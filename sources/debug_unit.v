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
    //  Parametros para UART
    parameter   SB_TICK             =       16      ,   //TENGO QUE CAMBIAR ??
    parameter   BAUD_DIV            =       163     ,
    parameter   BAUD_SIZ            =       8       ,
    parameter   NBITS               =       32
)
(
    //  Entradas
    input   wire    clk         ,           rst         ,
    input   wire                            rx          ,
    input   wire    current_PC  ,           halt_flag   ,
    input   wire    [DATA_WIDTH-1:0]        DM_Data     ,
    //  Salidas
    output  wire    [IM_ADDR_LENGTH-1:0]    IM_Addr     ,
    output  wire    [INST_WIDTH-1:0]        IM_Data     ,
    output  wire    [RBITS-1:0]             RB_Addr     ,
    output  wire    [DM_ADDR_LENGTH-1:0]    DM_Addr     ,
    output  wire                            tx          ,
    output  wire                            enable      ,
    output  wire    o_clock     ,           o_rst
);

    // Señales auxiliares
    reg             s_tick      ,           rx_done     ,
                    tx_start    ,           tx_done     ,
                    reset       ,           clk_enable  ;
    reg     [NBITS-1:0]                     rx_Data     ;
    reg     [NBITS-1:0]                     tx_Data     ;
    reg     [NBITS-1:0]                     clock_count ;
    
    assign  enable      =       clk_enable      ;
    
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
        .clock_count        (clock_count)   ,
        .IM_Addr            (IM_Addr)       ,
        .IM_Data            (IM_Data)       ,
        .RB_Addr            (RB_Addr)       ,
        .DM_Addr            (DM_Addr)       ,
        .tx_Data            (tx_Data)       ,
        .tx_start           (tx_start)      ,
        .clock_enable       (clk_enable)    ,
        .o_rst              (reset)
    );
    
    uart_tx         #(
        .DBIT               (NBITS)         ,
        .SB_TICK            (SB_TICK)
    )UARTTX
    (
        .clk                (clk)           ,
        .rst                (rst)           ,
        .tx_start           (tx_start)      ,
        .s_tick             (s_tick)        ,
        .din                (tx_Data)       ,
        .tx_done            (tx_done)       ,
        .tx                 (tx)
    );
    
    uart_rx         #(
        .DBIT               (NBITS)         ,
        .SB_TICK            (SB_TICK)
    )UARTRX
    (
        .clk                (clk)           ,
        .rst                (rst)           ,
        .s_tick             (s_tick)        ,
        .dout               (rx_Data)       ,
        .rx_done            (rx_done)       ,
        .rx                 (rx)
    );
    
    baud_generator  #(
        .N                  (BAUD_SIZ)      ,
        .M                  (BAUD_DIV)
    )BAUDGEN
    (
        .i_clk              (clk)           ,
        .i_reset            (rst)           ,
        .o_max_tick         (s_tick)
    );
    
    clock_control   #(
        .NBITS              (NBITS)
    )CLKCTRL
    (
        .clock              (clk)           ,
        .reset              (reset)         ,
        .enable             (clk_enable)    ,
        .clock_count        (clock_count)   ,
        .o_clock            (o_clock)
    );

endmodule
