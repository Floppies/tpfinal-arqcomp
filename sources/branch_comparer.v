module branch_comparer  #(
    parameter       RBITS   =   32
    )
    (
    //Entradas
    input   wire    [RBITS-1:0] i_rs    ,
    input   wire    [RBITS-1:0] i_rt    ,
    //Salidas
    output  wire                zero
    );
    
    assign zero =   (i_rs == i_rt) ? 1 : 0  ;
    
endmodule