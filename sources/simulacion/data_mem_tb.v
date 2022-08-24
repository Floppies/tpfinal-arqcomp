`timescale 10ns / 10ns

module data_mem_tb();
    
    //Parametros
    localparam      MEM_SIZE        =   5   ;
    localparam      WORD_WIDTH      =   32  ;
    localparam      ADDR_LENGTH     =   32  ;
    localparam      DATA_LENGTH     =   32  ;
    
    //Entradas
    reg             i_clk   ,   i_rst       ,
                    We      ,   Re          ;
    reg     [4:0]               size_ctrl   ;   
    reg     [ADDR_LENGTH-1:0]   i_Addr      ;
    reg     [DATA_LENGTH-1:0]   i_Data      ;
    
    //Salida
    wire    [DATA_LENGTH-1:0]   o_Data      ;
    
    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        //Stores normales
        i_clk       =       1       ;
        We          =       1       ;
        i_Addr      =       0       ;   // Carga 1 en la direccion 0
        i_Data      =       1       ;
        size_ctrl   =       0       ;
        Re          =       0       ;
        #10                             // Carga 22 en la direccion 1
        i_Addr      =       1       ;
        i_Data      =       22      ;
        #10                             // Carga 33 en la direccion 2
        i_Addr      =       2       ;
        i_Data      =       33      ;
        #10                             // Carga FF00FF00 en la direccion 3
        i_Addr      =       3       ;   
        i_Data      =       32'hFF00FFFF    ;
        #10                             // Carga 5 en la direccion 4
        i_Addr      =       4       ;
        i_Data      =       5       ;
        //Loads
        #10                             // Lee lo que hay en la direccion 0
        We          =       0       ;
        Re          =       1       ;
        i_Addr      =       0       ;
        i_Data      =       5       ;
        #10                             // Lee lo que hay en la direccion 2
        i_Addr      =       2       ;
        i_Data      =       5       ;
        #10                             // unsigned load byte en la direccion 3
        size_ctrl   =       5'b01000;
        i_Addr      =       3       ;
        #10                             // unsigned load byte en la direccion 1
        size_ctrl   =       5'b01000;
        i_Addr      =       1       ;
        #10                             // signed load byte en la direccion 3
        size_ctrl   =       5'b01100;
        i_Addr      =       3       ;
        #10                     
        size_ctrl   =       5'b01100;   // signed load byte en la direccion 1
        i_Addr      =       1       ;
        #10
        size_ctrl   =       5'b10000;   // unsigned load halfword en la direccion 3
        i_Addr      =       3       ;
        #10
        size_ctrl   =       5'b10100;   // signed  load halfword en la direccion 3
        i_Addr      =       3       ;
        //Stores
        #10                             // store byte en la direccion 1
        We          =       1       ;
        i_Data      =       32'hFFFFFFFF;
        size_ctrl   =       5'b00001;
        i_Addr      =       1       ;
        #10                             // store halfword en la direccion 2
        size_ctrl   =       5'b00010;
        i_Addr      =       2       ;
        #10                             // store word en la direccion 4
        size_ctrl   =       5'b00011;
        i_Addr      =       4       ;
        #20
        $finish;
    end
    
    always begin
        #5
        i_clk       =       ~i_clk  ;
    end
    
    data_memory
    #(
        .MEM_SIZE       (MEM_SIZE)      ,
        .WORD_WIDTH     (WORD_WIDTH)    ,
        .ADDR_LENGTH    (ADDR_LENGTH)   ,
        .DATA_LENGTH    (DATA_LENGTH)
    )dmdmdm
    (
        .i_clk          (i_clk)         ,
        .i_rst          (i_rst)         ,
        .We             (We)            ,
        .Re             (Re)            ,
        .size_control   (size_ctrl)     ,
        .i_Addr         (i_Addr)        ,
        .i_Data         (i_Data)        ,
        .o_Data         (o_Data)
    );

endmodule