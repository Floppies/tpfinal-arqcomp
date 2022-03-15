`timescale 1ns / 1ps

module two_sel_mux_tb();

    //Parametros
    localparam      NBITS   =   32  ;
    localparam      SELBITS =   2   ;
    
    //inputs
    reg     [NBITS-1:0]     i_one   ;
    reg     [NBITS-1:0]     i_two   ;
    reg     [NBITS-1:0]     i_three ;
    reg     [NBITS-1:0]     i_four  ;
    reg     [SELBITS-1:0]   select  ;
    //output
    wire    [NBITS-1:0]     o_mux   ;
    
    initial begin
    $dumpfile("dump.vcd"); $dumpvars;
        i_one       =   1       ;
        i_two       =   2       ;
        i_three     =   3       ;
        i_four      =   4       ;
        select      =   2'b00   ;
        #10
        select      =   2'b01   ;
        #10
        select      =   2'b10   ;
        #10
        select      =   2'b11   ;
        #10
        $finish;
    end
    
    forw_mux    #
    (
        .NBITS          (NBITS)     ,
        .SELBITS        (SELBITS)
    ) forwa
    (
        .regbnk_data    (i_one)     ,
        .alustg_data    (i_two)     ,
        .memstg_data    (i_three)   ,
        .wbstg_data     (i_four)    ,
        .sel_addr       (select)    ,
        .mux_forw       (o_mux)
    );

endmodule