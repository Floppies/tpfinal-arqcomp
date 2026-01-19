`timescale 10ns / 10ps

module ex_mem_reg_tb();

    //Parametros
    localparam      NBITS       =       32      ;
    localparam      RBITS       =       5       ;
    localparam      FBITS       =       3       ;
    
    //Entradas
    reg     [NBITS-1:0]     ex_ni,  ex_rslt     ;
    reg     [RBITS-1:0]             ex_rd       ;
    reg     [FBITS-1:0]             ex_szctrl   ;
    reg             ex_memtoreg ,   ex_memread  ,
                    ex_memwrite ,   ex_regwrite ,
                    ex_link     ,   ex_haltflag ,
                    i_clk       ,   i_rst       ;
    
    //Salidas
    wire    [NBITS-1:0]     mem_ni  ,   mem_rslt;
    wire    [RBITS-1:0]             mem_rd      ;
    wire    [FBITS-1:0]             mem_szctrl  ;
    wire            mem_memtoreg,   mem_memread ,
                    mem_memwrite,   mem_regwrite,
                    mem_link    ,   mem_haltflag;

    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        i_clk       =       1       ;
        i_rst       =       1       ;
        
        //Ponemos valores a los registros y sus datos
        ex_rslt     =       8       ;
        ex_ni       =       9       ;
        ex_rd       =       7       ;
        
        //Valores para el control
        ex_memtoreg     =   1       ;
        ex_memread      =   1       ;
        ex_memwrite     =   1       ;
        ex_regwrite     =   1       ;
        ex_szctrl       =   4       ;
        ex_link         =   1       ;
        ex_haltflag     =   1       ;
        
        #5
        i_rst           =   0       ;
        
        #10
        ex_rslt     =       5       ;
        ex_ni       =       6       ;
        ex_rd       =       7       ;
        ex_memtoreg     =   0       ;
        ex_memread      =   0       ;
        ex_memwrite     =   0       ;
        ex_regwrite     =   0       ;
        ex_szctrl       =   2       ;
        
        ex_link         =   0       ;
        ex_haltflag     =   0       ;
        
        #20
        $finish;
    end
    
    always begin
        #5
        i_clk       =       ~i_clk  ;
    end
    
    EX_MEM_reg
    #(
        .NBITS          (NBITS)     ,
        .RBITS          (RBITS)     ,
        .FBITS          (FBITS)
    )exmemregreg
    (
        .i_clk          (i_clk)         ,
        .i_rst          (i_rst)         ,
        .EX_next_inst   (ex_ni)         ,
        .EX_rd          (ex_rd)         ,
        .EX_result      (ex_rslt)       ,
        .EX_memtoreg    (ex_memtoreg)   ,
        .EX_memwrite    (ex_memwrite)   ,
        .EX_memread     (ex_memread)    ,
        .EX_regwrite    (ex_regwrite)   ,
        .EX_sizecontrol (ex_szctrl)     ,
        .EX_link        (ex_link)       ,
        .EX_haltflag    (ex_haltflag)   ,
        .MEM_result     (mem_rslt)      ,
        .MEM_next_inst  (mem_ni)        ,
        .MEM_rd         (mem_rd)        ,
        .MEM_memtoreg   (mem_memtoreg)  ,
        .MEM_memread    (mem_memread)   ,
        .MEM_memwrite   (mem_memwrite)  ,
        .MEM_regwrite   (mem_regwrite)  ,
        .MEM_link       (mem_link)      ,
        .MEM_haltflag   (mem_haltflag)  ,
        .MEM_sizecontrol(mem_szctrl)
    );

endmodule
