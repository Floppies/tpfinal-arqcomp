//Definicion de Macros para manipular mejor las operaciones
`define ADD     4'b0000     //Salida-> A + B
`define SUB     4'b0001     //Salida-> A - B
`define AND     4'b0010     //Salida-> A and B
`define OR      4'b0011     //Salida-> A or B
`define XOR     4'b0100     //Salida-> A xor B
`define NOR     4'b0101     //Salida-> A nor B
`define	SLT     4'b0110     //Salida-> (A < B)
`define	SLTU    4'b0111     //Salida-> (A < B) zero extends
`define SLL     4'b1000     //Salida-> A << B
`define SRL     4'b1001     //Salida-> A >> B
`define SRA     4'b1010     //Salida-> A >> B msb extends
`define	LUI     4'b1011     //Salida-> B << 12

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
	   result_op   =   {NBITS{1'b0}} ;
	   case(ALU_control)
	        `ADD     :   result_op   =   operando_A + operando_B     ;
			`SUB     :   result_op   =   operando_A - operando_B     ;
			`AND     :   result_op   =   operando_A & operando_B     ;
			`OR      :   result_op   =   operando_A | operando_B     ;
			`XOR     :   result_op   =   operando_A ^ operando_B     ;
			`NOR     :   result_op   =   ~(operando_A | operando_B)  ;
			`SLT     :   result_op   =   (operando_A < operando_B) ? 1 : 0 ;
			`SLTU    :   result_op   =   ($unsigned(operando_A) < $unsigned(operando_B)) ? 1 : 0 ;
			`SLL     :   result_op   =   operando_A << operando_B[4:0]      ;
			`SRL     :   result_op   =   $unsigned(operando_A) >> operando_B[4:0] ;
			`SRA     :   result_op   =   operando_A >>> operando_B[4:0]     ;
			`LUI     :   result_op   =   operando_B << 12            ;
			default  :   result_op   =   {NBITS{1'b1}}              ;   //FF es el resultado default
		endcase
	   zero    =   (result_op == 0);
	end
    
endmodule

