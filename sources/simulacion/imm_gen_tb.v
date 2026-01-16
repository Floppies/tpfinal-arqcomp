`timescale 1ns / 1ps

module imm_gen_tb();
    
    //Param
    localparam  MSB =   32      ;
    
    //Input
    reg     [MSB-1:0]   instr   ;
    wire    [MSB-1:0]   imm     ;


    initial begin
        $dumpfile("dump.vcd"); $dumpvars;

        // I-type: addi x1,x0,5  -> imm = 5
        instr = 32'b000000000101_00000_000_00001_0010011;
        #10;

        // S-type: sw x3,0(x0) -> imm = 0
        instr = 32'b0000000_00011_00000_010_00000_0100011;
        #10;

        // B-type: beq x0,x0, +8 -> imm = 8
        // imm[12|10:5|4:1|11] = 0|000000|1000|0
        instr = 32'b0000000_00000_00000_000_1000_0_1100011;
        #10;

        // U-type: lui x1,0x12345 -> imm = 0x12345000
        instr = 32'b00010010001101000101_00001_0110111;
        #10;

        // J-type: jal x0, +16 -> imm = 16
        // imm[20|10:1|11|19:12] = 0|0000001000|0|00000000
        instr = 32'b00000000000100000000_00000_1101111;
        #10;

        $finish;
    end
    
    imm_gen
    #(
        .NBITS  (MSB)
    )IMM_GEN
    (
        .instr  (instr) ,
        .imm    (imm)
    );

endmodule