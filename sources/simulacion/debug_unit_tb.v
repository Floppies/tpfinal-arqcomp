`timescale 10ns / 10ps

module debug_unit_tb();

    localparam  NBITS           =   32  ;
    localparam  RBITS           =   5   ;
    localparam  IMEM_SIZE_WORDS =   16  ;
    localparam  IMEM_ADDR_BITS  =   4   ;
    localparam  DMEM_SNAP_WORDS =   0   ;

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
    reg                     o_haltflag;
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
    reg     [NBITS-1:0]     o_inst_data;
    reg     [NBITS-1:0]     o_reg_data;
    reg     [NBITS-1:0]     o_mem_data;

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

    // Command bytes
    localparam [7:0] CMD_LOAD = 8'h4C; // 'L'
    localparam [7:0] CMD_STEP = 8'h53; // 'S'
    localparam [7:0] CMD_RUN  = 8'h52; // 'R'
    localparam [7:0] CMD_DUMP = 8'h44; // 'D'

    // Simple UART byte sender
    task send_byte(input [7:0] b);
    begin
        rx_byte = b;
        rx_done = 1'b1;
        #10;
        rx_done = 1'b0;
        #10;
    end
    endtask

    initial begin
        $dumpfile("debug_unit_tb.vcd"); $dumpvars;
        i_clk           =   1'b0;
        i_rst           =   1'b1;
        rx_done         =   1'b0;
        rx_byte         =   8'h00;
        tx_done         =   1'b0;

        o_haltflag      =   1'b0;
        o_pipe_empty    =   1'b0;
        o_IF_next_pc    =   32'h4;
        o_IF_pc         =   32'h0;
        o_ID_inst       =   32'h00000013;
        o_ID_next_pc    =   32'h4;
        o_ID_pc         =   32'h0;
        o_ID_imm        =   32'h0;
        o_ID_Rs1        =   32'h0;
        o_ID_Rs2        =   32'h0;
        o_ID_rd         =   5'd0;
        o_EX_result     =   32'h0;
        o_EX_Rs2        =   32'h0;
        o_EX_rd         =   5'd0;
        o_MEM_result    =   32'h0;
        o_MEM_data      =   32'h0;
        o_MEM_rd        =   5'd0;
        o_WB_data       =   32'h0;
        o_WB_rd         =   5'd0;
        o_inst_data     =   32'h0;
        o_reg_data      =   32'h0;
        o_mem_data      =   32'h0;
        dbg_reg_data    =   32'h0;
        dbg_dmem_data   =   32'h0;

        #20;
        i_rst = 1'b0;

        // LOAD: load 2 words into IMEM[0..1]
        send_byte(CMD_LOAD);
        send_byte(8'h02); // n_words[7:0]
        send_byte(8'h00); // n_words[15:8]
        // Word 0 = 0x12345678 (LE bytes)
        send_byte(8'h78);
        send_byte(8'h56);
        send_byte(8'h34);
        send_byte(8'h12);
        // Word 1 = 0xAABBCCDD (LE bytes)
        send_byte(8'hDD);
        send_byte(8'hCC);
        send_byte(8'hBB);
        send_byte(8'hAA);

        // STEP: should pulse step_pulse and then enter snapshot/send
        send_byte(CMD_STEP);
        #600

        // RUN: release debug_mode, then assert halt to stop
        send_byte(CMD_RUN);
        #50;
        o_haltflag   = 1'b1;
        o_pipe_empty = 1'b1;
        #600

        // DUMP
        send_byte(CMD_DUMP);

        #600;
        $finish;
    end

    always begin
        #5 i_clk = ~i_clk;
    end

    // Generate tx_done one cycle after tx_start
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
        .o_haltflag     (o_haltflag),
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
        .o_inst_data    (o_inst_data),
        .o_reg_data     (o_reg_data),
        .o_mem_data     (o_mem_data),
        .dbg_reg_index  (dbg_reg_index),
        .dbg_reg_data   (dbg_reg_data),
        .dbg_dmem_addr  (dbg_dmem_addr),
        .dbg_dmem_data  (dbg_dmem_data),
        .dbg_dmem_re    (dbg_dmem_re),
        .dbg_imem_we    (dbg_imem_we),
        .dbg_imem_addr  (dbg_imem_addr),
        .dbg_imem_data  (dbg_imem_data)
    );

endmodule
