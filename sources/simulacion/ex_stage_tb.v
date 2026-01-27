`timescale 1ns / 1ps

module ex_stage_tb();

    localparam NBITS    =   32  ;
    localparam FBITS    =   4   ;
    localparam CTRBITS  =   4   ;
    localparam OPBITS   =   2   ;

    reg  [NBITS-1:0]    i_Data1         ;
    reg  [NBITS-1:0]    i_Data2         ;
    reg  [NBITS-1:0]    i_immediate     ;
    reg  [NBITS-1:0]    i_data_from_mem ;
    reg  [NBITS-1:0]    i_data_from_wb  ;
    reg  [FBITS-1:0]    i_funct         ;   // {funct7[5], funct3}
    reg  [OPBITS-1:0]   i_forwardA      ;
    reg  [OPBITS-1:0]   i_forwardB      ;
    reg  [OPBITS-1:0]   i_ALUOp         ;
    reg                 i_ALUSrc        ;

    wire [NBITS-1:0]    o_EX_result     ;
    wire                o_EX_zero       ;

    initial begin
        $dumpfile("ex_stage_tb.vcd"); $dumpvars;

        i_Data1         =   32'h00000001    ;
        i_Data2         =   32'h00000002    ;
        i_immediate     =   32'h00000004    ;
        i_data_from_mem =   32'h0000000A    ;
        i_data_from_wb  =   32'h00000014    ;
        i_funct         =   4'b0000         ;
        i_forwardA      =   2'b00           ;
        i_forwardB      =   2'b00           ;
        i_ALUOp         =   2'b00           ;
        i_ALUSrc        =   1'b0            ;
        #10

        // Forward from MEM/WB, ADD: 10 + 20 = 30
        i_forwardA      =   2'b01           ;
        i_forwardB      =   2'b10           ;
        i_ALUOp         =   2'b00           ;
        i_ALUSrc        =   1'b0            ;
        #10

        // Use immediate (ALUSrc=1): 1 + 4 = 5
        i_forwardA      =   2'b00           ;
        i_forwardB      =   2'b01           ;
        i_ALUOp         =   2'b00           ;
        i_ALUSrc        =   1'b1            ;
        #10

        // SUB: 1 - 2 = -1
        i_forwardA      =   2'b00           ;
        i_forwardB      =   2'b00           ;
        i_ALUOp         =   2'b01           ;
        i_ALUSrc        =   1'b0            ;
        #10

        // FUNCT AND: 0xF0 & 0x0F = 0
        i_Data1         =   32'h000000F0    ;
        i_Data2         =   32'h0000000F    ;
        i_ALUOp         =   2'b10;
        i_funct         =   {1'b0, 3'b111}  ;   // AND
        #10;

        // FUNCT SRA: 0x80000000 >>> 1 = 0xC0000000
        i_Data1         =   32'h80000000    ;
        i_Data2         =   32'h00000001    ;
        i_funct         =   {1'b1, 3'b101}  ;   // SRA
        #10;

        // LUI: immediate << 12 = 0x00001000
        i_immediate     =   32'h00000001    ;
        i_ALUOp         =   2'b11           ;
        i_ALUSrc        =   1'b1            ;
        #10;

        $finish;
    end

    EX_stage #(
        .NBITS              (NBITS)             ,
        .FBITS              (FBITS)             ,
        .CTRBITS            (CTRBITS)           ,
        .OPBITS             (OPBITS)
    ) dut (
        .i_Data1            (i_Data1)           ,
        .i_Data2            (i_Data2)           ,
        .i_immediate        (i_immediate)       ,
        .i_data_from_mem    (i_data_from_mem)   ,
        .i_data_from_wb     (i_data_from_wb)    ,
        .i_funct            (i_funct)           ,
        .i_forwardA         (i_forwardA)        ,
        .i_forwardB         (i_forwardB)        ,
        .i_ALUOp            (i_ALUOp)           ,
        .i_ALUSrc           (i_ALUSrc)          ,
        .o_EX_result        (o_EX_result)       ,
        .o_EX_zero          (o_EX_zero)
    );

endmodule
