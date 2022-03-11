//Definicion de Macros para manipular mejor los tipos de operaciones
`define ALURtp  3'b000      //Operaciones Tipo R
`define ALUAdd  3'b001      
`define ALUAnd  3'b010      
`define ALUOr   3'b011      
`define ALUXor  3'b100      
`define ALUSlt  3'b101      
`define ALUSub  3'b110      
`define ALULui  3'b111

//Definicion de Macros para las instrucciones
`define Add     6'b100000
`define Addu    6'b100001
`define And     6'b100100
`define Jarl    6'b001001
`define Jr      6'b001000
`define Nor     6'b100111
`define Or      6'b100101
`define Sll     6'b000000
`define Sllv    6'b000100
`define Slt     6'b101010
`define Sra     6'b000011
`define Srav    6'b000111
`define Srl     6'b000010
`define Srlv    6'b000110
`define Sub     6'b100010
`define Subu    6'b100011
`define Xor     6'b100110

module ALU_Control #(
    //Parametros
    parameter                       FBITS   =   6   ,
    parameter                       OPBITS  =   3   ,
    parameter                       CTRBITS =   4
    )
    (
    //Entradas
    input   wire    [FBITS-1:0]     ALU_op          ,
    input   wire    [OPBITS-1:0]    i_funct         ,
    //Salidas
    output  reg     [CTRBITS-1:0]   ALU_control
    );
    
    localparam  [CTRBITS-1:0]
        ADD     =   4'b0000     ,
        AND     =   4'b0001     ,
        NOR     =   4'b0010     ,
        OR      =   4'b0011     ,
        SLL     =   4'b0100     ,
        SRL     =   4'b0101     ,
        SRA     =   4'b0110     ,
        SUB     =   4'b0111     ,
        XOR     =   4'b1000     ,
        SRAV    =   4'b1001     ,
        SRLV    =   4'b1010     ,
        SLLV    =   4'b1011     ,
        SLT     =   4'b1100     ,
        LUI     =   4'b1101     ;

    always @(*)
	begin :    control
		case(ALU_op)
		  `ALURtp     :
		      begin   :   RType
		          case(i_funct)
		              `Add    :   ALU_control =   ADD ;
		              `Addu   :   ALU_control =   ADD ;
		              `And    :   ALU_control =   AND ;
		              `Jarl   :   ALU_control =   ADD ;
		              `Jr     :   ALU_control =   ADD ;
		              `Nor    :   ALU_control =   NOR ;
		              `Or     :   ALU_control =   OR  ;
		              `Sll    :   ALU_control =   SLL ;
		              `Sllv   :   ALU_control =   SLLV;
		              `Slt    :   ALU_control =   SLT ;
		              `Sra    :   ALU_control =   SRA ;
		              `Srav   :   ALU_control =   SRAV;
		              `Srl    :   ALU_control =   SRL ;
		              `Srlv   :   ALU_control =   SRLV;
		              `Sub    :   ALU_control =   SUB ;
		              `Subu   :   ALU_control =   SUB ;
		              `Xor    :   ALU_control =   XOR ;
		              default :   ALU_control =   ADD ;
		          endcase
		      end
          `ALUAdd       :   ALU_control =   ADD     ;
          `ALUAnd       :   ALU_control =   AND     ;
          `ALUOr        :   ALU_control =   OR      ;
          `ALUXor       :   ALU_control =   XOR     ;
          `ALUSlt       :   ALU_control =   SLT     ;
          `ALUSub       :   ALU_control =   SUB     ;
          `ALULui       :   ALU_control =   LUI     ;
          default       :   ALU_control =   ADD     ;
        endcase
    end

endmodule