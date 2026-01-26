`timescale 1ns / 1ps

module branch_adder #(

    parameter   MSB     =   32
)
(
    input   wire    [MSB-1:0]   current_pc      ,   //  Current instruction address
    input   wire    [MSB-1:0]   offset          ,   //  imm
    output  wire    [MSB-1:0]   branch_addr         //  Target Address
);

    assign branch_addr  =   next_pc + offset    ;
    
endmodule
