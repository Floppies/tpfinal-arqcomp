`timescale 1ns / 1ps

module ALU_control_tb();

    //Local parameters
    localparam      FBITS       =   4   ;
    localparam      OPBITS      =   2   ;
    localparam      CTRBITS     =   4   ;

    //Inputs
    reg     [OPBITS-1:0]    alu_op      ;
    reg     [FBITS-1:0]     i_funct     ;   // {funct7, funct3}
    //Output
    wire    [CTRBITS-1:0]   alu_ctr     ;

    initial begin
        $dumpfile("dump.vcd"); $dumpvars;

        // ALUOp = 00 -> ADD
        alu_op  =   2'b00;
        i_funct =   4'b0;
        #10;

        // ALUOp = 01 -> SUB
        alu_op  =   2'b01;
        i_funct =   4'b0;
        #10;

        // ALUOp = 11 -> LUI
        alu_op  =   2'b11;
        i_funct =   4'b0;
        #10;

        // ALUOp = 10 -> funct3/funct7 (R/I-type)
        alu_op  =   2'b10;

        // ADD / ADDI (funct7=0000000, funct3=000)
        i_funct =   {1'b0, 3'b000};
        #10;
        // SUB (funct7=0100000, funct3=000)
        i_funct =   {1'b1, 3'b000};
        #10;
        // SLL / SLLI
        i_funct =   {1'b0, 3'b001};
        #10;
        // SLT / SLTI
        i_funct =   {1'b0, 3'b010};
        #10;
        // SLTU / SLTIU
        i_funct =   {1'b0, 3'b011};
        #10;
        // XOR / XORI
        i_funct =   {1'b0, 3'b100};
        #10;
        // SRL / SRLI
        i_funct =   {1'b0, 3'b101};
        #10;
        // SRA / SRAI
        i_funct =   {1'b1, 3'b101};
        #10;
        // OR / ORI
        i_funct =   {1'b0, 3'b110};
        #10;
        // AND / ANDI
        i_funct =   {1'b0, 3'b111};
        #10;

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
