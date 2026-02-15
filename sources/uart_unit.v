`timescale 1ns / 1ps

module uart_unit    #(
    parameter   SB_TICK             =       16      ,
    parameter   BAUD_DIV            =       163     ,
    parameter   BAUD_SIZ            =       8       ,
    parameter   DBIT                =       8
)
(
    //  Entradas
    input   wire    clk         ,   reset       ,
                    rx          ,   tx_start    ,
    input   wire    [DBIT-1:0]      tx_Data     ,
    
    //  Salidas
    output  wire    tx          ,   tx_done     ,
                                    rx_done     ,
    output  wire    [DBIT-1:0]      rx_Data
);

    //  Senal auxiliar
    wire    s_tick      ;
    
    uart_tx         #(
        .DBIT               (DBIT)          ,
        .SB_TICK            (SB_TICK)
    )UARTTX
    (
        .clk                (clk)           ,
        .reset              (reset)         ,
        .tx_start           (tx_start)      ,
        .s_tick             (s_tick)        ,
        .din                (tx_Data)       ,
        .tx_done            (tx_done)       ,
        .tx                 (tx)
    );
    
    uart_rx         #(
        .DBIT               (DBIT)          ,
        .SB_TICK            (SB_TICK)
    )UARTRX
    (
        .clk                (clk)           ,
        .reset              (reset)         ,
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
        .i_reset            (reset)         ,
        .o_max_tick         (s_tick)
    );
    
endmodule
