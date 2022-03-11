module branch_mux   #(
    parameter       NBITS       =   32
    )
    (
    //Entradas
    input   wire    [NBITS-1:0]     next_inst   ,
    input   wire    [NBITS-1:0]     jump_addr   ,
    input   wire                    branch      ,
    //Outputs
    output  wire    [NBITS-1:0]     next_pc
    );
    
    assign  next_pc     =   (branch) ? next_inst : jump_addr    ;
    
endmodule
