`timescale 10ns / 10ps

module debug_ctrl_tb();

    //Parametros
    localparam      IM_ADDR_LENGTH  =   32      ;
    localparam      IM_MEM_SIZE     =   5       ;
    localparam      INST_WIDTH      =   32      ;
    localparam      DM_ADDR_LENGTH  =   32      ;
    localparam      DM_MEM_SIZE     =   2       ;
    localparam      DATA_WIDTH      =   32      ;
    localparam      RBITS           =   5       ;
    localparam      BANK_SIZE       =   2       ;
    localparam      REG_WIDTH       =   32      ;
    localparam      NBITS           =   32      ;
    
    //Entradas
    reg     i_clk       ,       i_rst;
    reg     [NBITS-1:0]         rx_Data     ;
    reg     [REG_WIDTH-1:0]     RB_Data     ;
    reg     [DATA_WIDTH-1:0]    DM_Data     ;
    reg     rx_done     ,       halt_flag   ;
    reg                         tx_done     ;
    reg     [NBITS-1:0]         current_PC  ;
    reg     [NBITS-1:0]         clock_count ;
    
    //Salidas
    wire    [IM_ADDR_LENGTH-1:0]    IM_Addr     ;
    wire    [INST_WIDTH-1:0]        IM_Data     ;
    wire                            IM_We       ;
    wire    [RBITS-1:0]             RB_Addr     ;
    wire    [DM_ADDR_LENGTH-1:0]    DM_Addr     ;
    wire    [NBITS-1:0]             tx_Data     ;
    wire                            tx_start    ;
    wire    clock_enable    ,       o_rst       ;
    

initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        //Stores normales
        i_clk       =       1       ;
        i_rst       =       1       ;
        rx_Data     =       32'h0   ;
        RB_Data     =       32'h452 ;
        DM_Data     =       32'h0   ;
        rx_done     =       0       ;
        halt_flag   =       0       ;
        tx_done     =       0       ;
        current_PC  =       32'h02  ;
        clock_count =       32'h03  ;
        
        #20
        i_rst       =       0       ;
        rx_Data     =       32'hFF  ;           // Primera Instruccion
        
        #10
        rx_done     =       1       ;
        
        #10
        rx_done     =       0       ;
        rx_Data     =       32'h23  ;           //  Segunda Instruccion
        
        #10
        rx_done     =       1       ;
        
        #10
        rx_done     =       0       ;
        rx_Data     =       32'h789 ;           //  Tercera Instruccion
        
        #10
        rx_done     =       1       ;
        
        #10
        rx_done     =       0       ;
        rx_Data     =       32'hFFFFFFFF    ;   //  Ultima instruccion
        
        #10
        rx_done     =       1       ;
        
        //  RECVMODE
        #10
        rx_done     =       0       ;
        rx_Data     =       32'h10001000    ;   //STEPMODE
        
        #10
        rx_done     =       1       ;
        
        //  RUNPROG
        #10
        rx_done     =       0       ;
        //  SENDPC
        #10
        tx_done     =       0       ;
        
        #20
        tx_done     =       1       ;
        
        // SENDDM
        #10
        tx_done     =       0       ;
        
        #30
        tx_done     =       1       ;
        
        #10
        tx_done     =       0       ;
        DM_Data     =       32'hFFFFFFFF    ;   //  Ultimo espacio de memoria
        
        #10
        tx_done     =       1       ;
        
        //  SENDRB
        #10
        tx_done     =       0       ;
        
        #10
        tx_done     =       1       ;
        RB_Data     =       32'h85  ;
        
        #10
        tx_done     =       0       ;
        RB_Data     =       32'hFFFFFFFF    ;   //  Ultimo registro
        
        #10
        tx_done     =       1       ;
        
        //  SENDCLK
        #10
        tx_done     =       0       ;
        
        #10
        tx_done     =       1       ;
        
        //  RECVMODE
        #10
        tx_done     =       0       ;
        rx_done     =       0       ;
        
        #40
        rx_Data     =       32'h45003000    ;   //no STEPMODE
        rx_done     =       1       ;
        
        //  RUNALL
        #10
        rx_done     =       0       ;
        #40
        halt_flag   =       1       ;
        
        //  SENDPC
        #10
        tx_done     =       0       ;
        current_PC  =       32'hFFF ;
        
        #10
        tx_done     =       1       ;
        
        // SENDDM
        #10
        tx_done     =       0       ;
        DM_Data     =       32'hFFF ;
        
        #10
        tx_done     =       1       ;
        
        #10
        tx_done     =       0       ;
        DM_Data     =       32'hFFFFFFFF    ;   //  Ultimo espacio de memoria
        
        #10
        tx_done     =       1       ;
        RB_Data     =       32'h00  ;
        
        //  SENDRB
        #10
        tx_done     =       0       ;
        
        #10
        tx_done     =       1       ;

        #10
        tx_done     =       0       ;
        RB_Data     =       32'hFFFFFFFF    ;   //  Ultimo registro
        
        #10
        tx_done     =       1       ;
        
        //  SENDCLK
        #10
        tx_done     =       0       ;
        
        #10
        tx_done     =       1       ;
        rx_done     =       0       ;
        
        //  RECVPROG
        #20
        
        $finish;
    end
    
    always begin
        #5
        i_clk       =       ~i_clk  ;
    end
    
    debug_controller    #(
        .IM_ADDR_LENGTH         (IM_ADDR_LENGTH)    ,
        .IM_MEM_SIZE            (IM_MEM_SIZE)       ,
        .INST_WIDTH             (INST_WIDTH)        ,
        .DM_ADDR_LENGTH         (DM_ADDR_LENGTH)    ,
        .DM_MEM_SIZE            (DM_MEM_SIZE)       ,
        .DATA_WIDTH             (DATA_WIDTH)        ,
        .RBITS                  (RBITS)             ,
        .BANK_SIZE              (BANK_SIZE)         ,
        .REG_WIDTH              (REG_WIDTH)         ,
        .NBITS                  (NBITS)
    )DBGCTRLTB
    (
        .clk            (i_clk)         ,
        .reset          (i_rst)         ,
        .rx_Data        (rx_Data)       ,
        .RB_Data        (RB_Data)       ,
        .DM_Data        (DM_Data)       ,
        .rx_done        (rx_done)       ,
        .halt_flag      (halt_flag)     ,
        .tx_done        (tx_done)       ,
        .current_PC     (current_PC)    ,
        .clock_count    (clock_count)   ,
        .IM_Addr        (IM_Addr)       ,
        .IM_Data        (IM_Data)       ,
        .IM_We          (IM_We)         ,
        .RB_Addr        (RB_Addr)       ,
        .DM_Addr        (DM_Addr)       ,
        .tx_Data        (tx_Data)       ,
        .tx_start       (tx_start)      ,
        .clock_enable   (clock_enable)  ,
        .o_rst          (o_rst)
    );
    
endmodule