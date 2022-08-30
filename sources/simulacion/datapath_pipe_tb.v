`timescale 10ns / 10ps

module datapath_pipe_tb();

    //Parametros
    localparam      MEM_SIZE        =   5   ;
    localparam      BANK_SIZE       =   32  ;
    localparam      NBITS           =   32  ;
    localparam      RBITS           =   5   ;
    
    //Entradas
    reg             i_clk   ,   i_rst       ;
    
    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        //Stores normales
        i_clk       =       1       ;
        i_rst       =       1       ;
        
        #10
        i_rst       =       0       ;
        
        #80
        $finish;
    end
    
    always begin
        #5
        i_clk       =       ~i_clk  ;
    end
    
    datapath_pipe
    #(
        .MEM_SIZE       (MEM_SIZE)      ,
        .BANK_SIZE      (BANK_SIZE)     ,
        .NBITS          (NBITS)         ,
        .RBITS          (RBITS)
    )DATAPATHPIPE
    (
        .clk            (i_clk)         ,
        .rst            (i_rst)
    );
    
endmodule
