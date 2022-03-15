`timescale 1ns / 1ps

module ALU_control_tb();

    //Local parameters
    localparam      FBITS       =   6   ;
    localparam      OPBITS      =   3   ;
    localparam      CTRBITS     =   4   ;
    
    //Inputs
    reg     [FBITS-1:0]     alu_op      ;
    reg     [OPBITS-1:0]    i_funct     ;
    //Output
    wire    [CTRBITS-1:0]   alu_ctr     ;
    
    initial begin
    $dumpfile("dump.vcd"); $dumpvars;
        #10
        alu_op      =   3'b000      ;
        i_funct     =   6'b100000   ;
        #10
        i_funct     =   6'b100100   ;
        #10
        i_funct     =   6'b100001   ;
        #10
        i_funct     =   6'b001001   ;
        #10
        i_funct     =   6'b001000   ;
        #10
        i_funct     =   6'b100111   ;
        #10
        i_funct     =   6'b100101   ;
        #10
        i_funct     =   6'b000000   ;
        #10
        i_funct     =   6'b000100   ;
        #10
        i_funct     =   6'b101010   ;
        #10
        i_funct     =   6'b000011   ;
        #10
        i_funct     =   6'b000111   ;
        #10
        i_funct     =   6'b000010   ;
        #10
        i_funct     =   6'b000110   ;
        #10
        i_funct     =   6'b100010   ;
        #10
        i_funct     =   6'b100011   ;
        #10
        i_funct     =   6'b100110   ;
        #10
        alu_op      =   3'b001      ;
        #10
        alu_op      =   3'b010      ;
        #10
        alu_op      =   3'b110      ;
        #10
        alu_op      =   3'b111      ;
        #10
        alu_op      =   3'b011      ;
        #10
        alu_op      =   3'b101      ;
        #10
        alu_op      =   3'b100      ;
        $finish;
    end
    
    ALU_Control
    #(
        .FBITS          (FBITS)     ,
        .OPBITS         (OPBITS)    ,
        .CTRBITS        (CTRBITS)
    )alucontrol
    (
        .ALU_op         (alu_op)    ,
        .i_funct        (i_funct)   ,
        .ALU_control    (alu_ctr)
    );
    
endmodule