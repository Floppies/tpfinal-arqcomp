`timescale 1ns / 1ps

module debug_unit_tb();

    localparam  NBITS           =   32  ;
    localparam  RBITS           =   5   ;
    localparam  IMEM_SIZE_WORDS =   16  ;
    localparam  IMEM_ADDR_BITS  =   4   ;
    localparam  DMEM_SNAP_WORDS =   0   ;

    localparam integer PIPE_WORDS   = 17;
    localparam integer REG_WORDS    = 32;
    localparam integer SNAP_BYTES   = 2 + (PIPE_WORDS + REG_WORDS + DMEM_SNAP_WORDS) * 4;

    // Top-state aliases
    localparam [2:0] T_IDLE          = 3'd0;
    localparam [2:0] T_LOAD          = 3'd1;
    localparam [2:0] T_PREPARE_DATA  = 3'd3;
    localparam [2:0] T_SEND          = 3'd4;
    localparam [2:0] T_RUN           = 3'd5;
    localparam [2:0] T_STATUS_TX     = 3'd6;

    // Commands
    localparam [7:0] CMD_LOAD = 8'h4C; // 'L'
    localparam [7:0] CMD_RUN  = 8'h52; // 'R'

    // Status bytes
    localparam [7:0] ACK_CMD_LOAD    = 8'h01;
    localparam [7:0] ACK_RUN_START   = 8'h12;
    localparam [7:0] ACK_LOAD_DONE   = 8'h10;
    localparam [7:0] ACK_RUN_DONE    = 8'h13;
    localparam [7:0] ACK_SNAP_START  = 8'h14;
    localparam [7:0] ACK_SNAP_DONE   = 8'h15;
    localparam [7:0] ERR_CMD_UNKNOWN = 8'h80;

    // Clock/reset
    reg                     i_clk   ;
    reg                     i_rst   ;

    // UART
    reg                     rx_done ;
    reg     [7:0]           rx_byte ;
    wire                    tx_start;
    wire    [7:0]           tx_byte ;
    reg                     tx_done ;

    // CPU status/observability (dummy)
    reg                     o_pipe_empty;
    reg     [NBITS-1:0]     o_IF_next_pc;
    reg     [NBITS-1:0]     o_IF_pc;
    reg     [NBITS-1:0]     o_ID_inst;
    reg     [NBITS-1:0]     o_ID_next_pc;
    reg     [NBITS-1:0]     o_ID_pc;
    reg     [NBITS-1:0]     o_ID_imm;
    reg     [NBITS-1:0]     o_ID_Rs1;
    reg     [NBITS-1:0]     o_ID_Rs2;
    reg     [RBITS-1:0]     o_ID_rd;
    reg     [NBITS-1:0]     o_EX_result;
    reg     [NBITS-1:0]     o_EX_Rs2;
    reg     [RBITS-1:0]     o_EX_rd;
    reg     [NBITS-1:0]     o_MEM_result;
    reg     [NBITS-1:0]     o_MEM_data;
    reg     [RBITS-1:0]     o_MEM_rd;
    reg     [NBITS-1:0]     o_WB_data;
    reg     [RBITS-1:0]     o_WB_rd;

    // Debug access
    wire    [RBITS-1:0]     dbg_reg_index;
    reg     [NBITS-1:0]     dbg_reg_data;
    wire    [NBITS-1:0]     dbg_dmem_addr;
    reg     [NBITS-1:0]     dbg_dmem_data;
    wire                    dbg_dmem_re;
    wire                    dbg_imem_we;
    wire    [NBITS-1:0]     dbg_imem_addr;
    wire    [NBITS-1:0]     dbg_imem_data;

    // Outputs
    wire                    debug_mode;
    wire                    step_pulse;
    wire    [2:0]           o_top_state;
    wire    [3:0]           o_load_state;
    wire    [2:0]           o_snap_state;
    wire    [1:0]           o_tx_state;

    // Send one RX byte (one-cycle pulse)
    task send_byte(input [7:0] b);
    begin
        rx_byte <= b;
        rx_done <= 1'b1;
        @(posedge i_clk);
        rx_done <= 1'b0;
        @(posedge i_clk);
    end
    endtask

    task wait_next_tx;
        integer guard;
    begin
        guard = 0;

        // Avoid re-consuming a pulse if caller arrives while tx_start is still high.
        if (tx_start === 1'b1)
            @(negedge tx_start);

        while (tx_start !== 1'b1)
        begin
            @(posedge i_clk);
            guard = guard + 1;
            if (guard > 2000)
            begin
                $display("ERROR: timeout waiting TX byte");
                $fatal;
            end
        end
    end
    endtask

    task check_next_tx(input [7:0] exp);
    begin
        wait_next_tx();
        if (tx_byte !== exp) begin
            $display("ERROR: TX=0x%02h expected 0x%02h", tx_byte, exp);
            $fatal;
        end

        // Move past this tx_start pulse so next check consumes next byte.
        @(negedge tx_start);
    end
    endtask

    task skip_tx(input integer n);
        integer j;
    begin
        for (j = 0; j < n; j = j + 1)
        begin
            wait_next_tx();
            @(negedge tx_start);
        end
    end
    endtask

    task wait_top_state(input [2:0] st);
    begin
        while (o_top_state != st) @(posedge i_clk);
    end
    endtask

    initial begin
        $dumpfile("debug_unit_tb.vcd"); $dumpvars;

        i_clk           =   1'b0;
        i_rst           =   1'b1;
        rx_done         =   1'b0;
        rx_byte         =   8'h00;
        tx_done         =   1'b0;

        o_pipe_empty    =   1'b0;
        o_IF_next_pc    =   32'h00000004;
        o_IF_pc         =   32'h00000001;
        o_ID_inst       =   32'h00000013;
        o_ID_next_pc    =   32'h00000004;
        o_ID_pc         =   32'h00000001;
        o_ID_imm        =   32'h00000001;
        o_ID_Rs1        =   32'h00000001;
        o_ID_Rs2        =   32'h00000001;
        o_ID_rd         =   5'd2;
        o_EX_result     =   32'h00000001;
        o_EX_Rs2        =   32'h00000001;
        o_EX_rd         =   5'd2;
        o_MEM_result    =   32'h00000001;
        o_MEM_data      =   32'h00000001;
        o_MEM_rd        =   5'd2;
        o_WB_data       =   32'h00000001;
        o_WB_rd         =   5'd2;
        dbg_reg_data    =   32'h00000001;
        dbg_dmem_data   =   32'h00000001;

        repeat (4) @(posedge i_clk);
        i_rst = 1'b0;
        wait_top_state(T_IDLE);
        @(posedge i_clk);

        // 1) Invalid command -> ERR_CMD_UNKNOWN
        send_byte(8'h99);
        wait_top_state(T_STATUS_TX);
        check_next_tx(ERR_CMD_UNKNOWN);
        wait_top_state(T_IDLE);
        @(posedge i_clk);

        // 2) LOAD command -> ACK_CMD_LOAD
        send_byte(CMD_LOAD);
        wait_top_state(T_STATUS_TX);
        check_next_tx(ACK_CMD_LOAD);
        wait_top_state(T_LOAD);
        @(posedge i_clk);

        // LOAD payload -> ACK_LOAD_DONE
        send_byte(8'h02); // n_words LSB
        send_byte(8'h00); // n_words MSB
        // Word0 = 0x12345678
        send_byte(8'h78); send_byte(8'h56); send_byte(8'h34); send_byte(8'h12);
        // Word1 = 0xAABBCCDD
        send_byte(8'hDD); send_byte(8'hCC); send_byte(8'hBB); send_byte(8'hAA);

        wait_top_state(T_STATUS_TX);
        check_next_tx(ACK_LOAD_DONE);
        wait_top_state(T_IDLE);
        @(posedge i_clk);

        // 3) RUN command -> ACK_RUN_START
        send_byte(CMD_RUN);
        wait_top_state(T_STATUS_TX);
        check_next_tx(ACK_RUN_START);
        wait_top_state(T_RUN);

        // Let RUN execute a few cycles and finish
        repeat (12) @(posedge i_clk);
        o_pipe_empty = 1'b1;
        @(posedge i_clk);
        o_pipe_empty = 1'b0;

        // 4) RUN done + snapshot
        wait_top_state(T_STATUS_TX);
        check_next_tx(ACK_RUN_DONE);
        wait_top_state(T_PREPARE_DATA);
        wait_top_state(T_STATUS_TX);
        check_next_tx(ACK_SNAP_START);
        wait_top_state(T_SEND);
        check_next_tx(8'hA5);
        check_next_tx(8'h5A);
        skip_tx(SNAP_BYTES - 2);
        wait_top_state(T_STATUS_TX);
        check_next_tx(ACK_SNAP_DONE);

        $display("PASS: debug_unit ACK/ERR + snapshot framing verified");
        repeat (20) @(posedge i_clk);
        $finish;
    end

    always #5 i_clk = ~i_clk;

    // TX handshake model: done one cycle after start
    always @(posedge i_clk) begin
        tx_done <= tx_start;
    end

    debug_unit #(
        .NBITS              (NBITS),
        .RBITS              (RBITS),
        .IMEM_SIZE_WORDS    (IMEM_SIZE_WORDS),
        .IMEM_ADDR_BITS     (IMEM_ADDR_BITS),
        .DMEM_SNAP_WORDS    (DMEM_SNAP_WORDS)
    ) dut (
        .i_clk          (i_clk),
        .i_rst          (i_rst),
        .rx_done        (rx_done),
        .rx_byte        (rx_byte),
        .tx_start       (tx_start),
        .tx_byte        (tx_byte),
        .tx_done        (tx_done),
        .debug_mode     (debug_mode),
        .step_pulse     (step_pulse),
        .o_pipe_empty   (o_pipe_empty),
        .o_IF_next_pc   (o_IF_next_pc),
        .o_IF_pc        (o_IF_pc),
        .o_ID_inst      (o_ID_inst),
        .o_ID_next_pc   (o_ID_next_pc),
        .o_ID_pc        (o_ID_pc),
        .o_ID_imm       (o_ID_imm),
        .o_ID_Rs1       (o_ID_Rs1),
        .o_ID_Rs2       (o_ID_Rs2),
        .o_ID_rd        (o_ID_rd),
        .o_EX_result    (o_EX_result),
        .o_EX_Rs2       (o_EX_Rs2),
        .o_EX_rd        (o_EX_rd),
        .o_MEM_result   (o_MEM_result),
        .o_MEM_data     (o_MEM_data),
        .o_MEM_rd       (o_MEM_rd),
        .o_WB_data      (o_WB_data),
        .o_WB_rd        (o_WB_rd),
        .dbg_reg_index  (dbg_reg_index),
        .dbg_reg_data   (dbg_reg_data),
        .dbg_dmem_addr  (dbg_dmem_addr),
        .dbg_dmem_data  (dbg_dmem_data),
        .dbg_dmem_re    (dbg_dmem_re),
        .dbg_imem_we    (dbg_imem_we),
        .dbg_imem_addr  (dbg_imem_addr),
        .dbg_imem_data  (dbg_imem_data),
        .o_top_state    (o_top_state),
        .o_load_state   (o_load_state),
        .o_snap_state   (o_snap_state),
        .o_tx_state     (o_tx_state)
    );

endmodule
