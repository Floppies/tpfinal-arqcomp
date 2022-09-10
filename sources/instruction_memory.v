`timescale 1ns / 1ps

module instruction_memory   #(

    parameter       MEM_SIZE        =   5       ,
    parameter       WORD_WIDTH      =   32      ,
    parameter       ADDR_LENGTH     =   32      ,
    parameter       DATA_LENGTH     =   32
)
(
    input   wire    [ADDR_LENGTH-1:0]   i_Addr  ,
    input   wire    [DATA_LENGTH-1:0]   i_Data  ,
    output  reg     [DATA_LENGTH-1:0]   o_Data
);

reg [WORD_WIDTH-1:0]    ROM_mem[0:MEM_SIZE-1]   ;

initial
    begin
        $readmemb("C:/Users/flopp/OneDrive/Escritorio/program_memory.list", ROM_mem) ;   // ESto es TEMPORAL
    end

always  @(i_Addr)
    begin
        o_Data      <=      ROM_mem[i_Addr]     ;
    end
endmodule