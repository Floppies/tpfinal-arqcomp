`timescale 1ns / 1ps

module instruction_memory   #(

    parameter       MEM_SIZE        =   1024    ,
    parameter       WORD_WIDTH      =   32      ,
    parameter       ADDR_LENGTH     =   32      ,
    parameter       DATA_LENGTH     =   32      ,
    parameter       MEMFILE         =   ""
    )
    (
    input   wire    i_clk           ,   We      ,
    input   wire    [ADDR_LENGTH-1:0]   i_Addr  ,
    input   wire    [DATA_LENGTH-1:0]   i_Data  ,
    output  reg     [DATA_LENGTH-1:0]   o_Data
    );

    reg [WORD_WIDTH-1:0]    mem[0:MEM_SIZE-1]   ;

    integer k;
    initial begin
        if (MEMFILE != "") $readmemb(MEMFILE, mem);
    end

    //Write
    always @(posedge i_clk) begin
        if (We) begin
            mem[i_Addr] <= i_Data;
        end
    end

    //Read
    always @(*) begin
        o_Data = mem[i_Addr];
    end

endmodule