module link_mux     #(
    parameter       NBITS       =   32
    )
    (
    //Entradas
    input   wire    [NBITS-1:0]     i_linkinst  ,
    input   wire    [NBITS-1:0]     i_immediate ,
    input   wire                    link_flag   ,
    //Outputs
    output  wire    [NBITS-1:0]     o_imm
    );
    
    assign  o_imm       =   (link_flag) ? i_linkinst : i_immediate  ;
    
endmodule
