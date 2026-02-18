`timescale 1ns / 1ps

module datapath_pipe_tb();

    localparam MEM_SIZE = 8;
    localparam BANK_SIZE = 32;
    localparam NBITS = 32;
    localparam RBITS = 5;

    // Inputs
    reg                 i_clk;
    reg                 i_rst;
    reg                 debug_mode;
    reg                 step_pulse;
    reg                 dbg_imem_we;
    reg  [NBITS-1:0]    dbg_imem_addr;
    reg  [NBITS-1:0]    dbg_imem_data;
    reg  [RBITS-1:0]    dbg_reg_index;
    reg  [NBITS-1:0]    dbg_dmem_addr;
    reg                 dbg_dmem_re;

    // Key outputs only (timing-friendly observation set)
    wire [NBITS-1:0]    o_IF_pc;
    wire                o_haltflag;
    wire                o_pipe_empty;

    // Optional debug outputs
    wire [NBITS-1:0]    dbg_reg_data;
    wire [NBITS-1:0]    dbg_dmem_data;

    reg  [NBITS-1:0]    hold_pc;
    reg  [NBITS-1:0]    step_pc;

    initial begin
        // Keep dump tiny for gate-level timing simulation
        $dumpfile("datapath_pipe_tb.vcd");
        $dumpvars(0, datapath_pipe_tb.i_clk, datapath_pipe_tb.i_rst,
                     datapath_pipe_tb.debug_mode, datapath_pipe_tb.step_pulse,
                     datapath_pipe_tb.o_IF_pc, datapath_pipe_tb.o_haltflag,
                     datapath_pipe_tb.o_pipe_empty);

        i_clk       = 1'b0;
        i_rst       = 1'b1;
        debug_mode  = 1'b0;
        step_pulse  = 1'b0;
        dbg_imem_we = 1'b0;
        dbg_imem_addr = {NBITS{1'b0}};
        dbg_imem_data = {NBITS{1'b0}};
        dbg_reg_index = {RBITS{1'b0}};
        dbg_dmem_addr = {NBITS{1'b0}};
        dbg_dmem_re   = 1'b0;

        repeat (4) @(posedge i_clk);
        i_rst = 1'b0;

        // Normal run
        repeat (6) @(posedge i_clk);

        // Freeze in debug mode
        debug_mode = 1'b1;
        @(posedge i_clk);
        hold_pc = o_IF_pc;
        repeat (3) @(posedge i_clk);
        if (o_IF_pc !== hold_pc)
            $display("ERROR: PC changed while frozen in debug mode");

        // Single step pulse
        step_pulse = 1'b1;
        @(posedge i_clk);
        step_pulse = 1'b0;
        @(posedge i_clk);
        step_pc = o_IF_pc;
        if (step_pc === hold_pc)
            $display("ERROR: PC did not advance on step pulse");

        // Back to normal run
        debug_mode = 1'b0;
        repeat (8) @(posedge i_clk);

        $finish;
    end

    always #5 i_clk = ~i_clk;

    datapath_pipe #(
        .MEM_SIZE   (MEM_SIZE),
        .BANK_SIZE  (BANK_SIZE),
        .NBITS      (NBITS),
        .RBITS      (RBITS)
    ) dut (
        .i_clk          (i_clk),
        .i_rst          (i_rst),
        .debug_mode     (debug_mode),
        .step_pulse     (step_pulse),
        .dbg_imem_we    (dbg_imem_we),
        .dbg_imem_addr  (dbg_imem_addr),
        .dbg_imem_data  (dbg_imem_data),
        .dbg_reg_index  (dbg_reg_index),
        .dbg_dmem_addr  (dbg_dmem_addr),
        .dbg_dmem_re    (dbg_dmem_re),
        .dbg_reg_data   (dbg_reg_data),
        .dbg_dmem_data  (dbg_dmem_data),
        .o_IF_next_pc   (),
        .o_IF_pc        (o_IF_pc),
        .o_ID_inst      (),
        .o_ID_next_pc   (),
        .o_ID_pc        (),
        .o_ID_imm       (),
        .o_ID_Rs1       (),
        .o_ID_Rs2       (),
        .o_ID_rd        (),
        .o_EX_result    (),
        .o_EX_Rs2       (),
        .o_EX_rd        (),
        .o_MEM_result   (),
        .o_MEM_data     (),
        .o_MEM_rd       (),
        .o_WB_data      (),
        .o_WB_rd        (),
        .o_inst_data    (),
        .o_reg_data     (),
        .o_mem_data     (),
        .o_haltflag     (o_haltflag),
        .o_pipe_empty   (o_pipe_empty)
    );

endmodule
