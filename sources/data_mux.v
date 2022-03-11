module data_mux #(
    parameter       NBITS       =   32          ,
    parameter       SELBITS     =   2
    )
    (
    //Entradas
    input   wire    [NBITS-1:0]     i_data      ,
    input   wire    [NBITS-1:0]     i_aluresult ,
    input   wire    [NBITS-1:0]     i_link      ,
    input   wire    [SELBITS-1:0]   sel_regdata ,
    //Outputs
    output  wire    [NBITS-1:0]     reg_data
    );
    
    localparam  [SELBITS-1:0]
        ALU         =   2'b00   ,
        DATAMEM     =   2'b01   ,
        LINK        =   2'b10   ;
    reg     [NBITS-1:0] data_tmp    ;
    
    always  @(*)
    begin
        case(sel_regdata)
            ALU         :   data_tmp    =   i_aluresult ;
            DATAMEM     :   data_tmp    =   i_data      ;
            LINK        :   data_tmp    =   i_link      ;
            default     :   data_tmp    =   32'hFFFFFFFF;
        endcase
    end
    
    assign  mux_data    =   data_tmp    ;
    
endmodule