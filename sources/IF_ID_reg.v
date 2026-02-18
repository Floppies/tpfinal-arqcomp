`timescale 1ns / 1ps

module IF_ID_reg    #(
    parameter       MSB     =   32
)
(
    //Entradas
    input   wire    i_clk   ,   i_rst,  flush   ,   cpu_en  ,
    input   wire    [MSB-1:0]   IF_next_pc      ,
    input   wire    [MSB-1:0]   IF_current_pc   ,
    input   wire    [MSB-1:0]   IF_inst         ,
    input   wire                We              ,
    //Salidas
    output  reg     [MSB-1:0]   ID_next_pc      ,
    output  reg     [MSB-1:0]   ID_current_pc   ,
    output  reg     [MSB-1:0]   ID_inst
);

always  @(posedge i_clk or posedge i_rst)
    begin
        if  (i_rst)
        begin
            ID_next_pc      <=  32'b0           ;
            ID_inst         <=  32'b0           ;
            ID_current_pc   <=  32'b0           ;
        end
        else if (cpu_en &   (flush   |   We))
        begin
            ID_next_pc      <=  flush   ?   32'b0       :   IF_next_pc      ;
            ID_inst         <=  flush   ?   32'b0       :   IF_inst         ;
            ID_current_pc   <=  flush   ?   32'b0       :   IF_current_pc   ;
        end
    end

endmodule
