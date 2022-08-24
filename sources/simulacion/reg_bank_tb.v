`timescale 10ns / 10ns

module reg_bank_tb();

    //Parametro
    localparam      BANK_SIZE       =   32  ;
    localparam      WORD_WIDTH      =   32  ;
    localparam      ADDR_LENGTH     =   5   ;
    localparam      DATA_LENGTH     =   32  ;
    
    //Entradas
    reg     i_clk   ,   i_rst   ,   enable  ;
    reg     [ADDR_LENGTH-1:0]       i_reg1  ;
    reg     [ADDR_LENGTH-1:0]       i_reg2  ;
    reg     [ADDR_LENGTH-1:0]       i_regW  ;
    reg     [DATA_LENGTH-1:0]       i_Data  ;
    
    //Salidas
    wire    [DATA_LENGTH-1:0]       o_rg1D  ;
    wire    [DATA_LENGTH-1:0]       o_rg2D  ;
    
    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        i_clk       =   1   ;
        i_rst       =   1   ;
        enable      =   0   ;
        i_reg1      =   0   ;
        i_reg2      =   1   ;
        #5
        i_regW      =   0   ;
        i_Data      =   5   ;
        #5
        i_rst       =   0   ;
        enable      =   1   ;
        #5
        i_regW      =   1   ;
        #10
        i_regW      =   2   ;
        #10
        i_regW      =   3   ;
        #10
        i_regW      =   4   ;
        i_Data      =   8   ;
        #10
        i_regW      =   5   ;
        #10
        i_regW      =   6   ;
        enable      =   0   ;
        #10
        i_regW      =   7   ;
        #10
        i_reg1      =   3   ;
        i_reg2      =   4   ;
        #10
        i_reg1      =   7   ;
        i_reg2      =   2   ;
        #30
        $finish;
    end
    
    always begin
        #5
        i_clk       =       ~i_clk  ;
    end
    
    register_bank
    #(
        .BANK_SIZE      (BANK_SIZE)     ,
        .WORD_WIDTH     (WORD_WIDTH)    ,
        .ADDR_LENGTH    (ADDR_LENGTH)   ,
        .DATA_LENGTH    (DATA_LENGTH)
    )regbank
    (
        .i_clk          (i_clk)         ,
        .i_rst          (i_rst)         ,
        .enable         (enable)        ,
        .i_reg1         (i_reg1)        ,
        .i_reg2         (i_reg2)        ,
        .i_regW         (i_regW)        ,
        .i_Data         (i_Data)        ,
        .o_rg1D         (o_rg1D)        ,
        .o_rg2D         (o_rg2D)
    );
    
endmodule
