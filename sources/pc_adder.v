`timescale 1ns / 1ps

module pc_adder #(

    parameter   MSB     =   32
)
(
    input   wire    [MSB-1:0]   current_pc  ,   //  Entrada desde el incrementador
    output  wire    [MSB-1:0]   next_pc         //  Salida
);

    assign next_pc  =   current_pc + 4      ;   //  Sumo 4 para obtener la proxima instruccion
    
endmodule
