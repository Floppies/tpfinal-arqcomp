module wb_mux   #(
    parameter       NBITS       =   32
    )
    (
    //Entradas
    input   wire    [NBITS-1:0]     i_aluresult ,
    input   wire    [NBITS-1:0]     i_wbstgdata ,
    input   wire                    memtoreg    ,
    //Outputs
    output  wire    [NBITS-1:0]     o_regdata
    );
    
    assign  o_regdata   =   (memtoreg) ? i_wbstgdata : i_aluresult  ;
    
endmodule
