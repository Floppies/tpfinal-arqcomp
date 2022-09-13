`timescale 10ns / 10ps

module clk_ctrl_tb();

    //Parametros
    localparam      NBITS           =   32  ;
    
    //Entradas
    reg     i_clk   ,   i_rst   ,   enable  ;
    
    //Salidas
    wire    [NBITS-1:0]     clock_count     ;
    wire                    o_clock         ;
    

initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        //Stores normales
        i_clk       =       1       ;
        i_rst       =       1       ;
        enable      =       0       ;
        
        #10
        i_rst       =       0       ;
        
        #10
        enable      =       1       ;
        
        #80
        enable      =       0       ;
        
        #20
        $finish;
    end
    
    always begin
        #5
        i_clk       =       ~i_clk  ;
    end
    
    clock_control   #(
        .NBITS          (NBITS)
    )CLKCTRLTB
    (
        .clock          (i_clk)         ,
        .reset          (i_rst)         ,
        .enable         (enable)        ,
        .clock_count    (clock_count)   ,
        .o_clock        (o_clock)
    );
    
endmodule
