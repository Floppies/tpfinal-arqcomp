module address_mux  #(
    parameter       NBITS       =   32          ,
    parameter       SELBITS     =   2
    )
    (
    //Entradas
    input   wire    [NBITS-1:0]     branch_addr ,
    input   wire    [NBITS-1:0]     jump_addr   ,
    input   wire    [NBITS-1:0]     reg_addr    ,
    input   wire    [SELBITS-1:0]   sel_addr    ,
    //Outputs
    output  wire    [NBITS-1:0]     mux_addr
    );
    
    localparam  [SELBITS-1:0]
        INCONDJ     =   2'b00   ,
        CONDJ       =   2'b01   ,
        REG         =   2'b10   ;
    reg     [NBITS-1:0] addr_tmp    ;
    
    always  @(*)
    begin
        case(sel_addr)
            INCONDJ     :   addr_tmp    =   jump_addr   ;
            CONDJ       :   addr_tmp    =   branch_addr ;
            REG         :   addr_tmp    =   reg_addr    ;
            default     :   addr_tmp    =   32'hFFFFFFFF;
        endcase
    end
            
    assign  mux_addr    =   addr_tmp    ;
    
endmodule