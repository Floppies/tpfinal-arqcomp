`timescale 1ns / 1ps

module hazard_detection_unit_tb();

    //Parametros
    localparam      RBITS   =   5       ;
    
    //Entradas
    reg     [RBITS-1:0]     if_id_rs    ;
    reg     [RBITS-1:0]     if_id_rt    ;
    reg     [RBITS-1:0]     id_ex_rd    ;
    reg                     id_ex_mr    ;
    
    //Salidas
    wire    write_pc    ,   stall_id    ;
    
    initial begin
    $dumpfile("dump.vcd"); $dumpvars;
        if_id_rs    =   2   ;
        if_id_rt    =   3   ;
        id_ex_rd    =   2   ;
        id_ex_mr    =   0   ;
        #10
        id_ex_mr    =   1   ;
        #10
        id_ex_rd    =   4   ;
        #10
        if_id_rt    =   4   ;
        #10
        $finish;
    end
    
    hazard_detection_unit
    #(
        .RBITS          (RBITS)
    )hdu
    (
        .IF_ID_rs       (if_id_rs)  ,
        .IF_ID_rt       (if_id_rt)  ,
        .ID_EX_rd       (id_ex_rd)  ,
        .ID_EX_memread  (id_ex_mr)  ,
        .write_pc       (write_pc)  ,
        .stall_ID       (stall_id)
    );
endmodule
