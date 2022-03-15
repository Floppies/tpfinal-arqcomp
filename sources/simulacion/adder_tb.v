`timescale 1ns / 1ps

module adder_tb();
    //Local parameters
    localparam      NBITS       =   32  ;
    
    //Inputs
    reg     [NBITS-1:0]     factor_one  ;
    reg     [NBITS-1:0]     factor_two  ;
    //Output
    wire    [NBITS-1:0]     result      ;
    
    initial begin
    $dumpfile("dump.vcd"); $dumpvars;
        #10
        factor_one      =   1       ;
        factor_two      =   2       ;
        #10
        $finish;
    end
    
    branch_adder
    #(
        .MSB            (NBITS)
    )badder
    (
        .next_pc        (factor_one)    ,
        .offset         (factor_two)    ,
        .branch_addr    (result)
    );
    
endmodule
