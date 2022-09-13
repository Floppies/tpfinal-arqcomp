`timescale 1ns / 1ps

module clock_control    #(
    parameter   NBITS       =       32
)
(
    //Entradas
    input   wire    clock , reset , enable      ,
    output  wire    [NBITS-1:0]     clock_count ,
    output  wire                    o_clock
);
    
    // Señales auxiliares
    reg     [NBITS-1:0]     counter     ;
    
    always  @(posedge clock)
    begin
        if  (reset)
        begin
            counter         <=      32'b0       ;
        end
        else if (enable)
            counter         <=      counter + 1 ;
    end
    
    assign  o_clock         =   (enable)    ?   clock   :   0   ;
    assign  clock_count     =   counter     ;   //NO SE ?
    
endmodule
