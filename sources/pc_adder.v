`timescale 1ns / 1ps

module pc_adder #(

    parameter   MSB     =   32
)
(
    input   wire    [MSB-1:0]   current_pc  ,
    output  wire    [MSB-1:0]   next_pc
);

    assign next_pc  =   current_pc + 1      ;   //  Sumo 4 para obtener la proxima instruccion
    
endmodule
