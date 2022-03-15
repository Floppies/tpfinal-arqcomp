`timescale 1ns / 1ps

module forwarding_unit_tb();

    //Parametros
    localparam      RBITS   =   5       ;
    localparam      FBITS   =   2       ;
    
    //Entradas
    reg     [RBITS-1:0]     if_id_rs    ;
    reg     [RBITS-1:0]     if_id_rt    ;
    reg     [RBITS-1:0]     id_ex_rd    ;
    reg     [RBITS-1:0]     ex_mem_rd   ;
    reg     [RBITS-1:0]     mem_wb_rd   ;
    reg     id_ex_rw    ,   ex_mem_rw   ,
                            mem_wb_rw   ;
    //Salidas
    wire    [FBITS-1:0]     fwd_a       ;
    wire    [FBITS-1:0]     fwd_b       ;
    
    initial begin
    $dumpfile("dump.vcd"); $dumpvars;
        if_id_rs        =   2       ;
        if_id_rt        =   2       ;
        id_ex_rd        =   2       ;
        ex_mem_rd       =   2       ;
        mem_wb_rd       =   2       ;
        id_ex_rw        =   0       ;
        ex_mem_rw       =   0       ;
        mem_wb_rw       =   0       ;
        #10
        id_ex_rw        =   1       ;
        #10
        id_ex_rw        =   0       ;
        ex_mem_rw       =   1       ;
        #10
        ex_mem_rw       =   0       ;
        mem_wb_rw       =   1       ;
        #10
        mem_wb_rw       =   0       ;
        if_id_rt        =   3       ;
        ex_mem_rd       =   3       ;
        id_ex_rw        =   1       ;
        ex_mem_rw       =   1       ;
        #10
        if_id_rt        =   1       ;
        #10
        $finish;
    end
    
    forwarding_unit
    #(
        .RBITS              (RBITS)     ,
        .FBITS              (FBITS)
    )fwufwu
    (
        .IF_ID_rs           (if_id_rs)  ,
        .IF_ID_rt           (if_id_rt)  ,
        .ID_EX_rd           (id_ex_rd)  ,
        .EX_MEM_rd          (ex_mem_rd) ,
        .MEM_WB_rd          (mem_wb_rd) ,
        .ID_EX_regwrite     (id_ex_rw)  ,
        .EX_MEM_regwrite    (ex_mem_rw) ,
        .MEM_WB_regwrite    (mem_wb_rw) ,
        .forward_A          (fwd_a)     ,
        .forward_B          (fwd_b)
    );
    
endmodule
