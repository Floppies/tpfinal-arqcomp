`timescale 1ns / 1ps

module MEM_WB_reg   #(
    parameter       NBITS   =   32      ,
    parameter       RBITS   =   5
)
(
    //Entradas
    input   wire    i_clk   ,       i_rst           ,
    input   wire    [NBITS-1:0]     MEM_result      ,   //ALU result
    input   wire    [RBITS-1:0]     MEM_rd          ,   //Register
    input   wire    [NBITS-1:0]     MEM_data        ,   //Mem data
    input   wire    [NBITS-1:0]     MEM_next_inst   ,   //PC+4
    input   wire    MEM_regwrite,   MEM_memtoreg    ,
                                    MEM_link        ,
    //Salidas
    output  reg     [NBITS-1:0]     WB_result       ,   //ALU result
    output  reg     [RBITS-1:0]     WB_rd           ,   //Register
    output  reg     [NBITS-1:0]     WB_data         ,   //Mem data
    output  reg     [NBITS-1:0]     WB_next_inst    ,   //PC+4
    output  reg     WB_regwrite ,   WB_memtoreg     ,
                                    WB_link
);

always  @(posedge i_clk)
    begin
        if  (i_rst)
        begin
            WB_result       <=      32'b0           ;
            WB_data         <=      32'b0           ;
            WB_next_inst    <=      32'b0           ;
            WB_rd           <=      5'b0            ;
            WB_regwrite     <=      0               ;
            WB_memtoreg     <=      0               ;
            WB_link         <=      0               ;
        end
        else
        begin
            WB_result       <=      MEM_result      ;
            WB_data         <=      MEM_data        ;
            WB_next_inst    <=      MEM_next_inst   ;
            WB_rd           <=      MEM_rd          ;
            WB_regwrite     <=      MEM_regwrite    ;
            WB_memtoreg     <=      MEM_memtoreg    ;
            WB_link         <=      MEM_link        ;
        end
    end

endmodule