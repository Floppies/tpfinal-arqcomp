`timescale 10ns / 10ps

module mem_wb_reg_tb();
    //Parametros
    localparam      NBITS   =   32      ;
    localparam      FBITS   =   3       ;
    localparam      RBITS   =   5       ;

    //Entradas
    reg     [NBITS-1:0] mem_data    , mem_rslt    , mem_next_inst ;
    reg     [RBITS-1:0] mem_rd      ;
    reg     [FBITS-1:0] mem_size    ;
    reg                 mem_memtoreg, mem_regwrite,
                        mem_link    , mem_haltflag,
                        i_clk       , i_rst       ;

    //Salidas
    wire    [NBITS-1:0] wb_data , wb_rslt , wb_next_inst ;
    wire    [RBITS-1:0] wb_rd   ;
    wire    [FBITS-1:0] wb_size ;
    wire                wb_memtoreg , wb_regwrite,
                        wb_link     , wb_haltflag ;

    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        i_clk       =   1       ;
        i_rst       =   1       ;

        // Valores iniciales
        mem_data    =   32'h0000_0008 ;
        mem_rslt    =   32'h0000_0009 ;
        mem_next_inst = 32'h0000_0004 ;
        mem_rd      =   5'd7          ;
        mem_size    =   3'b010        ;
        mem_memtoreg=   1'b1          ;
        mem_regwrite=   1'b1          ;
        mem_link    =   1'b0          ;
        mem_haltflag=   1'b0          ;

        #5
        i_rst       =   0       ;

        // Cambio de datos y control
        #10
        mem_data    =   32'h0000_0004 ;
        mem_rslt    =   32'h0000_0007 ;
        mem_next_inst = 32'h0000_0008 ;
        mem_rd      =   5'd5          ;
        mem_size    =   3'b101        ;
        mem_memtoreg=   1'b0          ;
        mem_regwrite=   1'b0          ;
        mem_link    =   1'b1          ;
        mem_haltflag=   1'b1          ;

        // Otro cambio
        #10
        mem_data    =   32'hDEAD_BEEF ;
        mem_rslt    =   32'h1234_5678 ;
        mem_next_inst = 32'h0000_000C ;
        mem_rd      =   5'd31         ;
        mem_size    =   3'b000        ;
        mem_memtoreg=   1'b1          ;
        mem_regwrite=   1'b1          ;
        mem_link    =   1'b1          ;
        mem_haltflag=   1'b0          ;

        #20
        $finish;
    end

    always begin
        #5
        i_clk       =   ~i_clk  ;
    end

    MEM_WB_reg
    #(
        .NBITS          (NBITS)     ,
        .FBITS          (FBITS)     ,
        .RBITS          (RBITS)
    )memwbregreg
    (
        .i_clk          (i_clk)         ,
        .i_rst          (i_rst)         ,
        .MEM_result     (mem_rslt)      ,
        .MEM_rd         (mem_rd)        ,
        .MEM_data       (mem_data)      ,
        .MEM_next_inst  (mem_next_inst) ,
        .MEM_sizecontrol(mem_size)      ,
        .MEM_regwrite   (mem_regwrite)  ,
        .MEM_memtoreg   (mem_memtoreg)  ,
        .MEM_link       (mem_link)      ,
        .MEM_haltflag   (mem_haltflag)  ,
        .WB_result      (wb_rslt)       ,
        .WB_rd          (wb_rd)         ,
        .WB_data        (wb_data)       ,
        .WB_next_inst   (wb_next_inst)  ,
        .WB_sizecontrol (wb_size)       ,
        .WB_regwrite    (wb_regwrite)   ,
        .WB_memtoreg    (wb_memtoreg)   ,
        .WB_link        (wb_link)       ,
        .WB_haltflag    (wb_haltflag)
    );

endmodule
