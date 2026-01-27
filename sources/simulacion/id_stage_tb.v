`timescale 1ns / 1ps

module id_stage_tb();

    //Local parameters
    localparam  NBITS       =   32  ;
    localparam  RBITS       =   5   ;
    localparam  FBITS       =   4   ;
    localparam  OPBITS      =   8   ;
    localparam  BANK_SIZE   =   32  ;

    //Inputs
    reg     [NBITS-1:0]     i_ID_current_pc ;
    reg     [NBITS-1:0]     i_ID_instruction;
    reg     [NBITS-1:0]     i_reg_data      ;
    reg     [RBITS-1:0]     i_reg_address   ;
    reg                     i_regwrite      ;
    reg                     i_clk           ;
    reg                     i_rst           ;

    //Outputs
    wire    [NBITS-1:0]     o_jump_address  ;
    wire    [NBITS-1:0]     o_Data1         ;
    wire    [NBITS-1:0]     o_Data2         ;
    wire    [NBITS-1:0]     o_immediate     ;
    wire    [RBITS-1:0]     o_ID_rs1        ;
    wire    [RBITS-1:0]     o_ID_rs2        ;
    wire    [OPBITS-1:0]    o_opcode        ;
    wire    [FBITS-1:0]     o_funct         ;
    wire    [RBITS-1:0]     o_ID_rd         ;

    initial begin
        $dumpfile("id_stage_tb.vcd"); $dumpvars;
        i_clk               =   1'b0        ;
        i_rst               =   1'b1        ;
        i_regwrite          =   1'b0        ;
        i_reg_address       =   5'd0        ;
        i_reg_data          =   32'h0       ;
        i_ID_current_pc     =   32'h00000100;
        i_ID_instruction    =   32'h00000013;   // NOP (addi x0,x0,0)

        // Release reset after one negedge
        #10
        i_rst = 1'b0;

        // Write x5 = 0xAAAA and x2 = 0x5555
        i_regwrite          =   1'b1        ;
        i_reg_address       =   5'd5        ;
        i_reg_data          =   32'h0000AAAA;
        #10
        i_reg_address       =   5'd2        ;
        i_reg_data          =   32'h00005555;
        #10
        i_regwrite          =   1'b0        ;

        // R-type SUB: funct7=0100000, rs2=x2, rs1=x5, funct3=000, rd=x3, opcode=0110011
        i_ID_instruction    =   32'b0100000_00010_00101_000_00011_0110011   ;
        #10

        // BNE with imm = +8: funct3=001, opcode=1100011
        // imm[12|10:5|4:1|11] = 0|000000|0100|0
        i_ID_instruction    =   32'b0_000000_00010_00101_001_0100_0_1100011 ;
        #10

        // Change PC to verify jump address changes
        i_ID_current_pc     =   32'h0000_0200;
        #10;

        $finish;
    end

    always begin
        #5
        i_clk   =   ~i_clk  ;
    end

    ID_stage #(
        .NBITS              (NBITS)     ,
        .RBITS              (RBITS)     ,
        .FBITS              (FBITS)     ,
        .OPBITS             (OPBITS)    ,
        .BANK_SIZE          (BANK_SIZE)
    ) dut (
        .i_ID_current_pc    (i_ID_current_pc)   ,
        .i_ID_instruction   (i_ID_instruction)  ,
        .i_reg_data         (i_reg_data)        ,
        .i_reg_address      (i_reg_address)     ,
        .i_regwrite         (i_regwrite)        ,
        .i_clk              (i_clk)             ,
        .i_rst              (i_rst)             ,
        .o_jump_address     (o_jump_address)    ,
        .o_Data1            (o_Data1)           ,
        .o_Data2            (o_Data2)           ,
        .o_immediate        (o_immediate)       ,
        .o_ID_rs1           (o_ID_rs1)          ,
        .o_ID_rs2           (o_ID_rs2)          ,
        .o_opcode           (o_opcode)          ,
        .o_funct            (o_funct)           ,
        .o_ID_rd            (o_ID_rd)
    );

endmodule
