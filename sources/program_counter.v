`timescale 1ns / 1ps

module program_counter#(
    parameter       MSB     =   32
)
(
    input   wire    i_clk   ,   i_rst   ,
    input   wire    [MSB-1:0]   next_pc ,   //  Entrada de la nueva instruccion
    input   wire                write_pc,   //  Entrada que actualiza el registro en este ciclo
    output  reg     [MSB-1:0]   o_pc        //  Salida
);

always  @(posedge i_clk)
    begin
        if  (i_rst)
        begin
            o_pc        <=      32'b0   ;
        end
        else if (write_pc)
            o_pc        <=      next_pc ;
    end

endmodule