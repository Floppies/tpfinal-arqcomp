`timescale 1ns / 1ps

module uart_unit    #(
    parameter   SB_TICK             =       16      ,   //TENGO QUE CAMBIAR ??
    parameter   BAUD_DIV            =       163     ,
    parameter   BAUD_SIZ            =       8       ,
    parameter   NBITS               =       32
)
(
    //  Entradas
    input   wire    clk         ,   reset       ,
                    rx          ,   tx_start    ,
    input   wire    [NBITS-1:0]     tx_Data     ,
    
    //  Salidas
    output  wire    tx          ,   tx_done     ,
                                    rx_done     ,
    output  wire    [NBITS-1:0]     rx_Data
);

    //  Señal auxiliar
    reg     s_tick      ;
    
    uart_tx         #(
        .DBIT               (NBITS)         ,
        .SB_TICK            (SB_TICK)
    )UARTTX
    (
        .clk                (clk)           ,
        .rst                (reset)         ,
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
        .rst                (reset)         ,
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
    
endmodule
