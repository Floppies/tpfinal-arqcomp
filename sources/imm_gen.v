`define OPIMM   7'b0010011
`define LOAD    7'b0000011
`define JARL    7'b1100111
`define STORE   7'b0100011
`define BRANCH  7'b1100011
`define LUI     7'b0110111
`define JAL     7'b1101111


module imm_gen #(
    parameter NBITS = 32
)(
    input  wire [NBITS-1:0] instr,
    output reg  [NBITS-1:0] imm
);

    wire [6:0] opcode = instr[6:0];

    always @(*) begin
        case (opcode)
            `OPIMM  , // OP-IMM (addi, andi, ori, xori, slti, sltiu)
            `LOAD   ,
            `JARL   :
                imm = {{20{instr[31]}}, instr[31:20]}   ;   // I-type

            `STORE  :
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]}  ;   // S-type

            `BRANCH :
                imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}   ;   // B-type

            `LUI    :
                imm = {instr[31:12], 12'b0} ;   // U-type

            `JAL    :
                imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0} ;   // J-type

            default:
                imm = 32'b0;
        endcase
    end

endmodule
