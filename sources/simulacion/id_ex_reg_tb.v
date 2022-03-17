`timescale 10ns / 10ps

module id_ex_reg_tb();

    //Parametros
    localparam      NBITS       =       32      ;
    localparam      RBITS       =       5       ;
    localparam      FBITS       =       6       ;
    
    //Entradas
    reg     [NBITS-1:0]     id_Rs   ,   id_Rt   ;
    reg     [NBITS-1:0]             id_imm      ;
    reg     [RBITS-1:0]     id_rd   ,   id_rt   ;
    reg     [FBITS-1:0]             id_funct    ;
    reg             id_memtoreg ,   id_memread  ,
                    id_memwrite ,   id_alusource,
                    id_link     ,   id_regwrite ,
                    i_clk       ,   i_rst       ,
                                    stallid     ;
    reg     [2:0]                   id_aluop    ;
    reg     [1:0]                   id_regdst   ;
    reg     [4:0]                   id_sizectrl ;
    
    //Salidas
    wire    [NBITS-1:0]     ex_Rs   ,   ex_Rt   ;
    wire    [NBITS-1:0]             ex_imm      ;
    wire    [RBITS-1:0]     ex_rd   ,   ex_rt   ;
    wire    [FBITS-1:0]             ex_funct    ;
    wire            ex_memtoreg ,   ex_memread  ,
                    ex_memwrite ,   ex_alusource,
                    ex_link     ,   ex_regwrite ;
    wire    [2:0]                   ex_aluop    ;
    wire    [1:0]                   ex_regdst   ;
    wire    [4:0]                   ex_sizectrl ;

    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        i_clk       =       1       ;
        i_rst       =       1       ;
        stallid     =       0       ;
        //Ponemos valores a los registros y sus datos
        id_Rs       =       8       ;
        id_Rt       =       9       ;
        id_rd       =       2       ;
        id_rt       =       3       ;
        //Valores para la funcion y el inmediato
        id_funct    =       6'h6    ;
        id_imm      =       15      ;
        //Valores para el control
        id_memtoreg     =   1       ;
        id_memread      =   1       ;
        id_memwrite     =   1       ;
        id_alusource    =   1       ;
        id_link         =   1       ;
        id_regwrite     =   1       ;
        id_aluop        =   4       ;
        id_regdst       =   2       ;
        id_sizectrl     =   5       ;
        #5
        i_rst           =   0       ;
        #10
        stallid         =   1       ;
        #10
        stallid         =   0       ;
        #10
        stallid         =   1       ;
        id_Rs       =       9       ;
        id_Rt       =       8       ;
        id_rd       =       3       ;
        id_rt       =       2       ;
        id_funct    =       6'h5    ;
        id_imm      =       8       ;
        id_memtoreg     =   0       ;
        id_memread      =   0       ;
        id_memwrite     =   1       ;
        id_alusource    =   1       ;
        id_link         =   1       ;
        id_regwrite     =   0       ;
        id_aluop        =   5       ;
        id_regdst       =   1       ;
        id_sizectrl     =   4       ;
        #10
        stallid         =   0       ;
        #20
        $finish;
    end
    
    always begin
        #5
        i_clk       =       ~i_clk  ;
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
        .stallID        (stallid)       ,
        .ID_Rs          (id_Rs)         ,
        .ID_Rt          (id_Rt)         ,
        .ID_rd          (id_rd)         ,
        .ID_rt          (id_rt)         ,
        .ID_funct       (id_funct)      ,
        .ID_immediate   (id_imm)        ,
        .ID_memtoreg    (id_memtoreg)   ,
        .ID_memwrite    (id_memwrite)   ,
        .ID_memread     (id_memread)    ,
        .ID_alusource   (id_alusource)  ,
        .ID_link        (id_link)       ,
        .ID_regwrite    (id_regwrite)   ,
        .ID_aluop       (id_aluop)      ,
        .ID_regdst      (id_regdst)     ,
        .ID_sizecontrol (id_sizectrl)   ,
        .EX_Rs          (ex_Rs)         ,
        .EX_Rt          (ex_Rt)         ,
        .EX_rd          (ex_rd)         ,
        .EX_rt          (ex_rt)         ,
        .EX_funct       (ex_funct)      ,
        .EX_immediate   (ex_imm)        ,
        .EX_memtoreg    (ex_memtoreg)   ,
        .EX_memwrite    (ex_memwrite)   ,
        .EX_memread     (ex_memread)    ,
        .EX_alusource   (ex_alusource)  ,
        .EX_link        (ex_link)       ,
        .EX_regwrite    (ex_regwrite)   ,
        .EX_aluop       (ex_aluop)      ,
        .EX_regdst      (ex_regdst)     ,
        .EX_sizecontrol (ex_sizectrl)
    );

endmodule
