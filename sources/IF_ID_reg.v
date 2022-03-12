`timescale 1ns / 1ps

module IF_ID_reg    #(
    parameter       MSB     =   32
)
(
    //Entradas
    input   wire    i_clk   ,   i_rst,  flush   ,
    input   wire    [MSB-1:0]   IF_next_pc      ,
    input   wire    [MSB-1:0]   IF_inst         ,
    //Salidas
    output  reg     [MSB-1:0]   ID_next_pc      ,
    output  reg     [MSB-1:0]   ID_inst
);

always  @(posedge i_clk)
    begin
        if  (i_rst  ||  flush)
        begin
            ID_next_pc  <=      32'b0       ;
            ID_inst     <=      32'b0       ;
        end
        else
        begin
            ID_next_pc  <=      IF_next_pc  ;
            ID_inst     <=      IF_inst     ;
        end
    end

endmodule
