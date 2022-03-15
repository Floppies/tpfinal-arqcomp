module mem_stage_mux    #(
    parameter       NBITS       =   32
    )
    (
    //Entradas
    input   wire    [NBITS-1:0]     i_aluresult ,
    input   wire    [NBITS-1:0]     i_memdata   ,
    input   wire                    memread     ,
    //Outputs
    output  wire    [NBITS-1:0]     o_memstgdata
    );
    
    assign  o_memstgdata    =   (memread) ? i_memdata : i_aluresult;
    
endmodule
