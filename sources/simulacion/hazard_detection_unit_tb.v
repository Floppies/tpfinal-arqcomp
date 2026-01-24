`timescale 1ns / 1ps

module hazard_detection_unit_tb();

    //Parametros
    localparam      RBITS   =   5       ;

    //Entradas
    reg     [RBITS-1:0]     if_id_rs1      ;
    reg     [RBITS-1:0]     if_id_rs2      ;
    reg     [RBITS-1:0]     id_ex_rd       ;
    reg                     id_ex_mr       ;
    reg                     id_ex_alusrc   ;
    reg                     id_ex_memwrite ;
    reg                     redirect       ;

    //Salidas
    wire    write_pc    ,   ifid_write  ,
            ifid_flush  ,   idex_flush  ;

    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        if_id_rs1      =   2   ;
        if_id_rs2      =   3   ;
        id_ex_rd       =   0   ;
        id_ex_mr       =   0   ;
        id_ex_alusrc   =   0   ;
        id_ex_memwrite =   0   ;
        redirect       =   0   ;

        // No stall, no redirect
        #10
        id_ex_rd       =   2   ;
        id_ex_mr       =   0   ;

        // Stall on rs1 (load-use)
        #10
        id_ex_mr       =   1   ;

        // No stall: rd doesn't match
        #10
        id_ex_rd       =   4   ;

        // Stall on rs2 when ID uses rs2
        #10
        if_id_rs2      =   4   ;
        id_ex_mr       =   1   ;
        id_ex_alusrc   =   0   ;
        id_ex_memwrite =   0   ;

        // No stall when ID doesn't use rs2 (ALUSrc=1, MemWrite=0)
        #10
        id_ex_mr       =   1   ;
        id_ex_alusrc   =   1   ;
        id_ex_memwrite =   0   ;

        // Redirect flush when not stalling
        #10
        id_ex_mr       =   0   ;
        redirect       =   1   ;

        // Redirect should be masked by stall
        #10
        id_ex_mr       =   1   ;
        id_ex_rd       =   2   ;
        redirect       =   1   ;

        #10
        $finish;
    end

    hazard_detection_unit
    #(
        .RBITS          (RBITS)
    )hdu
    (
        .IF_ID_rs1          (if_id_rs1)     ,
        .IF_ID_rs2          (if_id_rs2)     ,
        .ID_EX_rd           (id_ex_rd)      ,
        .ID_EX_memread      (id_ex_mr)      ,
        .ID_EX_alusrc       (id_ex_alusrc)  ,
        .ID_EX_memwrite     (id_ex_memwrite),
        .redirect           (redirect)      ,
        .write_pc           (write_pc)      ,
        .IFID_write         (ifid_write)    ,
        .IFID_flush         (ifid_flush)    ,
        .IDEX_flush         (idex_flush)
    );

endmodule
