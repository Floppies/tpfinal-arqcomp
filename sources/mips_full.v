`timescale 1ns / 1ps

module mips_full    #(
    //  Parametros para las dimensiones de la Instruction Memory
    parameter   IM_ADDR_LENGTH      =       32      ,
    parameter   IM_MEM_SIZE         =       5       ,
    parameter   INST_WIDTH          =       32      ,
    //  Parametros para las dimensiones de la Data Memory
    parameter   DM_ADDR_LENGTH      =       32      ,
    parameter   DM_MEM_SIZE         =       1024    ,
    parameter   DATA_WIDTH          =       32      ,
    //  Parametros para las dimensiones del Register Bank
    parameter   RBITS               =       5       ,
    parameter   BANK_SIZE           =       32      ,
    parameter   REG_WIDTH           =       32      ,
    //  Parametros para la info que viene de la unidad de UART
    parameter   NBITS               =       32
)
(
    input   wire    clk         ,       rst         ,
    input   wire    rx_done     ,       tx_done     ,
    input   wire    [NBITS-1:0]         rx_Data     ,
    output  wire                        tx_start    ,
    output  wire    [NBITS-1:0]         tx_Data
);

    /*      Señales auxiliares      */
    wire            i_clk       ,       i_rst       ;
    
    //  MIPS Pipeline
    wire    [IM_ADDR_LENGTH-1:0]        IM_Addr_MIPS;
    wire    [RBITS-1:0]                 RB_Addr1    ;
    wire    [RBITS-1:0]                 RB_Addr2    ;
    wire    [RBITS-1:0]                 RB_AddrW    ;
    wire    [REG_WIDTH-1:0]             RB_Data1    ;
    wire    [REG_WIDTH-1:0]             RB_Data2    ;
    wire    [REG_WIDTH-1:0]             RB_Data     ;
    wire                                RB_RegWrite ;
    wire    [DM_ADDR_LENGTH-1:0]        DM_Addr     ;
    wire    [DATA_WIDTH-1:0]            DM_Data     ;
    wire    [4:0]                       DM_SizeCtrl ;
    wire                                DM_MemWrite ;
    wire                                halt_flag   ;
    
    //  Debug Unit
    wire    [IM_ADDR_LENGTH-1:0]        IM_Addr_DU  ;
    wire    [INST_WIDTH-1:0]            IM_Data_DU  ;
    wire                                IM_We_DU    ;
    wire    [RBITS-1:0]                 RB_Addr_DU  ;
    wire    [DM_ADDR_LENGTH-1:0]        DM_Addr_DU  ;
    wire        o_clock         ,       o_rst       ;
    
    //  Memorias
    wire    [IM_ADDR_LENGTH-1:0]        IM_Addr     ;
    assign  IM_Addre        =   (enable) ? IM_Addr_MIPS : IM_Addr_DU    ;
    wire    [INST_WIDTH-1:0]            IM_inst     ;
    
    wire    [RBITS-1:0]                 register2   ;
    assign  register2       =   (enable) ? RB_Addr2 : RB_Addr_DU    ;
    wire    [REG_WIDTH-1:0]             data1       ;
    wire    [REG_WIDTH-1:0]             data2       ;
    
    wire    [DM_ADDR_LENGTH-1:0]        dm_address  ;
    assign  dm_address      =   (enable) ? DM_Addr      : DM_Addr_DU    ;
    wire    [DATA_WIDTH-1:0]            DM_readData ;
    
    /*      Declaracion modulos     */
    
    mips_pipeline   #(
        .IM_ADDR_LENGTH     (IM_ADDR_LENGTH)    ,
        .INST_WIDTH         (INST_WIDTH)        ,
        .DM_ADDR_LENGTH     (DM_ADDR_LENGTH)    ,
        .DATA_WIDTH         (DATA_WIDTH)        ,
        .RBITS              (RBITS)             ,
        .REG_WIDTH          (REG_WIDTH)         ,
        .NBITS              (NBITS)
    )MIPSPIPELINE
    (
        .clk                (o_clock)           ,
        .rst                (o_rst)             ,
        .IM_inst            (IM_inst)           ,
        .RB_Data1           (data1)             ,
        .RB_Data2           (data2)             ,
        .DM_readData        (DM_readData)       ,
        .halt_flag          (halt_flag)         ,
        .IM_Addr            (IM_Addr_MIPS)      ,
        .RB_Addr1           (RB_Addr1)          ,
        .RB_Addr2           (RB_Addr2)          ,
        .RB_AddrW           (RB_AddrW)          ,
        .RB_Data            (RB_Data)           ,
        .RB_RegWrite        (RB_RegWrite)       ,
        .DM_Addr            (DM_Addr)           ,
        .DM_Data            (DM_Data)           ,
        .DM_SizeCtrl        (DM_SizeCtrl)       ,
        .DM_MemWrite        (DM_MemWrite)
    );
    
    debug_unit      #(
        .IM_ADDR_LENGTH     (IM_ADDR_LENGTH)    ,
        .IM_MEM_SIZE        (IM_MEM_SIZE)       ,
        .INST_WIDTH         (INST_WIDTH)        ,
        .DM_ADDR_LENGTH     (DM_ADDR_LENGTH)    ,
        .DM_MEM_SIZE        (DM_MEM_SIZE)       ,
        .DATA_WIDTH         (DATA_WIDTH)        ,
        .RBITS              (RBITS)             ,
        .BANK_SIZE          (BANK_SIZE)         ,
        .REG_WIDTH          (REG_WIDTH)         ,
        .NBITS              (NBITS)
    )DEBUGUNIT
    (
        .clk                (clk_out1)          ,
        .rst                (locked)            ,
        .halt_flag          (halt_flag)         ,
        .current_pc         (IM_Addr_MIPS)      ,
        .RB_Data            (data2)             ,
        .DM_Data            (DM_readData)       ,
        .rx_Data            (rx_Data)           ,
        .tx_Data            (tx_Data)           ,
        .rx_done            (rx_done)           ,
        .tx_done            (tx_done)           ,
        .tx_start           (tx_start)          ,
        .IM_Addr            (IM_Addr_DU)        ,
        .IM_Data            (IM_Data_DU)        ,
        .IM_We              (IM_We_DU)          ,
        .RB_Addr            (RB_Addr_DU)        ,
        .DM_Addr            (DM_Addr_DU)        ,
        .o_clock            (o_clock)           ,
        .o_rst              (o_rst)
    );
    
    instruction_memory      #(
        .MEM_SIZE           (IM_MEM_SIZE)       ,
        .WORD_WIDTH         (INST_WIDTH)        ,
        .ADDR_LENGTH        (IM_ADDR_LENGTH)    ,
        .DATA_LENGTH        (INST_WIDTH)
    )IMIM
    (
        .i_clk              (clk_out1)          ,
        .i_rst              (o_rst)             ,
        .We                 (IM_We_DU)          ,
        .i_Addr             (IM_Addr)           ,
        .i_Data             (IM_Data_DU)        ,
        .o_Data             (IM_inst)
    );
    
    register_bank       #(
        .BANK_SIZE          (BANK_SIZE)         ,
        .REG_WIDTH          (REG_WIDTH)         ,
        .ADDR_LENGTH        (RBITS)             ,
        .DATA_LENGTH        (REG_WIDTH)
    )RGBANK
    (
        .i_clk              (clk_out1)          ,
        .i_rst              (o_rst)             ,
        .enable             (RB_RegWrite)       ,
        .i_reg1             (RB_Addr1)          ,
        .i_reg2             (register2)         ,
        .i_regW             (RB_AddrW)          ,
        .i_Data             (RB_Data)           ,
        .o_rg1D             (data1)             ,
        .o_rg2D             (data2)
    );
    
    data_memory     #(
        .MEM_SIZE           (DM_MEM_SIZE)       ,
        .WORD_WIDTH         (DATA_WIDTH)        ,
        .ADDR_LENGTH        (DM_ADDR_LENGTH)    ,
        .DATA_LENGTH        (DATA_WIDTH)
    )DMDM
    (
        .i_clk              (clk_out1)          ,
        .i_rst              (o_rst)             ,
        .i_Addr             (dm_address)        ,
        .We                 (DM_RegWrite)       ,
        .size_control       (DM_SizeCtrl)       ,
        .i_Data             (DM_Data)           ,
        .o_Data             (DM_readData)
    );
    
endmodule
