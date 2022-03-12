module forw_mux     #(
    parameter       NBITS       =   32          ,
    parameter       SELBITS     =   2
    )
    (
    //Entradas
    input   wire    [NBITS-1:0]     regbnk_data ,
    input   wire    [NBITS-1:0]     alustg_data ,
    input   wire    [NBITS-1:0]     memstg_data ,
    input   wire    [NBITS-1:0]     wbstg_data  ,
    input   wire    [SELBITS-1:0]   sel_addr    ,
    //Outputs
    output  wire    [NBITS-1:0]     mux_forw
    );
    
    localparam  [SELBITS-1:0]
        REGBNK      =   2'b00   ,
        ALUSTG      =   2'b01   ,
        MEMSTG      =   2'b10   ,
        WBSTG       =   2'b11   ;
        
    reg     [NBITS-1:0] forw_tmp    ;
    
    always  @(*)
    begin
        case(sel_addr)
            REGBNK      :   forw_tmp    =   regbnk_data ;
            ALUSTG      :   forw_tmp    =   alustg_data ;
            MEMSTG      :   forw_tmp    =   memstg_data ;
            WBSTG       :   forw_tmp    =   wbstg_data  ;
            default     :   forw_tmp    =   32'hFFFFFFFF;
        endcase
    end
            
    assign  mux_forw    =   forw_tmp    ;
    
endmodule
