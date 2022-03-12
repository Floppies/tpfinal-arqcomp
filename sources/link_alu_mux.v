module link_alu_mux     #(
    parameter       NBITS       =   5
    )
    (
    //Entradas
    input   wire    [NBITS-1:0]     i_rs        ,
    input   wire                    link_flag   ,
    //Outputs
    output  wire    [NBITS-1:0]     o_aluinA
    );
    
    assign  o_aluinA    =   (link_flag) ? i_rs : 0  ;
    
endmodule
