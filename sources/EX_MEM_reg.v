`timescale 1ns / 1ps

module EX_MEM_reg   #(
    parameter       NBITS   =   32      ,
    parameter       RBITS   =   5
)
(
    //Entradas
    input   wire    i_clk   ,       i_rst           ,
    input   wire    [NBITS-1:0]     EX_result       ,   //Resultado de la ALU
    input   wire    [RBITS-1:0]     EX_rd           ,   //Nombre de los registros
    input   wire    [NBITS-1:0]     EX_Rt           ,
    input   wire    [4:0]           EX_sizecontrol  ,
    input   wire    EX_memtoreg,    EX_memread      ,
                    EX_regwrite,    EX_memwrite     ,
    //Salidas
    output  reg     [NBITS-1:0]     MEM_result      ,   //Resultado de la ALU
    output  reg     [RBITS-1:0]     MEM_rd          ,   //Nombre de los registros
    output  reg     [NBITS-1:0]     MEM_Rt          ,
    output  reg     [4:0]           MEM_sizecontrol ,
    output  reg     MEM_memtoreg,   MEM_memread     ,
                    MEM_regwrite,   MEM_memwrite
);

always  @(posedge i_clk)
    begin
        if  (i_rst)
        begin
            MEM_result      <=      32'b0           ;
            MEM_Rt          <=      32'b0           ;
            MEM_rd          <=      5'b0            ;
            MEM_sizecontrol <=      5'b0            ;
            MEM_regwrite    <=      0               ;
            MEM_memtoreg    <=      0               ;
            MEM_memread     <=      0               ;
            MEM_memwrite    <=      0               ;
        end
        else
        begin
            MEM_result      <=      EX_result       ;
            MEM_Rt          <=      EX_Rt           ;
            MEM_rd          <=      EX_rd           ;
            MEM_sizecontrol <=      EX_sizecontrol  ;
            MEM_regwrite    <=      EX_regwrite     ;
            MEM_memtoreg    <=      EX_memtoreg     ;
            MEM_memread     <=      EX_memread      ;
            MEM_memwrite    <=      EX_memwrite     ;
        end
    end

endmodule
