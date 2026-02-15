`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Debug Unit for a pipelined RISC-V CPU
// - TOP FSM: IDLE / LOAD / STEP_PULSE / PREPARE_DATA / SEND / RUN
// - Sub-FSM LOAD: receives binary UART bytes, builds 32-bit words, writes IMEM
//   Protocol: 'L' (0x4C) + n_words[15:0] little-endian + n_words*4 bytes (LE)
// - Sub-FSM SNAPSHOT: captures pipeline wires + 32 regs via one combinational port
// - Sub-FSM TX: streams snapshot over UART TX (byte-based) using tx_start/tx_done
// -----------------------------------------------------------------------------
module debug_unit #(
    parameter       NBITS           =   32  ,
    parameter       RBITS           =   5   ,
    parameter       IMEM_SIZE_WORDS =   1024,
    parameter       IMEM_ADDR_BITS  =   10  ,
    parameter       DMEM_SNAP_WORDS =   64
)
(
    input   wire                    i_clk       ,
    input   wire                    i_rst       ,

    // UART byte interface
    input   wire                    rx_done     ,
    input   wire    [7:0]           rx_byte     ,
    output  reg                     tx_start    ,
    output  reg     [7:0]           tx_byte     ,
    input   wire                    tx_done     ,

    // CPU control
    output  reg                     debug_mode  ,   // 1 = freeze CPU
    output  reg                     step_pulse  ,   // 1-cycle pulse in debug mode

    // CPU status
    input   wire                    o_haltflag  ,

    // Observability wires from CPU
    input   wire    [NBITS-1:0]     o_IF_next_pc,
    input   wire    [NBITS-1:0]     o_IF_pc     ,

    input   wire    [NBITS-1:0]     o_ID_inst   ,
    input   wire    [NBITS-1:0]     o_ID_next_pc,
    input   wire    [NBITS-1:0]     o_ID_pc     ,
    input   wire    [NBITS-1:0]     o_ID_imm    ,
    input   wire    [NBITS-1:0]     o_ID_Rs1    ,
    input   wire    [NBITS-1:0]     o_ID_Rs2    ,
    input   wire    [RBITS-1:0]     o_ID_rd     ,

    input   wire    [NBITS-1:0]     o_EX_result ,
    input   wire    [NBITS-1:0]     o_EX_Rs2    ,
    input   wire    [RBITS-1:0]     o_EX_rd     ,

    input   wire    [NBITS-1:0]     o_MEM_result,
    input   wire    [NBITS-1:0]     o_MEM_data  ,
    input   wire    [RBITS-1:0]     o_MEM_rd    ,

    input   wire    [NBITS-1:0]     o_WB_data   ,
    input   wire    [RBITS-1:0]     o_WB_rd     ,

    input   wire    [NBITS-1:0]     o_inst_data ,
    input   wire    [NBITS-1:0]     o_reg_data  ,
    input   wire    [NBITS-1:0]     o_mem_data  ,

    // Debug read access to regfile (combinational)
    output  reg     [RBITS-1:0]     dbg_reg_index,
    input   wire    [NBITS-1:0]     dbg_reg_data ,

    // Debug read access to DMEM (word addressed)
    output  reg     [NBITS-1:0]     dbg_dmem_addr,
    input   wire    [NBITS-1:0]     dbg_dmem_data,
    output  reg                     dbg_dmem_re  ,

    // Debug write access to IMEM (word addressed)
    output  reg                     dbg_imem_we  ,
    output  reg     [NBITS-1:0]     dbg_imem_addr,
    output  reg     [NBITS-1:0]     dbg_imem_data
);

    // =========================================================================
    // 1) TOP FSM
    // =========================================================================
    localparam  [2:0]
        T_IDLE          =   3'd0    ,   //  Waiting for a command
        T_LOAD          =   3'd1    ,   //  Loading the program
        T_STEP_PULSE    =   3'd2    ,   //  Running for a cycle
        T_PREPARE_DATA  =   3'd3    ,   //  Prepare the data snapshot to send
        T_SEND          =   3'd4    ,   //  Sending the snapshot
        T_RUN           =   3'd5    ;   //  Running up to the halt flag

    reg     [2:0]   top_state   ,   top_next    ;

    // Commands (single-byte)
    localparam [7:0] 
        CMD_LOAD    =   8'h4C   ,   //  'L'
        CMD_STEP    =   8'h53   ,   //  'S'
        CMD_RUN     =   8'h52   ,   //  'R'
        CMD_DUMP    =   8'h44   ;   //  'D'

    // Latch last received command in IDLE
    reg     cmd_load    ,   cmd_step    ,
            cmd_run     ,   cmd_dump    ;

    // Sub-FSM enables
    wire    load_enable =   (top_state  ==  T_LOAD)         ;
    wire    snap_enable =   (top_state  ==  T_PREPARE_DATA) ;
    wire    tx_enable   =   (top_state  ==  T_SEND)         ;

    // Done flags from sub-FSMs
    wire    load_done   ,   load_error      ,
            snap_done   ,   tx_stream_done  ;

    // TOP sequential
    always @(posedge i_clk or posedge i_rst)
    begin
        if  (i_rst) top_state   <=  T_IDLE  ;
        else        top_state   <=  top_next;
    end

    // Command decode in IDLE
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst)
            begin
                cmd_load    <=  1'b0    ;
                cmd_step    <=  1'b0    ;
                cmd_run     <=  1'b0    ;
                cmd_dump    <=  1'b0    ;
            end
        else
            begin
                cmd_load    <=  1'b0    ;
                cmd_step    <=  1'b0    ;
                cmd_run     <=  1'b0    ;
                cmd_dump    <=  1'b0    ;

                if (top_state == T_IDLE && rx_done)
                begin
                    if      (rx_byte    ==  CMD_LOAD)   cmd_load    <=  1'b1    ;
                    else if (rx_byte    ==  CMD_STEP)   cmd_step    <=  1'b1    ;
                    else if (rx_byte    ==  CMD_RUN )   cmd_run     <=  1'b1    ;
                    else if (rx_byte    ==  CMD_DUMP)   cmd_dump    <=  1'b1    ;
                end
            end
    end

    // TOP next-state logic
    always @* begin
        top_next    =   top_state   ;

        case (top_state)
            T_IDLE:
            begin
                if      (cmd_load)  top_next    =   T_LOAD          ;
                else if (cmd_step)  top_next    =   T_STEP_PULSE    ;
                else if (cmd_dump)  top_next    =   T_PREPARE_DATA  ;
                else if (cmd_run )  top_next    =   T_RUN           ;
            end

            T_LOAD:
            begin
                if  (load_done  ||  load_error)
                    top_next    =   T_IDLE  ;
            end

            T_STEP_PULSE:
            begin
                top_next    =   T_PREPARE_DATA  ;
            end

            T_PREPARE_DATA:
            begin
                if  (snap_done)
                    top_next    =   T_SEND  ;
            end

            T_SEND:
            begin
                if  (tx_stream_done)
                    top_next    =   T_IDLE  ;
            end

            T_RUN: begin
                if (o_haltflag)
                    top_next    =   T_PREPARE_DATA  ;
            end

            default:
                top_next    =   T_IDLE  ;
        endcase
    end

    // TOP outputs: debug_mode and step_pulse
    always @*
    begin
        debug_mode  =   1'b1    ;
        step_pulse  =   1'b0    ;

        case (top_state)
            T_IDLE:        debug_mode = 1'b1;
            T_LOAD:        debug_mode = 1'b1;
            T_STEP_PULSE: begin
                debug_mode = 1'b1;
                step_pulse = 1'b1;
            end
            T_PREPARE_DATA:debug_mode = 1'b1;
            T_SEND:        debug_mode = 1'b1;
            T_RUN:         debug_mode = 1'b0;
            default:       debug_mode = 1'b1;
        endcase
    end

    // =========================================================================
    // 2) SUB-FSM: LOAD
    // =========================================================================
    localparam  [3:0]
        L_LEN0  =   4'd0    ,
        L_LEN1  =   4'd1    ,
        L_B0    =   4'd2    ,
        L_B1    =   4'd3    ,
        L_B2    =   4'd4    ,
        L_B3    =   4'd5    ,
        L_WRITE =   4'd6    ,
        L_DONE  =   4'd7    ,
        L_ERR   =   4'd8    ;   

    reg [3:0]   l_state     ,   l_next  ;

    reg [15:0]  l_n_words   ,   l_word_i;
    reg [31:0]  l_wbuf      ;

    // outputs from load FSM
    reg         l_done_r    ,   l_err_r ;
    assign      load_done   =   l_done_r;
    assign      load_error  =   l_err_r ;

    // LOAD FSM sequential
    always @(posedge i_clk or posedge i_rst)
    begin
        if (i_rst)
        begin
            l_state     <=  L_LEN0  ;
            l_n_words   <=  16'd0   ;
            l_word_i    <=  16'd0   ;
            l_wbuf      <=  32'd0   ;
        end
        else if (!load_enable)
        begin
            l_state     <=  L_LEN0  ;
            l_n_words   <=  16'd0   ;
            l_word_i    <=  16'd0   ;
            l_wbuf      <=  32'd0   ;
        end
        else
        begin
            l_state     <=  l_next          ;
            l_n_words   <=  l_n_words_next  ;
            l_word_i    <=  l_word_i_next   ;
            l_wbuf      <=  l_wbuf_next     ;
        end
    end

    reg [15:0]  l_n_words_next  ;
    reg [15:0]  l_word_i_next   ;
    reg [31:0]  l_wbuf_next     ;

    always @*
    begin
        l_next          =   l_state     ;
        l_n_words_next  =   l_n_words   ;
        l_word_i_next   =   l_word_i    ;
        l_wbuf_next     =   l_wbuf      ;

        l_done_r        =   1'b0        ;
        l_err_r         =   1'b0        ;

        dbg_imem_we     =   1'b0        ;
        dbg_imem_addr   =   {NBITS{1'b0}};
        dbg_imem_data   =   32'b0       ;

        case (l_state)
            L_LEN0:
            begin
                if (rx_done)
                begin
                    l_n_words_next[7:0] =   rx_byte;
                    l_next = L_LEN1;
                end
            end

            L_LEN1:
            begin
                if (rx_done)
                begin
                    l_n_words_next[15:8]    =   rx_byte;
                    l_word_i_next           = 16'd0;
                    l_wbuf_next             = 32'd0;

                    if ({rx_byte, l_n_words[7:0]} == 16'd0)     // The n word command was 00
                    begin
                        l_next  =   L_DONE  ;
                    end
                    else
                    begin
                        l_next  =   L_B0    ;
                    end
                end
            end

            L_B0:
            begin
                if (rx_done)
                begin
                    l_wbuf_next[7:0]    =   rx_byte ;
                    l_next              =   L_B1    ;
                end
            end

            L_B1:
            begin
                if (rx_done)
                begin
                    l_wbuf_next[15:8]   =   rx_byte ;
                    l_next              =   L_B2    ;
                end
            end

            L_B2:
            begin
                if (rx_done)
                begin
                    l_wbuf_next[23:16]  =   rx_byte ;
                    l_next              =   L_B3    ;
                end
            end

            L_B3:
            begin
                if (rx_done)
                begin
                    l_wbuf_next[31:24]  =   rx_byte ;
                    l_next              =   L_WRITE ;
                end
            end

            L_WRITE:
            begin
                if (l_word_i >= IMEM_SIZE_WORDS) begin
                    l_next          =   L_ERR   ;
                end
                else
                begin
                    dbg_imem_we     =   1'b1    ;
                    dbg_imem_addr   =   {{(NBITS-IMEM_ADDR_BITS){1'b0}}, l_word_i[IMEM_ADDR_BITS-1:0]}  ;
                    dbg_imem_data   =   l_wbuf  ;

                    if (l_word_i == (l_n_words - 1))
                    begin
                        l_next          =   L_DONE  ;
                    end
                    else
                    begin
                        l_word_i_next   =   l_word_i    +   1   ;
                        l_next          =   L_B0    ;
                    end
                end
            end

            L_DONE:
            begin
                l_done_r    =   1'b1    ;
            end

            L_ERR:
            begin
                l_err_r     =   1'b1    ;
            end

            default:
                l_next      =   L_LEN0  ;
        endcase
    end

    // =========================================================================
    // 3) SUB-FSM: SNAPSHOT
    // =========================================================================
    localparam  [2:0]
        S_CAP_LATCHES   =   3'd0    ,
        S_READ_REGS     =   3'd1    ,
        S_READ_DMEM     =   3'd2    ,
        S_DONE          =   3'd3    ;

    reg [2:0]   s_state ,   s_next  ;

    // Snapshot storage (pipeline wires)
    reg [NBITS-1:0] snap_IF_inst    ,   snap_IF_next_pc ,   snap_IF_pc  ;
    reg [NBITS-1:0] snap_ID_inst    ,   snap_ID_next_pc ,   snap_ID_pc  ,
                    snap_ID_imm     ,   snap_ID_Rs1     ,   snap_ID_Rs2 ;
    reg [RBITS-1:0] snap_ID_rd      ;
    reg [NBITS-1:0] snap_EX_result  ,   snap_EX_Rs2     ;
    reg [RBITS-1:0] snap_EX_rd      ;
    reg [NBITS-1:0] snap_MEM_result ,   snap_MEM_data   ;
    reg [RBITS-1:0] snap_MEM_rd     ;
    reg [NBITS-1:0] snap_WB_data    ;
    reg [RBITS-1:0] snap_WB_rd      ;

    // Register file snapshot
    reg [NBITS-1:0] snap_regs [0:31];
    reg [5:0]       s_reg_i         ;

    // DMEM snapshot
    reg [NBITS-1:0] snap_dmem [0: (DMEM_SNAP_WORDS>0 ? DMEM_SNAP_WORDS-1 : 0)];
    reg [NBITS-1:0] s_mem_i;

    reg     snap_done_r ;
    assign  snap_done   =   snap_done_r ;

    // Snapshot sequential
    always @(posedge i_clk or posedge i_rst)
    begin
        if (i_rst)
        begin
            s_state <=  S_CAP_LATCHES   ;
            s_reg_i <=  0               ;
            s_mem_i <=  0               ;
        end
        else if (!snap_enable)
        begin
            s_state <=  S_CAP_LATCHES   ;
            s_reg_i <=  0               ;
            s_mem_i <=  0               ;
        end
        else
        begin
            s_state <=  s_next  ;

            if (s_state == S_CAP_LATCHES)
            begin
                snap_IF_inst    <=  o_inst_data ;
                snap_IF_next_pc <=  o_IF_next_pc;
                snap_IF_pc      <=  o_IF_pc     ;

                snap_ID_inst    <=  o_ID_inst   ;
                snap_ID_next_pc <=  o_ID_next_pc;
                snap_ID_pc      <=  o_ID_pc     ;
                snap_ID_imm     <=  o_ID_imm    ;
                snap_ID_Rs1     <=  o_ID_Rs1    ;
                snap_ID_Rs2     <=  o_ID_Rs2    ;
                snap_ID_rd      <=  o_ID_rd     ;

                snap_EX_result  <=  o_EX_result ;
                snap_EX_Rs2     <=  o_EX_Rs2    ;
                snap_EX_rd      <=  o_EX_rd     ;

                snap_MEM_result <=  o_MEM_result;
                snap_MEM_data   <=  o_MEM_data  ;
                snap_MEM_rd     <=  o_MEM_rd    ;

                snap_WB_data    <=  o_WB_data   ;
                snap_WB_rd      <=  o_WB_rd     ;
            end

            if (s_state == S_READ_REGS)
            begin
                snap_regs[s_reg_i[4:0]] <=  dbg_reg_data    ;
                s_reg_i                 <=  s_reg_i +   1   ;
            end

            if (s_state == S_READ_DMEM)
            begin
                if (DMEM_SNAP_WORDS > 0)
                begin
                    snap_dmem[s_mem_i]  <=  dbg_dmem_data   ;
                    s_mem_i             <=  s_mem_i +   1   ;
                end
            end
        end
    end

    // Snapshot combinational next-state + drive debug read addresses
    always @*
    begin
        s_next          =   s_state ;
        snap_done_r     =   1'b0    ;

        dbg_reg_index   =   {RBITS{1'b0}}   ;
        dbg_dmem_addr   =   {NBITS{1'b0}}   ;
        dbg_dmem_re     =   1'b0            ;

        case (s_state)
            S_CAP_LATCHES:
            begin
                dbg_reg_index   =   {RBITS{1'b0}}   ;
                s_next          =   S_READ_REGS     ;
            end

            S_READ_REGS:
            begin
                dbg_reg_index   =   s_reg_i[RBITS-1:0]  ;
                if (s_reg_i == 6'd31)
                begin
                    if (DMEM_SNAP_WORDS > 0)
                        s_next  =   S_READ_DMEM ;
                    else                     
                        s_next  =   S_DONE      ;
                end
                else
                begin
                    s_next  =   S_READ_REGS ;
                end
            end

            S_READ_DMEM:
            begin
                dbg_dmem_addr   =   s_mem_i ;
                dbg_dmem_re     =   1'b1    ;
                if (s_mem_i == (DMEM_SNAP_WORDS-1))
                begin
                    s_next  =   S_DONE      ;
                end
                else
                begin
                    s_next  =   S_READ_DMEM ;
                end
            end

            S_DONE:
            begin
                snap_done_r =   1'b1        ;
            end

            default:
                s_next      =   S_CAP_LATCHES   ;
        endcase
    end

    // =========================================================================
    // 4) SUB-FSM: TX STREAM (byte-by-byte)
    // =========================================================================
    localparam  [1:0]
        X_IDLE      =   2'd0    ,
        X_PULSE     =   2'd1    ,
        X_WAIT_DONE =   2'd2    ,
        X_DONE      =   2'd3    ;

    reg [1:0]   x_state ,   x_next  ;
    reg [15:0]  tx_ptr  ;
    reg         tx_done_r           ;

    assign  tx_stream_done  =   tx_done_r   ;

    localparam integer PIPE_WORDS =
        3  + // IF: inst,next_pc,pc
        7  + // ID: inst,next_pc,pc,imm,rs1,rs2,rd
        3  + // EX: result,rs2,rd
        3  + // MEM: result,data,rd
        2;   // WB: data,rd

    localparam integer REG_WORDS        =   32  ;
    localparam integer TX_TOTAL_BYTES  =   2 + (PIPE_WORDS + REG_WORDS + DMEM_SNAP_WORDS) * 4  ;

    // TX sequential
    always @(posedge i_clk or posedge i_rst)
    begin
        if (i_rst)
        begin
            x_state <=  X_IDLE  ;
            tx_ptr  <=  0       ;
        end
        else if (!tx_enable)
        begin
            x_state <=  X_IDLE  ;
            tx_ptr  <=  0       ;
        end
        else
        begin
            x_state <=  x_next  ;
            if (x_state == X_WAIT_DONE && tx_done)
            begin
                tx_ptr  <=  tx_ptr  +   1   ;
            end
        end
    end

    function automatic [7:0] get_stream_byte(input [15:0] ptr);
        integer         word_index  ;
        integer         byte_in_word;
        reg     [31:0]  w           ;
        integer         i           ;
        begin
            if (ptr == 0)
            begin
                get_stream_byte =   8'hA5   ;
            end
            else if (ptr == 1)
            begin
                get_stream_byte =   8'h5A   ;
            end
            else
            begin
                i           =   ptr -   2   ;
                word_index  =   i[15:2]     ;
                byte_in_word=   i[1:0]      ;
                w           =   32'h0       ;

                if (word_index < PIPE_WORDS)
                begin
                    case (word_index)
                        0:  w   =   snap_IF_inst    ;
                        1:  w   =   snap_IF_next_pc ;
                        2:  w   =   snap_IF_pc      ;
                        3:  w   =   snap_ID_inst    ;
                        4:  w   =   snap_ID_next_pc ;
                        5:  w   =   snap_ID_pc      ;
                        6:  w   =   snap_ID_imm     ;
                        7:  w   =   snap_ID_Rs1     ;
                        8:  w   =   snap_ID_Rs2     ;
                        9:  w   =   { {(32-RBITS){1'b0}}, snap_ID_rd }  ;
                        10: w   =   snap_EX_result  ;
                        11: w   =   snap_EX_Rs2     ;
                        12: w   =   { {(32-RBITS){1'b0}}, snap_EX_rd }  ;
                        13: w   =   snap_MEM_result ;
                        14: w   =   snap_MEM_data   ;
                        15: w   =   { {(32-RBITS){1'b0}}, snap_MEM_rd } ;
                        16: w   =   snap_WB_data    ;
                        17: w   =   { {(32-RBITS){1'b0}}, snap_WB_rd }  ;
                        default:
                            w   =   32'h0   ;
                    endcase
                end
                else if (word_index < (PIPE_WORDS + REG_WORDS))
                begin
                    w   =   snap_regs[word_index - PIPE_WORDS]  ;
                end
                else
                begin
                    if (DMEM_SNAP_WORDS > 0)
                    begin
                        w   =   snap_dmem[word_index - (PIPE_WORDS + REG_WORDS)]    ;
                    end
                    else
                    begin
                        w   =   32'h0   ;
                    end
                end

                case (byte_in_word)
                    0:  get_stream_byte =   w[7:0]      ;
                    1:  get_stream_byte =   w[15:8]     ;
                    2:  get_stream_byte =   w[23:16]    ;
                    default:
                        get_stream_byte =   w[31:24]    ;
                endcase
            end
        end
    endfunction

    // TX combinational
    always @* begin
        x_next      =   x_state ;
        tx_done_r   =   1'b0    ;
        tx_start    =   1'b0    ;
        tx_byte     =   8'h00   ;

        case (x_state)
            X_IDLE:
            begin
                tx_byte =   get_stream_byte(tx_ptr) ;
                x_next  =   X_PULSE                 ;
            end

            X_PULSE:
            begin
                tx_byte =   get_stream_byte(tx_ptr) ;
                tx_start=   1'b1                    ;
                x_next  =   X_WAIT_DONE             ;
            end

            X_WAIT_DONE:
            begin
                tx_byte =   get_stream_byte(tx_ptr) ;
                if (tx_done)
                begin
                    if (tx_ptr == (TX_TOTAL_BYTES - 1))
                    begin
                        x_next  =   X_DONE  ;
                    end
                    else
                    begin
                        x_next  =   X_IDLE  ;
                    end
                end
            end

            X_DONE:
            begin
                tx_done_r   =   1'b1    ;
            end

            default:
                x_next      =   X_IDLE  ;
        endcase
    end

endmodule
