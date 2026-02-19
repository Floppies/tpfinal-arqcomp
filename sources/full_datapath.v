`timescale 1ns / 1ps

module full_datapath #(
    parameter   MEM_SIZE        =   1024    ,
    parameter   BANK_SIZE       =   32      ,
    parameter   NBITS           =   32      ,
    parameter   RBITS           =   5       ,
    parameter   BAUD_DIV        =   163     ,
    parameter   BAUD_SIZ        =   8       ,
    parameter   SB_TICK         =   16      ,
    parameter   DBIT            =   8       ,
    parameter   IMEM_ADDR_BITS  =   10      ,
    parameter   DMEM_SNAP_WORDS =   4       ,
    parameter   USE_CLK_WIZ     =   1
)
(
    input   wire                i_clk_100mhz ,
    input   wire                i_rst       ,
    input   wire                i_rx        ,
    output  wire                o_tx        ,

    // State outputs for LEDs
    output  wire    [2:0]       o_top_state ,
    output  wire    [3:0]       o_load_state,
    output  wire    [2:0]       o_snap_state,
    output  wire    [1:0]       o_tx_state
);

    // UART <-> Debug Unit
    wire                    rx_done     ;
    wire    [DBIT-1:0]      rx_byte     ;
    wire                    tx_start    ;
    wire    [DBIT-1:0]      tx_byte     ;
    wire                    tx_done     ;

    // Debug control signals to datapath
    wire                    debug_mode      ;
    wire                    step_pulse      ;
    wire                    dbg_imem_we     ;
    wire    [NBITS-1:0]     dbg_imem_addr   ;
    wire    [NBITS-1:0]     dbg_imem_data   ;
    wire    [RBITS-1:0]     dbg_reg_index   ;
    wire    [NBITS-1:0]     dbg_dmem_addr   ;
    wire                    dbg_dmem_re     ;
    wire    [NBITS-1:0]     dbg_reg_data    ;
    wire    [NBITS-1:0]     dbg_dmem_data   ;

    // Datapath observability
    wire    [NBITS-1:0]     o_IF_next_pc    ;
    wire    [NBITS-1:0]     o_IF_pc         ;
    wire    [NBITS-1:0]     o_ID_inst       ;
    wire    [NBITS-1:0]     o_ID_next_pc    ;
    wire    [NBITS-1:0]     o_ID_pc         ;
    wire    [NBITS-1:0]     o_ID_imm        ;
    wire    [NBITS-1:0]     o_ID_Rs1        ;
    wire    [NBITS-1:0]     o_ID_Rs2        ;
    wire    [RBITS-1:0]     o_ID_rd         ;
    wire    [NBITS-1:0]     o_EX_result     ;
    wire    [NBITS-1:0]     o_EX_Rs2        ;
    wire    [RBITS-1:0]     o_EX_rd         ;
    wire    [NBITS-1:0]     o_MEM_result    ;
    wire    [NBITS-1:0]     o_MEM_data      ;
    wire    [RBITS-1:0]     o_MEM_rd        ;
    wire    [NBITS-1:0]     o_WB_data       ;
    wire    [RBITS-1:0]     o_WB_rd         ;
    wire                    o_haltflag      ;
    wire                    o_pipe_empty    ;

    wire clk_50;
    wire clk_locked;
    wire rst_sync = i_rst | ~clk_locked;

    generate
        if (USE_CLK_WIZ) begin : G_CLK_WIZ
            clk_wiz_0 clk_gen (
                .clk_in1(i_clk_100mhz),
                .clk_out1(clk_50),
                .locked(clk_locked)
            );
        end else begin : G_CLK_BYPASS
            assign clk_50 = i_clk_100mhz;
            assign clk_locked = 1'b1;
        end
    endgenerate

    uart_unit #(
        .SB_TICK    (SB_TICK)   ,
        .BAUD_DIV   (BAUD_DIV)  ,
        .BAUD_SIZ   (BAUD_SIZ)  ,
        .DBIT       (DBIT)
    )UART
    (
        .clk        (clk_50)    ,
        .reset      (rst_sync)  ,
        .rx         (i_rx)      ,
        .tx_start   (tx_start)  ,
        .tx_Data    (tx_byte)   ,
        .tx         (o_tx)      ,
        .tx_done    (tx_done)   ,
        .rx_done    (rx_done)   ,
        .rx_Data    (rx_byte)
    );

    debug_unit #(
        .NBITS              (NBITS)         ,
        .RBITS              (RBITS)         ,
        .IMEM_SIZE_WORDS    (MEM_SIZE)      ,
        .IMEM_ADDR_BITS     (IMEM_ADDR_BITS),
        .DMEM_SNAP_WORDS    (DMEM_SNAP_WORDS)
    )DEBUG
    (
        .i_clk          (clk_50)        ,
        .i_rst          (rst_sync)      ,
        .rx_done        (rx_done)       ,
        .rx_byte        (rx_byte)       ,
        .tx_start       (tx_start)      ,
        .tx_byte        (tx_byte)       ,
        .tx_done        (tx_done)       ,
        .debug_mode     (debug_mode)    ,
        .step_pulse     (step_pulse)    ,
        .o_haltflag     (o_haltflag)    ,
        .o_pipe_empty   (o_pipe_empty)  ,
        .o_IF_next_pc   (o_IF_next_pc)  ,
        .o_IF_pc        (o_IF_pc)       ,
        .o_ID_inst      (o_ID_inst)     ,
        .o_ID_next_pc   (o_ID_next_pc)  ,
        .o_ID_pc        (o_ID_pc)       ,
        .o_ID_imm       (o_ID_imm)      ,
        .o_ID_Rs1       (o_ID_Rs1)      ,
        .o_ID_Rs2       (o_ID_Rs2)      ,
        .o_ID_rd        (o_ID_rd)       ,
        .o_EX_result    (o_EX_result)   ,
        .o_EX_Rs2       (o_EX_Rs2)      ,
        .o_EX_rd        (o_EX_rd)       ,
        .o_MEM_result   (o_MEM_result)  ,
        .o_MEM_data     (o_MEM_data)    ,
        .o_MEM_rd       (o_MEM_rd)      ,
        .o_WB_data      (o_WB_data)     ,
        .o_WB_rd        (o_WB_rd)       ,
        .dbg_reg_index  (dbg_reg_index) ,
        .dbg_reg_data   (dbg_reg_data)  ,
        .dbg_dmem_addr  (dbg_dmem_addr) ,
        .dbg_dmem_data  (dbg_dmem_data) ,
        .dbg_dmem_re    (dbg_dmem_re)   ,
        .dbg_imem_we    (dbg_imem_we)   ,
        .dbg_imem_addr  (dbg_imem_addr) ,
        .dbg_imem_data  (dbg_imem_data) ,
        .o_top_state    (o_top_state)   ,
        .o_load_state   (o_load_state)  ,
        .o_snap_state   (o_snap_state)  ,
        .o_tx_state     (o_tx_state)
    );

    datapath_pipe #(
        .MEM_SIZE   (MEM_SIZE)  ,
        .BANK_SIZE  (BANK_SIZE) ,
        .NBITS      (NBITS)     ,
        .RBITS      (RBITS)
    )DATAPATH
    (
        .i_clk          (clk_50)        ,
        .i_rst          (rst_sync)      ,
        .debug_mode     (debug_mode)    ,
        .step_pulse     (step_pulse)    ,
        .dbg_imem_we    (dbg_imem_we)   ,
        .dbg_imem_addr  (dbg_imem_addr) ,
        .dbg_imem_data  (dbg_imem_data) ,
        .dbg_reg_index  (dbg_reg_index) ,
        .dbg_dmem_addr  (dbg_dmem_addr) ,
        .dbg_dmem_re    (dbg_dmem_re)   ,
        .dbg_reg_data   (dbg_reg_data)  ,
        .dbg_dmem_data  (dbg_dmem_data) ,
        .o_IF_next_pc   (o_IF_next_pc)  ,
        .o_IF_pc        (o_IF_pc)       ,
        .o_ID_inst      (o_ID_inst)     ,
        .o_ID_next_pc   (o_ID_next_pc)  ,
        .o_ID_pc        (o_ID_pc)       ,
        .o_ID_imm       (o_ID_imm)      ,
        .o_ID_Rs1       (o_ID_Rs1)      ,
        .o_ID_Rs2       (o_ID_Rs2)      ,
        .o_ID_rd        (o_ID_rd)       ,
        .o_EX_result    (o_EX_result)   ,
        .o_EX_Rs2       (o_EX_Rs2)      ,
        .o_EX_rd        (o_EX_rd)       ,
        .o_MEM_result   (o_MEM_result)  ,
        .o_MEM_data     (o_MEM_data)    ,
        .o_MEM_rd       (o_MEM_rd)      ,
        .o_WB_data      (o_WB_data)     ,
        .o_WB_rd        (o_WB_rd)       ,
        .o_haltflag     (o_haltflag)    ,
        .o_pipe_empty   (o_pipe_empty)
    );

endmodule
