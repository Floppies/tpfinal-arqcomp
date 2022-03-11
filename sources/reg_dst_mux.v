module reg_dst_mux  #(
    parameter       NBITS       =   5           ,
    parameter       SELBITS     =   2
    )
    (
    //Entradas
    input   wire    [NBITS-1:0]     reg_rt      ,
    input   wire    [NBITS-1:0]     reg_rd      ,
    input   wire    [NBITS-1:0]     reg_31      ,
    input   wire    [SELBITS-1:0]   sel_reg     ,
    //Outputs
    output  wire    [NBITS-1:0]     mux_reg
    );
    
    localparam  [SELBITS-1:0]
        RT          =   2'b00   ,
        R31         =   2'b01   ,
        RD          =   2'b10   ;
    reg     [NBITS-1:0] reg_tmp     ;
    
    always  @(*)
    begin
        case(sel_reg)
            RT          :   reg_tmp     =   reg_rt      ;
            R31         :   reg_tmp     =   2'd31       ;
            RD          :   reg_tmp     =   reg_rd      ;
            default     :   reg_tmp     =   5'b00000    ;
        endcase
    end
    
    assign  mux_reg     =   reg_tmp     ;
    
endmodule