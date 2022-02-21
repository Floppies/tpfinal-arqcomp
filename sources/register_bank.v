`timescale 1ns / 1ps

module register_bank    #(
    parameter       BANK_SIZE       =   32      ,
    parameter       WORD_WIDTH      =   32      ,
    parameter       ADDR_LENGTH     =   5       ,
    parameter       DATA_LENGTH     =   32
)
(
    input   wire    i_clk,  i_rst,  enable      ,
    input   wire    [ADDR_LENGTH-1:0]   i_reg1  ,
    input   wire    [ADDR_LENGTH-1:0]   i_reg2  ,
    input   wire    [ADDR_LENGTH-1:0]   i_regW  ,
    input   wire    [DATA_LENGTH-1:0]   i_Data  ,
    output  wire    [DATA_LENGTH-1:0]   o_rg1D  ,
    output  wire    [DATA_LENGTH-1:0]   o_rg2D
    
);

reg [WORD_WIDTH-1:0]    reg_bank[0:BANK_SIZE-1] ;   //  Banco de Registros
reg     i       ;

assign  o_rg1D      =   reg_bank[i_reg1]        ;
assign  o_rg2D      =   reg_bank[i_reg2]        ;

always  @(negedge i_clk)
    begin
        if  (i_rst)
        begin
            // set all registers to their defaults 
            for(i = 0; i < 32; i = i + 1 )
                reg_bank[i]     =       32'h0   ;
        end
        else if (enable)
            reg_bank[i_regW]    =       i_Data  ;   //  Write back the register
    end
endmodule
