`timescale 1ns / 1ps

module comparer_tb();

    //Local parameters
    localparam      RBITS       =   32  ;
    
    //Inputs
    reg     [RBITS-1:0]     factor_one  ;
    reg     [RBITS-1:0]     factor_two  ;
    //Output
    wire                    result      ;
    
    initial begin
    $dumpfile("dump.vcd"); $dumpvars;
        #10
        factor_one      =   1       ;
        factor_two      =   2       ;
        #10
        factor_two      =   1       ;
        #10
        $finish;
    end
    
    branch_comparer
    #(
        .RBITS      (RBITS)
    )brbr
    (
        .i_rs       (factor_one)    ,
        .i_rt       (factor_two)    ,
        .zero       (result)
    );
    
endmodule
