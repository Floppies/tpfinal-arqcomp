`timescale 1ns / 1ps

module ID_EX_reg    #(
    parameter       NBITS   =   32      ,
    parameter       RBITS   =   5       ,
    parameter       FBITS   =   6       
)
(
    //Entradas
    input   wire    i_clk   ,       i_rst,  i_nop   ,
    input   wire    [NBITS-1:0]     ID_Rs,  ID_Rt   ,   //Datos de los registros
    input   wire    [RBITS-1:0]     ID_rd,  ID_rt   ,   //Nombre de los registros
    input   wire    [FBITS-1:0]     ID_funct        ,
    input   wire    [NBITS-1:0]     ID_immediate    ,
    input   wire    [4:0]           ID_sizecontrol  ,
    input   wire    ID_memtoreg,    ID_memread      ,
                    ID_memwrite,    ID_alusource    ,
                    ID_link,        ID_regwrite     ,
                                    ID_haltflag     ,
    input   wire    [2:0]           ID_aluop        ,
    input   wire    [1:0]           ID_regdst       ,
    //Salidas
    output  reg     [NBITS-1:0]     EX_Rs,  EX_Rt   ,   //Datos de los registros
    output  reg     [RBITS-1:0]     EX_rd,  EX_rt   ,   //Nombre de los registros
    output  reg     [FBITS-1:0]     EX_funct        ,
    output  reg     [NBITS-1:0]     EX_immediate    ,
    output  reg     [4:0]           EX_sizecontrol  ,
    output  reg     EX_memtoreg,    EX_memread      ,
                    EX_memwrite,    EX_alusource    ,
                    EX_link,        EX_regwrite     ,
                                    EX_haltflag     ,
    output  reg     [2:0]           EX_aluop        ,
    output  reg     [1:0]           EX_regdst
);

always  @(posedge i_clk)
    begin
        if  (i_rst  ||  i_nop)
        begin
            EX_Rs           <=      32'b0           ;
            EX_Rt           <=      32'b0           ;
            EX_immediate    <=      32'b0           ;
            EX_rd           <=      5'b0            ;
            EX_rt           <=      5'b0            ;
            EX_funct        <=      6'b0            ;
            EX_sizecontrol  <=      5'b0            ;
            EX_regwrite     <=      0               ;
            EX_memtoreg     <=      0               ;
            EX_memread      <=      0               ;
            EX_memwrite     <=      0               ;
            EX_alusource    <=      0               ;
            EX_link         <=      0               ;
            EX_aluop        <=      2'b0            ;
            EX_regdst       <=      2'b0            ;
        end
        else
        begin
            EX_Rs           <=      ID_Rs           ;
            EX_Rt           <=      ID_Rt           ;
            EX_immediate    <=      ID_immediate    ;
            EX_rd           <=      ID_rd           ;
            EX_rt           <=      ID_rt           ;
            EX_funct        <=      ID_funct        ;
            EX_sizecontrol  <=      ID_sizecontrol  ;
            EX_regwrite     <=      ID_regwrite     ;
            EX_memtoreg     <=      ID_memtoreg     ;
            EX_memread      <=      ID_memread      ;
            EX_memwrite     <=      ID_memwrite     ;
            EX_alusource    <=      ID_alusource    ;
            EX_link         <=      ID_link         ;
            EX_aluop        <=      ID_aluop        ;
            EX_regdst       <=      ID_regdst       ;
        end
    end

endmodule
