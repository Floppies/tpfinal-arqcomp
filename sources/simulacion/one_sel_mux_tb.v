`timescale 1ns / 1ps

module one_sel_mux_tb();

    //Parametros
    localparam      NBITS   =   32  ;
    
    //inputs
    reg     [NBITS-1:0]     i_one   ;
    reg     [NBITS-1:0]     i_two   ;
    reg                     select  ;
    //output
    wire    [NBITS-1:0]     o_mux   ;
    
    initial begin
    $dumpfile("dump.vcd"); $dumpvars;
        i_one       =   1       ;
        i_two       =   2       ;
        select      =   0       ;
        #10
        select      =   1       ;
        #10
        $finish;
    end
    
    alu_source_mux  #
    (
        .NBITS          (NBITS)
    ) muxmux
    (
        .i_reg          (i_one)     ,
        .i_immediate    (i_two)     ,
        .alu_source     (select)    ,
        .o_aluinB       (o_mux)
    );

endmodule
