`timescale 1ns / 1ps

module link_adder   #(

    parameter   MSB     =   32
)
(
    input   wire    [MSB-1:0]   next_pc     ,
    output  wire    [MSB-1:0]   link_address    //  Salida
);

    assign link_address     =   next_pc + 4 ;   //  Sumo 4 para obtener la instruccion de enlace
    
endmodule
