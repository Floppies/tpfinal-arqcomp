`timescale 10ns / 10ps

module pc_tb();
    
    //Parametro
    localparam      MSB     =   32      ;
    
    //Entrada
    reg         i_clk   ,   i_rst       ;
    reg     [MSB-1:0]       next_pc     ;
    reg                     write_pc    ;
    
    //Salida
    wire    [MSB-1:0]       o_pc        ;
    
    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        i_clk       =       1       ;
        i_rst       =       1       ;
        next_pc     =       4       ;
        write_pc    =       0       ;
        #5
        i_rst       =       0       ;
        #10
        write_pc    =       1       ;
        #10
        next_pc     =       2       ;
        #20
        $finish;
    end
    
    always begin
        #5
        i_clk       =       ~i_clk  ;
    end
    
    program_counter
    #(
        .MSB        (MSB)
    )pcpc
    (
        .i_clk      (i_clk)     ,
        .i_rst      (i_rst)     ,
        .next_pc    (next_pc)   ,
        .write_pc   (write_pc)  ,
        .o_pc       (o_pc)
    );
    
endmodule
