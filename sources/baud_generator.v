`timescale 1ns / 1ps

module baud_generator #(
    parameter N     =       4       ,   // Cantidad de bits del counter
    parameter M     =       10          // Mod M
)(
    input   wire    i_clk           ,
    input   wire    i_reset         ,
    output  wire    o_max_tick
);

//  Declaracion de se?ales
reg     [N-1:0]     r_reg           ;
wire    [N-1:0]     r_next          ;

//  L?gica del reset
always  @(posedge i_clk,    posedge i_reset)
    if  (i_reset)
        r_reg   <=      0           ;
    else
        r_reg   <=      r_next      ;

//  Logica de proximo estado
assign r_next       =   (r_reg==(M-1)) ? 0 : r_reg + 1  ;

//  Logica de salida
assign o_max_tick   =   (r_reg==(M-1)) ? 1'b1 : 1'b0    ;

endmodule