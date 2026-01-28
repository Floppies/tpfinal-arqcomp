`timescale 1ns / 1ps

module EX_MEM_reg   #(
    parameter       NBITS   =   32      ,
    parameter       FBITS   =   3      ,
    parameter       RBITS   =   5
)
(
    //Entradas
    input   wire    i_clk   ,       i_rst           ,
    input   wire    [NBITS-1:0]     EX_result       ,   //ALU result
    input   wire    [NBITS-1:0]     EX_next_inst    ,   //PC+4
    input   wire    [NBITS-1:0]     EX_rs2          ,   //rs2 data for stores
    input   wire    [RBITS-1:0]     EX_rd           ,   //Register
    input   wire    [FBITS-1:0]     EX_sizecontrol  ,   //funct3
    input   wire    EX_memtoreg,    EX_memread      ,
                    EX_regwrite,    EX_memwrite     ,
                    EX_link,        EX_haltflag     ,
    //Salidas
    output  reg     [NBITS-1:0]     MEM_result      ,   //ALU result
    output  reg     [NBITS-1:0]     MEM_next_inst   ,   //PC+4
    output  reg     [NBITS-1:0]     MEM_rs2         ,   //rs2 data for stores
    output  reg     [RBITS-1:0]     MEM_rd          ,   //Register
    output  reg     [FBITS-1:0]     MEM_sizecontrol ,   //funct3
    output  reg     MEM_memtoreg,   MEM_memread     ,
                    MEM_regwrite,   MEM_memwrite    ,
                    MEM_link,       MEM_haltflag
);

always  @(posedge i_clk)
    begin
        if  (i_rst)
        begin
            MEM_result      <=      32'b0           ;
            MEM_next_inst   <=      32'b0           ;
            MEM_rs2         <=      32'b0           ;
            MEM_rd          <=      5'b0            ;
            MEM_sizecontrol <=      3'b0            ;
            MEM_regwrite    <=      0               ;
            MEM_memtoreg    <=      0               ;
            MEM_memread     <=      0               ;
            MEM_memwrite    <=      0               ;
            MEM_link        <=      0               ;
            MEM_haltflag    <=      0               ;
        end
        else
        begin
            MEM_result      <=      EX_result       ;
            MEM_next_inst   <=      EX_next_inst    ;
            MEM_rs2         <=      EX_rs2          ;
            MEM_rd          <=      EX_rd           ;
            MEM_sizecontrol <=      EX_sizecontrol  ;
            MEM_regwrite    <=      EX_regwrite     ;
            MEM_memtoreg    <=      EX_memtoreg     ;
            MEM_memread     <=      EX_memread      ;
            MEM_memwrite    <=      EX_memwrite     ;
            MEM_link        <=      EX_link         ;
            MEM_haltflag    <=      MEM_haltflag    ;
        end
    end

endmodule
