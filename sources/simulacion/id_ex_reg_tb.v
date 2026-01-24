`timescale 10ns / 10ps

module id_ex_reg_tb();

    //Parametros
    localparam      NBITS       =   32      ;
    localparam      RBITS       =   5       ;
    localparam      FBITS       =   4       ;

    //Entradas
    reg     [NBITS-1:0]     id_rs1      ,   id_rs2      ;
    reg     [NBITS-1:0]     id_imm      ,   id_next_pc  ;
    reg     [RBITS-1:0]     id_rd       ;
    reg     [FBITS-1:0]     id_funct    ;
    reg                     id_memtoreg ,   id_memread  ,
                            id_memwrite ,   id_alusource,
                            id_link     ,   id_regwrite ,
                            id_jumpreg  ,   id_bne      ,
                            id_beq      ,
                            i_clk       ,   i_rst       ,
                            id_ex_flush ,   we          ;
    reg     [2:0]           id_aluop    ;

    //Salidas
    wire    [NBITS-1:0]     ex_rs1      ,   ex_rs2      ;
    wire    [NBITS-1:0]     ex_imm      ;
    wire    [RBITS-1:0]     ex_rd       ;
    wire    [FBITS-1:0]     ex_funct    ;
    wire                    ex_memtoreg ,   ex_memread  ,
                            ex_memwrite ,   ex_alusource,
                            ex_jumpreg  ,   ex_bne      ,
                            ex_beq      ,
                            ex_link     ,   ex_regwrite ;
    wire    [2:0]           ex_aluop    ;

    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        i_clk       =   1       ;
        i_rst       =   1       ;
        id_ex_flush =   0       ;
        we          =   1       ;

        // Valores iniciales
        id_rs1      =   32'h0000_0008 ;
        id_rs2      =   32'h0000_0009 ;
        id_rd       =   5'd2          ;
        id_funct    =   10'h006       ;
        id_imm      =   32'h0000_000F ;
        id_next_pc  =   32'h0000_0004 ;
        id_memtoreg =   1'b1          ;
        id_memread  =   1'b1          ;
        id_memwrite =   1'b0          ;
        id_alusource=   1'b1          ;
        id_jumpreg  =   1'b1          ;
        id_bne      =   1'b0          ;
        id_beq      =   1'b1          ;
        id_link     =   1'b0          ;
        id_regwrite =   1'b1          ;
        id_aluop    =   3'b100        ;

        #5
        i_rst       =   0       ;

        // Carga normal
        #10
        id_rs1      =   32'h0000_0011 ;
        id_rs2      =   32'h0000_0022 ;
        id_rd       =   5'd3          ;
        id_funct    =   10'h015       ;
        id_imm      =   32'h0000_0008 ;
        id_next_pc  =   32'h0000_0008 ;
        id_memtoreg =   1'b0          ;
        id_memread  =   1'b0          ;
        id_memwrite =   1'b1          ;
        id_alusource=   1'b0          ;
        id_link     =   1'b1          ;
        id_regwrite =   1'b0          ;
        id_aluop    =   3'b010        ;

        // Flush (debe limpiar)
        #10
        id_ex_flush =   1       ;

        // Hold con We=0 (no cambia salidas)
        #10
        id_ex_flush =   0       ;
        we          =   0       ;
        id_rs1      =   32'h0000_00AA ;
        id_rs2      =   32'h0000_00BB ;
        id_rd       =   5'd4          ;
        id_funct    =   10'h3FF       ;
        id_imm      =   32'h0000_00CC ;
        id_next_pc  =   32'h0000_000C ;
        id_memtoreg =   1'b1          ;
        id_memread  =   1'b1          ;
        id_memwrite =   1'b1          ;
        id_alusource=   1'b1          ;
        id_link     =   1'b1          ;
        id_regwrite =   1'b1          ;
        id_aluop    =   3'b111        ;

        // Re-enable write (debe cargar nuevos valores)
        #10
        we          =   1       ;

        #20
        $finish;
    end

    always begin
        #5
        i_clk       =   ~i_clk  ;
    end

    ID_EX_reg
    #(
        .NBITS          (NBITS)     ,
        .FBITS          (FBITS)     ,
        .RBITS          (RBITS)
    )idexregreg
    (
        .i_clk          (i_clk)         ,
        .i_rst          (i_rst)         ,
        .ID_EX_flush    (id_ex_flush)   ,
        .We             (we)            ,
        .ID_Rs1         (id_rs1)        ,
        .ID_Rs2         (id_rs2)        ,
        .next_pc        (id_next_pc)    ,
        .ID_rd          (id_rd)         ,
        .ID_funct       (id_funct)      ,
        .ID_immediate   (id_imm)        ,
        .ID_memtoreg    (id_memtoreg)   ,
        .ID_memread     (id_memread)    ,
        .ID_memwrite    (id_memwrite)   ,
        .ID_JumpReg     (id_jumpreg)    ,
        .ID_BEQ         (id_beq)        ,
        .ID_BNE         (id_bne)        ,
        .ID_alusource   (id_alusource)  ,
        .ID_link        (id_link)       ,
        .ID_regwrite    (id_regwrite)   ,
        .ID_aluop       (id_aluop)      ,
        .EX_Rs1         (ex_rs1)        ,
        .EX_Rs2         (ex_rs2)        ,
        .EX_rd          (ex_rd)         ,
        .EX_funct       (ex_funct)      ,
        .EX_immediate   (ex_imm)        ,
        .EX_memtoreg    (ex_memtoreg)   ,
        .EX_memread     (ex_memread)    ,
        .EX_memwrite    (ex_memwrite)   ,
        .EX_alusource   (ex_alusource)  ,
        .EX_link        (ex_link)       ,
        .EX_regwrite    (ex_regwrite)   ,
        .EX_JumpReg     (ex_jumpreg)    ,
        .EX_BEQ         (ex_beq)        ,
        .EX_BNE         (ex_bne)        ,
        .EX_aluop       (ex_aluop)
    );

endmodule
