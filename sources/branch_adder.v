`timescale 1ns / 1ps

module branch_adder #(

    parameter   MSB     =   32
)
(
    input   wire    [MSB-1:0]   current_pc      ,   //  Current instruction address
    input   wire    [MSB-1:0]   offset          ,   //  imm
    output  wire    [MSB-1:0]   branch_addr         //  Target Address
);

    wire signed [MSB-1:0] offset_words;

    // The ISA immediate is encoded in bytes, but this design uses a word-addressed PC.
    assign offset_words = $signed(offset) >>> 2;
    assign branch_addr  = current_pc + offset_words;
    
endmodule
