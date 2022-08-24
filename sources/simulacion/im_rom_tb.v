`timescale 10ns / 10ns

module im_rom_tb();

    //Parametros
    localparam      MEM_SIZE    =   9   ;
    localparam      WORD_WIDTH  =   32  ;
    localparam      ADDR_LENGTH =   32  ;
    localparam      DATA_LENGTH =   32  ;
    
    //Entrada
    reg     [ADDR_LENGTH-1:0]   i_Addr  ;
    
    //Salida
    wire    [DATA_LENGTH-1:0]   o_Data  ;
    
    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        i_Addr      =       32'h0       ;
        #10
        i_Addr      =       32'h1       ;
        #10
        i_Addr      =       32'h2       ;
        #10
        i_Addr      =       32'h3       ;
        #10
        i_Addr      =       32'h5       ;
        #10
        i_Addr      =       32'h4       ;
        #10
        $finish;
    end
    
    instruction_memory
    #(
        .MEM_SIZE       (MEM_SIZE)      ,
        .WORD_WIDTH     (WORD_WIDTH)    ,
        .ADDR_LENGTH    (ADDR_LENGTH)   ,
        .DATA_LENGTH    (DATA_LENGTH)
    )imrom
    (
        .i_Addr         (i_Addr)        ,
        .o_Data         (o_Data)
    );
    
endmodule
