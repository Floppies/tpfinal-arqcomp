`timescale 10ns / 10ps

module debug_control_tb();

    //Parametros
    localparam      IM_ADDR_LENGTH  =   32      ;
    localparam      INST_WIDTH      =   32      ;
    localparam      NBITS           =   32      ;
    
    //Entradas
    reg     i_clk       ,       i_rst       ;
    reg     rx_done     ,       halt_flag   ,
                                send_done   ;
    reg     [NBITS-1:0]         rx_Data     ;
    
    //Salidas
    wire    enable      ,           o_reset     ,
            send_flag   ,           IM_We       ;
    wire    [IM_ADDR_LENGTH-1:0]    IM_Addr     ;
    wire    [INST_WIDTH-1:0]        DM_Addr     ;
    
initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        //Stores normales
        i_clk       =       1       ;
        i_rst       =       1       ;
        rx_Data     =       45      ;
        rx_done     =       0       ;
        send_done   =       1       ;
        halt_flag   =       0       ;
        
        #20
        i_rst       =       0       ;
        
        #10
        rx_done     =       1       ;
        
        #5
        rx_done     =       0       ;
        
        #10
        rx_Data     =       32'hFFFFFFFF    ;
        
        #15
        rx_done     =       1       ;
        
        #5
        rx_done     =       0       ;
        #5
        rx_done     =       1       ;
        #55
        halt_flag   =       0       ;


        #60
        $finish;
    end
    
    always begin
        #5
        i_clk       =       ~i_clk  ;
    end
    
    debug_control   #(
        .IM_ADDR_LENGTH         (IM_ADDR_LENGTH)    ,
        .INST_WIDTH             (INST_WIDTH)        ,
        .NBITS                  (NBITS)
    )DEBUGDEBUGCTRL
    (
        .clk                (i_clk)             ,
        .reset              (i_rst)             ,
        .rx_Data            (rx_Data)           ,
        .rx_done            (rx_done)           ,
        .send_done          (send_done)         ,
        .halt_flag          (halt_flag)         ,
        .IM_We              (IM_We)             ,
        .IM_Addr            (IM_Addr)           ,
        .DM_Addr            (DM_Addr)
    );
endmodule