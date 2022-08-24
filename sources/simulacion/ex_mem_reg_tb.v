`timescale 10ns / 10ps

module ex_mem_reg_tb();

    //Parametros
    localparam      NBITS       =       32      ;
    localparam      RBITS       =       5       ;
    
    //Entradas
    reg     [NBITS-1:0]     ex_Rt   ,   ex_rslt ;
    reg     [RBITS-1:0]             ex_rd       ;
    reg             ex_memtoreg ,   ex_memread  ,
                    ex_memwrite ,   ex_regwrite ,
                    i_clk       ,   i_rst       ;
    reg     [4:0]                   ex_szctrl   ;
    
    //Salidas
    wire    [NBITS-1:0]     mem_Rt  ,   mem_rslt;
    wire    [RBITS-1:0]             mem_rd      ;
    wire            mem_memtoreg,   mem_memread ,
                    mem_memwrite,   mem_regwrite;
    wire    [4:0]                   mem_szctrl  ;

    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        i_clk       =       1       ;
        i_rst       =       1       ;
        
        //Ponemos valores a los registros y sus datos
        ex_rslt     =       8       ;
        ex_Rt       =       9       ;
        ex_rd       =       7       ;
        
        //Valores para el control
        ex_memtoreg     =   1       ;
        ex_memread      =   1       ;
        ex_memwrite     =   1       ;
        ex_regwrite     =   1       ;
        ex_szctrl       =   4       ;
        
        #5
        i_rst           =   0       ;
        
        #10
        ex_rslt     =       5       ;
        ex_Rt       =       6       ;
        ex_rd       =       7       ;
        ex_memtoreg     =   0       ;
        ex_memread      =   0       ;
        ex_memwrite     =   0       ;
        ex_regwrite     =   0       ;
        ex_szctrl       =   2       ;
        
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
        .RBITS          (RBITS)
    )exmemregreg
    (
        .i_clk          (i_clk)         ,
        .i_rst          (i_rst)         ,
        .EX_Rt          (ex_Rt)         ,
        .EX_rd          (ex_rd)         ,
        .EX_result      (ex_rslt)       ,
        .EX_memtoreg    (ex_memtoreg)   ,
        .EX_memwrite    (ex_memwrite)   ,
        .EX_memread     (ex_memread)    ,
        .EX_regwrite    (ex_regwrite)   ,
        .EX_sizecontrol (ex_szctrl)     ,
        .MEM_result     (mem_rslt)      ,
        .MEM_Rt         (mem_Rt)        ,
        .MEM_rd         (mem_rd)        ,
        .MEM_memtoreg   (mem_memtoreg)  ,
        .MEM_memread    (mem_memread)   ,
        .MEM_memwrite   (mem_memwrite)  ,
        .MEM_regwrite   (mem_regwrite)  ,
        .MEM_sizecontrol(mem_szctrl)
    );

endmodule
