`timescale 1ns / 1ps

module instruction_memory   #(

    parameter       MEM_SIZE        =   5       ,
    parameter       WORD_WIDTH      =   32      ,
    parameter       ADDR_LENGTH     =   32      ,
    parameter       DATA_LENGTH     =   32
)
(
    input   wire    i_clk       ,       i_rst   ,
    input   wire                        We      ,
    input   wire    [ADDR_LENGTH-1:0]   i_Addr  ,
    input   wire    [DATA_LENGTH-1:0]   i_Data  ,
    output  reg     [DATA_LENGTH-1:0]   o_Data
);

reg [WORD_WIDTH-1:0]    RAM_mem[0:MEM_SIZE-1]   ;


//  Bloque que maneja la lectura de la RAM
always  @(i_clk)
    begin
            o_Data      <=  RAM_mem[i_Addr]     ;
    end
    
//  Bloque que maneja la escritura de la RAM
always @(posedge i_clk)
    begin
        if  (We)
            RAM_mem[i_Addr]     <=  i_Data      ;
    end

endmodule