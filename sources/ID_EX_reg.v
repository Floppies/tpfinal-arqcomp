`timescale 1ns / 1ps

module ID_EX_reg    #(
    parameter       NBITS   =   32      ,
    parameter       RBITS   =   5       ,
    parameter       FBITS   =   4       
)
(
    //Entradas
    input   wire    i_clk   ,       i_rst,  ID_EX_flush ,   cpu_en  ,
    input   wire    [NBITS-1:0]     ID_Rs1, ID_Rs2      ,   //Register data
    input   wire    [NBITS-1:0]     ID_next_pc          ,   //PC+4
    input   wire    [RBITS-1:0]     ID_rd               ,   //Register address
    input   wire    [RBITS-1:0]     ID_rs1, ID_rs2      ,
    input   wire    [FBITS-1:0]     ID_funct            ,   //funct7,funct3
    input   wire    [NBITS-1:0]     ID_immediate        ,
    input   wire    [NBITS-1:0]     ID_jump_address     ,
    input   wire    ID_memtoreg,    ID_memread          ,
                    ID_memwrite,    ID_alusource        ,
                    ID_link,        ID_regwrite         ,
                    ID_JumpReg,     ID_BNE, ID_BEQ      ,
                                    ID_halt             ,
    input   wire    [1:0]           ID_aluop            ,
    //Salidas
    output  reg     [NBITS-1:0]     EX_Rs1, EX_Rs2      ,   //Registers data
                                    EX_next_pc          ,
    output  reg     [RBITS-1:0]     EX_rd               ,   //Register address
                                    EX_rs1, EX_rs2      ,
    output  reg     [FBITS-1:0]     EX_funct            ,   //funct7,funct3
    output  reg     [NBITS-1:0]     EX_immediate        ,
    output  reg     [NBITS-1:0]     EX_jump_address     ,
    output  reg     EX_memtoreg,    EX_memread          ,
                    EX_memwrite,    EX_alusource        ,
                    EX_link,        EX_regwrite         ,
                    EX_JumpReg,     EX_BNE, EX_BEQ      ,
                                    EX_halt             ,
    output  reg     [1:0]           EX_aluop
);

always  @(posedge i_clk or posedge i_rst)
    begin
        if  (i_rst)
        begin
            EX_Rs1          <=      32'b0           ;
            EX_Rs2          <=      32'b0           ;
            EX_immediate    <=      32'b0           ;
            EX_next_pc      <=      32'b0           ;
            EX_jump_address <=      32'b0           ;
            EX_rd           <=      5'b0            ;
            EX_rs1          <=      5'b0            ;
            EX_rs2          <=      5'b0            ;
            EX_funct        <=      4'b0            ;
            EX_regwrite     <=      0               ;
            EX_memtoreg     <=      0               ;
            EX_memread      <=      0               ;
            EX_memwrite     <=      0               ;
            EX_alusource    <=      0               ;
            EX_link         <=      0               ;
            EX_JumpReg      <=      0               ;
            EX_BEQ          <=      0               ;
            EX_BNE          <=      0               ;
            EX_halt         <=      0               ;
            EX_aluop        <=      2'b0            ;
        end
        else if (cpu_en)
        begin
            EX_Rs1          <=      ID_EX_flush ?   32'b0       :   ID_Rs1          ;
            EX_Rs2          <=      ID_EX_flush ?   32'b0       :   ID_Rs2          ;
            EX_immediate    <=      ID_EX_flush ?   32'b0       :   ID_immediate    ;
            EX_jump_address <=      ID_EX_flush ?   32'b0       :   ID_jump_address ;
            EX_next_pc      <=      ID_EX_flush ?   32'b0       :   ID_next_pc      ;
            EX_rd           <=      ID_EX_flush ?   5'b0        :   ID_rd           ;
            EX_rs1          <=      ID_EX_flush ?   5'b0        :   ID_rs1          ;
            EX_rs2          <=      ID_EX_flush ?   5'b0        :   ID_rs2          ;
            EX_funct        <=      ID_EX_flush ?   4'b0        :   ID_funct        ;
            EX_regwrite     <=      ID_EX_flush ?   1'b0        :   ID_regwrite     ;
            EX_memtoreg     <=      ID_EX_flush ?   1'b0        :   ID_memtoreg     ;
            EX_memread      <=      ID_EX_flush ?   1'b0        :   ID_memread      ;
            EX_memwrite     <=      ID_EX_flush ?   1'b0        :   ID_memwrite     ;
            EX_alusource    <=      ID_EX_flush ?   1'b0        :   ID_alusource    ;
            EX_link         <=      ID_EX_flush ?   1'b0        :   ID_link         ;
            EX_JumpReg      <=      ID_EX_flush ?   1'b0        :   ID_JumpReg      ;
            EX_BEQ          <=      ID_EX_flush ?   1'b0        :   ID_BEQ          ;
            EX_BNE          <=      ID_EX_flush ?   1'b0        :   ID_BNE          ;
            EX_halt         <=      ID_EX_flush ?   1'b0        :   ID_halt         ;
            EX_aluop        <=      ID_EX_flush ?   2'b0        :   ID_aluop        ;
        end
    end

endmodule
