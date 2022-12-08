`timescale 1ns / 1ps

module debug_unit   #(
    //  Parametros para las dimensiones de la Instruction Memory
    parameter   IM_ADDR_LENGTH      =       32      ,
    parameter   IM_MEM_SIZE         =       5       ,
    parameter   INST_WIDTH          =       32      ,
    //  Parametros para las dimensiones de la Data Memory
    parameter   DM_ADDR_LENGTH      =       32      ,
    parameter   DM_MEM_SIZE         =       1024    ,
    parameter   DATA_WIDTH          =       32      ,
    //  Parametros para las dimensiones del Register Bank
    parameter   RBITS               =       5       ,
    parameter   BANK_SIZE           =       32      ,
    parameter   REG_WIDTH           =       32      ,
    parameter   NBITS               =       32
)
(
    //  Entradas
    input   wire    clk         ,           rst         ,
                                            halt_flag   ,
    input   wire    [NBITS-1:0]             current_pc  ,
    input   wire    [DATA_WIDTH-1:0]        DM_Data     ,
    input   wire    [RBITS-1:0]             RB_Data     ,
    input   wire    [NBITS-1:0]             rx_Data     ,
    input   wire    tx_done     ,           rx_done     ,
    //  Salidas
    output  wire    [IM_ADDR_LENGTH-1:0]    IM_Addr     ,
    output  wire    [INST_WIDTH-1:0]        IM_Data     ,
    output  wire    [RBITS-1:0]             RB_Addr     ,
    output  wire    [DM_ADDR_LENGTH-1:0]    DM_Addr     ,
    output  wire                            IM_We       ,
    output  wire                            tx_start    ,
    output  wire    [NBITS-1:0]             tx_Data     ,
    output  wire    o_clock     ,           o_rst
);

    // Señales auxiliares
    /*reg                 reset   ,   clk_enable  ;
    reg     [NBITS-1:0]             clock_count ;
    
    assign  enable      =       clk_enable      ;
    assign  o_rst       =       reset           ;*/
    wire                            clk_enable  ;
    wire    [NBITS-1:0]             clk_count   ;
    
    debug_controller    #(
        .IM_ADDR_LENGTH     (IM_ADDR_LENGTH)    ,
        .IM_MEM_SIZE        (IM_MEM_SIZE)       ,
        .INST_WIDTH         (INST_WIDTH)        ,
        .DM_ADDR_LENGTH     (DM_ADDR_LENGTH)    ,
        .DM_MEM_SIZE        (DM_MEM_SIZE)       ,
        .DATA_WIDTH         (DATA_WIDTH)        ,
        .RBITS              (RBITS)             ,
        .BANK_SIZE          (BANK_SIZE)         ,
        .REG_WIDTH          (REG_WIDTH)         ,
        .NBITS              (NBITS)
    )DEBUGCTRL
    (
        .clk                (clk)           ,
        .rst                (rst)           ,
        .rx_Data            (rx_Data)       ,
        .RB_Data            (RB_Data)       ,
        .DM_Data            (DM_Data)       ,
        .rx_done            (rx_done)       ,
        .tx_done            (tx_done)       ,
        .halt_flag          (halt_flag)     ,
        .current_pc         (current_pc)    ,
        .clock_count        (clk_count)     ,
        .IM_Addr            (IM_Addr)       ,
        .IM_Data            (IM_Data)       ,
        .IM_We              (IM_We)         ,
        .RB_Addr            (RB_Addr)       ,
        .DM_Addr            (DM_Addr)       ,
        .tx_Data            (tx_Data)       ,
        .tx_start           (tx_start)      ,
        .clock_enable       (clk_enable)    ,
        .o_rst              (reset)
    );
    
    clock_control   #(
        .NBITS              (NBITS)
    )CLKCTRL
    (
        .clock              (clk)           ,
        .reset              (o_rst)         ,
        .enable             (clk_enable)    ,
        .clock_count        (clock_count)   ,
        .o_clock            (o_clock)
    );

endmodule
