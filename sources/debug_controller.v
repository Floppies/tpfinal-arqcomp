`timescale 1ns / 1ps

module debug_controller #(
    parameter   IM_ADDR_LENGTH      =       32      ,
    parameter   IM_MEM_SIZE         =       5       ,
    parameter   INST_WIDTH          =       32      ,
    parameter   DM_ADDR_LENGTH      =       32      ,
    parameter   DM_MEM_SIZE         =       1024    ,
    parameter   DATA_WIDTH          =       32      ,
    parameter   RBITS               =       5       ,
    parameter   BANK_SIZE           =       32      ,
    parameter   REG_WIDTH           =       32      ,
    parameter   NBITS               =       32
)
(
    //Entradas
    input   wire    clk             ,   reset           ,
    input   wire    [NBITS-1:0]         rx_Data         ,
    input   wire    [REG_WIDTH-1:0]     RB_Data         ,
    input   wire    [DATA_WIDTH-1:0]    DM_Data         ,
    input   wire    rx_done         ,   halt_flag       ,
                                        tx_done         ,
    input   wire    [NBITS-1:0]         current_PC      ,
    input   wire    [NBITS-1:0]         clock_count     ,
    //Outputs
    output  wire    [IM_ADDR_LENGTH-1:0]    IM_Addr     ,
    output  wire    [DATA_WIDTH-1:0]        IM_Data     ,
    output  wire                            IM_We       ,
    output  wire    [RBITS-1:0]             RB_Addr     ,
    output  wire    [DM_ADDR_LENGTH-1:0]    DM_Addr     ,
    output  wire    [NBITS-1:0]             tx_Data     ,
    output  wire                            tx_start    ,
    output  wire    clock_enable    ,       o_rst
    );
    
    /*  Auxiliary signals   */
    wire            send_done   ,   send_flag   ;
    
    debug_control  #(
        .IM_ADDR_LENGTH     (IM_ADDR_LENGTH)    ,
        .INST_WIDTH         (INST_WIDTH)        ,
        .NBITS              (NBITS)
    )DEBUGCNTRLCNTRL
    (
        .clk                (clk)               ,
        .reset              (reset)             ,
        .rx_Data            (rx_Data)           ,
        .rx_done            (rx_done)           ,
        .halt_flag          (halt_flag)         ,
        .send_done          (send_done)         ,
        .enable             (clock_enable)      ,
        .o_reset            (o_rst)             ,
        //.step_flag          (step_flag)         ,
        .send_flag          (send_flag)         ,
        .IM_We              (IM_We)             ,
        .IM_Data            (IM_Data)           ,
        .IM_Addr            (IM_Addr)
    );
    
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
        .clk                (clk)               ,
        .reset              (reset)             ,
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
