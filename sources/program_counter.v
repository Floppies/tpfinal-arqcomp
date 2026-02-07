`timescale 1ns / 1ps

module program_counter  #(
    parameter       MSB     =   32
)
(
    input   wire    i_clk   ,   i_rst   ,
    input   wire    [MSB-1:0]   next_pc ,   //  New instruction
    input   wire                cpu_en  ,   //  Enables CPU, comes from debug mode
                                write_pc,   //  Updates in the new cycle, internal to CPU
    output  reg     [MSB-1:0]   o_pc        //  Output
);

always  @(posedge i_clk)
    begin
        if  (i_rst)
        begin
            o_pc        <=      32'b0   ;
        end
        else if (cpu_en &   write_pc)
            o_pc        <=      next_pc ;
    end

endmodule