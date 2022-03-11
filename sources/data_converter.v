module data_converter   #(
    parameter       NBITS       =   32  ,
    parameter       SIZE        =   2   
    )
    (
    //Entradas
    input   wire    [NBITS-1:0] i_data  ,
    input   wire    [SIZE-1:0]  size    ,
    input   wire                sign    ,
    //Salida
    output  wire    [NBITS-1:0] o_data
    );
    
    localparam  [SIZE-1:0]
        BYTE        =   2'b01   ,
        HALFWORD    =   2'b10   ,
        WORD        =   2'b11   ;
    
    reg     [NBITS-1:0] data_tmp    ;
    reg     [7:0]       byte_tmp    ;
    reg     [15:0]      half_tmp    ;
    
    
    always @(*)
	begin
	   case(size)
	       BYTE        :
	       begin
	           byte_tmp    =   i_data  ;
	           if(sign)
	               data_tmp    =   (i_data[NBITS-1] == 1) ?  {24'h000000, byte_tmp} : {24'hFFFFFF, byte_tmp}   ;
	           else
	               data_tmp    =   {24'h000000, byte_tmp}  ;
	       end
	       HALFWORD    :
	       begin
	           half_tmp    =   i_data  ;
	           if(sign)
	               data_tmp    =   (i_data[NBITS-1] == 1) ?  {16'h0000, byte_tmp} : {16'hFFFF, byte_tmp}   ;
	           else
	               data_tmp    =   {16'h0000, byte_tmp}  ;
	       end
	       WORD        :   data_tmp    =   i_data      ;
	       default     :   data_tmp    =   32'hFFFFFFFF;
	   endcase
	end
	
	assign o_data  =   data_tmp    ;
	               
endmodule
