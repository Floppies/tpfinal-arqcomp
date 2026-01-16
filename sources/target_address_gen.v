`timescale 1ns / 1ps

module target_address_gen   #(
    parameter       MSB     =   32
)
(
    //Entradas
    input   wire    [MSB-1:0]   current_pc  ,
    input   wire    [MSB-1:0]   rs1         ,
    input   wire    [MSB-1:0]   immediate   ,
    input   wire                Jump_reg    ,
    //Salidas
    output  wire     [MSB-1:0]   target_address
);

wire    [MSB-1:0]   jal_target  = current_pc + immediate;
wire    [MSB-1:0]   jalr_target = (rs1 + immediate) & ~32'b1;

assign target_address   =   Jump_reg ? jalr_target : jal_target;

endmodule