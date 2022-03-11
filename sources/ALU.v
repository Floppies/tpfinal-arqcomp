//Definicion de Macros para manipular mejor las operaciones
`define ADD     4'b0000     //Salida-> A + B
`define AND     4'b0001     //Salida-> A and B
`define NOR     4'b0010     //Salida-> A nor B
`define OR      4'b0011     //Salida-> A or B
`define SLL     4'b0100     //Salida-> A,B[10:6] <<
`define SRL     4'b0101     //Salida-> A,B[10:6] >>
`define SRA     4'b0110     //Salida-> A,B[10:6] >>> 
`define SUB     4'b0111     //Salida-> A - B
`define XOR     4'b1000     //Salida-> A xor B
`define SRAV    4'b1001     //Salida-> A,B >>> 
`define SRLV    4'b1010     //Salida-> A,B >>
`define SLLV    4'b1011     //Salida-> A,B <<
`define	SLT     4'b1100     //Salida-> (A < B)
`define	LUI     4'b1101     //Salida-> B,16 <<

//Modulo combinacional que, de manera continua, produce la salida teniendo en cuenta los operandos
//y la operacion
module ALU #(
    //Parametros
    parameter                           NBITS   =   32
    )
    (
    //Entradas
    input   wire    signed  [NBITS-1:0] operando_A, operando_B  ,
    input   wire            [3:0]       ALU_control             ,
    //Salidas
    output  reg     signed  [NBITS-1:0] result_op               ,
    output  reg                         zero
    );
    
    always @(*)
	begin : operaciones
		case(ALU_control)
			`ADD     :   result_op   =   operando_A + operando_B     ;
			`SUB     :
                begin
                    result_op   =   operando_A - operando_B         ;
                    zero        =   (result_op == 0) ? 0 : 1        ;
                end
			`AND     :   result_op   =   operando_A & operando_B     ;
			`OR      :   result_op   =   operando_A | operando_B     ;
			`XOR     :   result_op   =   operando_A ^ operando_B     ;
			`SRAV    :   result_op   =   operando_A >>> operando_B   ;
			`SRLV    :   result_op   =   operando_A >> operando_B    ;
			`SLLV    :   result_op   =   operando_A << operando_B    ;
			`SRA     :   result_op   =   operando_A >>> operando_B[10:6]     ;
			`SRL     :   result_op   =   operando_A >> operando_B[10:6]      ;
			`SLL     :   result_op   =   operando_A << operando_B[10:6]      ;
			`NOR     :   result_op   =   ~(operando_A | operando_B)  ;
			`SLT     :   result_op   =   (operando_A == operando_B) ? 0 : 1  ;
			`LUI     :   result_op   =   operando_B << 16            ;
			default  :   result_op   =   {NBITS{1'b1}}              ;   //FF es el resultado default
		endcase
	end
    
endmodule
