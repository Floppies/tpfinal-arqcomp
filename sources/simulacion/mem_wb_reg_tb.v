`timescale 10ns / 10ps

module mem_wb_reg_tb();
//Parametros
    localparam      NBITS       =       32      ;
    localparam      RBITS       =       5       ;
    
    //Entradas
    reg     [NBITS-1:0] mem_data    ,   mem_rslt;
    reg     [RBITS-1:0]             mem_rd      ;
    reg             mem_memtoreg,   mem_regwrite,
                    i_clk       ,   i_rst       ;
    
    //Salidas
    wire    [NBITS-1:0] wb_data ,   wb_rslt     ;
    wire    [RBITS-1:0]             wb_rd       ;
    wire            wb_memtoreg ,   wb_regwrite ;

    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        i_clk       =       1       ;
        i_rst       =       1       ;
        
        //Ponemos valores a los registros y sus datos
        mem_data    =       8       ;
        mem_rslt    =       9       ;
        mem_rd      =       7       ;
        
        //Valores para el control
        mem_memtoreg    =   1       ;
        mem_regwrite    =   1       ;
        
        #5
        i_rst           =   0       ;
        
        #10
        mem_data    =       4       ;
        mem_rslt    =       7       ;
        mem_rd      =       5       ;
        mem_memtoreg    =   0       ;
        mem_regwrite    =   0       ;
        
        #20
        $finish;
    end
    
    always begin
        #5
        i_clk       =       ~i_clk  ;
    end
    
    MEM_WB_reg
    #(
        .NBITS          (NBITS)     ,
        .RBITS          (RBITS)
    )memwbregreg
    (
        .i_clk          (i_clk)         ,
        .i_rst          (i_rst)         ,
        .MEM_result     (mem_rslt)      ,
        .MEM_data       (mem_data)      ,
        .MEM_rd         (mem_rd)        ,
        .MEM_memtoreg   (mem_memtoreg)  ,
        .MEM_regwrite   (mem_regwrite)  ,
        .WB_result      (wb_rslt)       ,
        .WB_data        (wb_data)       ,
        .WB_rd          (wb_rd)         ,
        .WB_regwrite    (wb_regwrite)   ,
        .WB_memtoreg    (wb_memtoreg)
    );

endmodule
