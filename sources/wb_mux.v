module wb_mux   #(
    parameter       NBITS       =   32
    )
    (
    //Entradas
    input   wire    [NBITS-1:0]     i_aluresult ,   //ALU result
    input   wire    [NBITS-1:0]     i_wbstgdata ,   //Mem data
    input   wire    [NBITS-1:0]     i_nextinst  ,   //PC+4
    input   wire    [1:0]           i_sel       ,   //Link, MemToReg
    //Outputs
    output  wire    [NBITS-1:0]     o_regdata       //Data to write into RegBank
    );
    
    localparam  [1:0]
        ALU     =   2'b00   ,
        MEMDATA =   2'b01   ,
        LINK    =   2'b10   ;
    
    reg [NBITS-1:0] data_tmp;

    always  @(*)
    begin
        case(i_sel)
            ALU     :   data_tmp    =   i_aluresult ;
            MEMDATA :   data_tmp    =   i_wbstgdata ;
            LINK    :   data_tmp    =   i_nextinst  ;
            default :   data_tmp    =   32'hFFFFFFFF;
        endcase
    end

    assign  o_regdata   =   data_tmp    ;
    
endmodule
