`timescale 1ns / 1ps

module branch_adder #(

    parameter   MSB     =   32
)
(
    input   wire    [MSB-1:0]   next_pc         ,   //  Entrada desde el incrementador
    input   wire    [MSB-1:0]   offset          ,   //  Entrada desde el incrementador
    output  wire    [MSB-1:0]   branch_addr         //  Salida
);

    assign branch_addr  =   next_pc + offset    ;   //  La direccion
    
endmodule
