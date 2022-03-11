module sign_extend  #(
    //Parametros
    parameter       NBITS       =       16      ,
    parameter       EXTBITS     =       32
    )
    (
    //Entradas
    input   wire    [NBITS-1:0]     i_sign      ,
    //Salidas
    output  wire    [EXTBITS-1:0]   o_ext
    );
    
    assign o_ext    =   (i_sign[NBITS-1] == 1)? {16'hffff , i_sign} : 
                        (i_sign[NBITS-1] == 0)? {16'h0000 ,i_sign}  : 16'hxxxx  ;
                        
endmodule

