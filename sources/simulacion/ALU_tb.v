`timescale 1ns / 1ps
module ALU_tb();

    //Local parameters
    localparam              nbits = 32	;

    //inputs
    reg     [3:0]           control     ;
  	reg		[nbits-1:0]     in_A        ;
  	reg		[nbits-1:0]     in_B        ;
  	//outputs
  	wire 	[nbits-1:0] 	result      ;
  	wire                    zero        ;
    
    initial begin
    $dumpfile("dump.vcd"); $dumpvars;
        #10
        in_A        =       32'h1       ;
        in_B        =       32'h2       ;
        control     =       4'h0        ;
        #10
        control     =       4'h1        ;
        #10
        control     =       4'hF        ;
        #10
        control     =       4'h3        ;
        #10
        control     =       4'h4        ;
        #10
        control     =       4'h5        ;
        #10
        control     =       4'h6        ;
        #10
        control     =       4'h7        ;
        #10
        control     =       4'h8        ;
        #10
        control     =       4'h9        ;
        #10
        control     =       4'hA        ;
        #10
        control     =       4'hB        ;
        #10
        control     =       4'hC        ;
        #10
        control     =       4'hE        ;
        #10
        control     =       4'hF        ;
        $finish;
    end
    
    ALU
    #(
        .NBITS              (nbits)
    )
    alu
    (
        .ALU_control        (control)   ,
        .operando_A         (in_A)      ,
        .operando_B         (in_B)      ,
        .result_op          (result)    ,
        .zero               (zero)
    );

endmodule