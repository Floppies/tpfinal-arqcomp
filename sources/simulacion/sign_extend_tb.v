`timescale 1ns / 1ps

module sign_extend_tb();

    //Local parameters
    localparam      NBITS       =   16  ;
    localparam      EXTBITS     =   32  ;
    
    //Inputs
    reg     [NBITS-1:0]     signal      ;
    //Output
    wire    [EXTBITS-1:0]   ext_signal  ;
    
    initial begin
    $dumpfile("dump.vcd"); $dumpvars;
        #10
        signal      =   16'hF00F    ;
        #10
        signal      =   16'h000F    ;
        #10
        $finish;
    end
    
    sign_extend
    #(
        .NBITS          (NBITS)         ,
        .EXTBITS        (EXTBITS)
    )extext
    (
        .i_sign         (signal)        ,
        .o_ext          (ext_signal)
    );
endmodule
