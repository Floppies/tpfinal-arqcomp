//Definicion de Macros para manipular mejor los tipos de operaciones (RISC-V)
`define ALU_ADD     2'b00
`define ALU_SUB     2'b01
`define ALU_FUNCT   2'b10
`define ALU_LUI     2'b11

// RISC-V funct3
`define F3_ADD_SUB  3'b000
`define F3_SLL      3'b001
`define F3_SLT      3'b010
`define F3_SLTU     3'b011
`define F3_XOR      3'b100
`define F3_SRL_SRA  3'b101
`define F3_OR       3'b110
`define F3_AND      3'b111

// RISC-V funct7
`define F7_ADD      1'b0
`define F7_SUB      1'b1

module ALU_Control #(
    //Parametros
    parameter                       FBITS   =   4   ,
    parameter                       OPBITS  =   2   ,
    parameter                       CTRBITS =   4
    )
    (
    //Entradas
    input   wire    [OPBITS-1:0]    ALU_op          ,
    input   wire    [FBITS-1:0]     i_funct         ,   // {funct7, funct3}
    //Salidas
    output  reg     [CTRBITS-1:0]   ALU_control
    );
    
    localparam  [CTRBITS-1:0]
        ADD     =   4'b0000     ,
        SUB     =   4'b0001     ,
        AND     =   4'b0010     ,
        OR      =   4'b0011     ,
        XOR     =   4'b0100     ,
        NOR     =   4'b0101     ,
        SLT     =   4'b0110     ,
        SLTU    =   4'b0111     ,
        SLL     =   4'b1000     ,
        SRL     =   4'b1001     ,
        SRA     =   4'b1010     ,
        LUI     =   4'b1011     ;

    wire            funct7 = i_funct[3];
    wire    [2:0]   funct3 = i_funct[2:0];

    always @(*)
	begin :    control
        ALU_control = ADD;
		case(ALU_op)
          `ALU_ADD  :   ALU_control = ADD; // Loads/Stores/AUIPC/JALR
          `ALU_SUB  :   ALU_control = SUB; // Branch compare
          `ALU_FUNCT:
              begin
                  case(funct3)
                      `F3_ADD_SUB : ALU_control = (funct7 == `F7_SUB) ? SUB : ADD;
                      `F3_SLL     : ALU_control = SLL;
                      `F3_SLT     : ALU_control = SLT;
                      `F3_SLTU    : ALU_control = SLTU;
                      `F3_XOR     : ALU_control = XOR;
                      `F3_SRL_SRA : ALU_control = (funct7 == `F7_SUB) ? SRA : SRL;
                      `F3_OR      : ALU_control = OR;
                      `F3_AND     : ALU_control = AND;
                      default     : ALU_control = ADD;
                  endcase
              end
          `ALU_LUI  :   ALU_control = LUI;
          default   :   ALU_control = ADD;
        endcase
    end

endmodule
