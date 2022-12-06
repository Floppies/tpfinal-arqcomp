`timescale 100ns / 100ps

module send_control_tb();

    //Parametros
    localparam      DM_ADDR_LENGTH  =   32      ;
    localparam      DM_MEM_SIZE     =   4       ;
    localparam      DATA_WIDTH      =   32      ;
    localparam      RBITS           =   5       ;
    localparam      BANK_SIZE       =   4       ;
    localparam      REG_WIDTH       =   32      ;
    localparam      NBITS           =   32      ;
    
    //Entradas
    reg     i_clk       ,       i_rst       ;
    reg     [REG_WIDTH-1:0]     RB_Data     ;
    reg     [DATA_WIDTH-1:0]    DM_Data     ;
    reg     tx_done     ,       send_flag   ;
    reg     [NBITS-1:0]         current_PC  ;
    reg     [NBITS-1:0]         clock_count ;
    
    //Salidas
    wire    [RBITS-1:0]             RB_Addr     ;
    wire    [DM_ADDR_LENGTH-1:0]    DM_Addr     ;
    wire    [NBITS-1:0]             tx_Data     ;
    wire    send_done   ,           tx_start    ;
    
initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        //Stores normales
        i_clk       =       1       ;
        i_rst       =       1       ;
        RB_Data     =       32'h45  ;
        DM_Data     =       32'h7F  ;
        current_PC  =       32'h02  ;
        clock_count =       32'h03  ;
        tx_done     =       0       ;
        send_flag   =       0       ;
        
        #20
        i_rst       =       0       ;
        
        #10
        send_flag   =       1       ;
        
        #10
        tx_done     =       1       ;
        
        #5
        tx_done     =       0       ;
        
        #15
        tx_done     =       1       ;
        send_flag   =       0       ;
        
        #5
        tx_done     =       1      ;
        #5
        tx_done     =       1       ;
        #5
        tx_done     =       1       ;
        DM_Data     =   32'hFFFFFFFF;
        #5
        tx_done     =       1       ;
        #5
        tx_done     =       1       ;
        #5
        tx_done     =       1       ;
        #5
        tx_done     =       1       ;
        RB_Data     =   32'hFFFFFFFF; 
        #5
        tx_done     =       1       ;
        
        #5
        tx_done     =       1       ;
        
        #5
        tx_done     =       1       ;
        
        #95
        tx_done     =       0       ;


        #20
        $finish;
    end
    
    always begin
        #5
        i_clk       =       ~i_clk  ;
    end
    
    send_control    #(
        .DM_ADDR_LENGTH         (DM_ADDR_LENGTH)    ,
        .DM_MEM_SIZE            (DM_MEM_SIZE)       ,
        .DATA_WIDTH             (DATA_WIDTH)        ,
        .RBITS                  (RBITS)             ,
        .BANK_SIZE              (BANK_SIZE)         ,
        .REG_WIDTH              (REG_WIDTH)         ,
        .NBITS                  (NBITS)
    )SENDCTRL
    (
        .clk                (i_clk)             ,
        .reset              (i_rst)             ,
        .DM_Data            (DM_Data)           ,
        .RB_Data            (RB_Data)           ,
        .tx_Data            (tx_Data)           ,
        .tx_done            (tx_done)           ,
        .send_done          (send_done)         ,
        .current_pc         (current_PC)        ,
        .clock_count        (clock_count)       ,
        .send_flag          (send_flag)         ,
        .tx_start           (tx_start)          ,
        .RB_Addr            (RB_Addr)           ,
        .DM_Addr            (DM_Addr)
    );
endmodule
