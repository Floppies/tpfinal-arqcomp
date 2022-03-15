module alu_source_mux   #(
    parameter       NBITS       =   32
    )
    (
    //Entradas
    input   wire    [NBITS-1:0]     i_reg       ,
    input   wire    [NBITS-1:0]     i_immediate ,
    input   wire                    alu_source  ,
    //Outputs
    output  wire    [NBITS-1:0]     o_aluinB
    );
    
    assign  o_aluinB    =   (alu_source) ? i_immediate : i_reg  ;
    
endmodule