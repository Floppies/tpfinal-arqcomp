`timescale 1ns / 1ps

module datapath_pipe    #(
    parameter   MEM_SIZE    =       1024    ,
    parameter   BANK_SIZE   =       32      ,
    parameter   NBITS       =       32      ,
    parameter   RBITS       =       5
)
(
    input       wire                i_clk   ,
    input       wire                i_rst   ,
    output      wire    [NBITS-1:0] o_pc
);

    // Parametros locales
    localparam      OPBITS      =   8       ;
    localparam      FBITS       =   4       ;
    localparam      IMMBITS     =   16      ;
    
    /* Internal signals */

    // Instruction Fetch stage
    wire    [NBITS-1:0]     IF_next_pc      ,
                            IF_current_pc   ,
                            IF_instruction  ;
    wire                    IF_ID_write     ;

    assign  IF_ID_write =   HDU_IFID_write  &   ~ID_halt    ;
    assign  o_pc        =   IF_current_pc   ;

    // Instruction Decode stage
    wire    [NBITS-1:0]     ID_next_pc      ,
                            ID_current_pc   ,
                            ID_instruction  ,
                            ID_jump_address ,   //JAL target address
                            ID_Data1        ,
                            ID_Data2        ,
                            ID_immediate    ;
    wire    [RBITS-1:0]     ID_rs1          ,
                            ID_rs2          ,
                            ID_rd           ;
    wire    [OPBITS-1:0]    ID_opcode       ;   //funct3[0],opcode
    wire    [FBITS-1:0]     ID_funct        ;   //funct7[5],funct3
    
    // Execution stage
    wire    [NBITS-1:0]     EX_Data1        ,
                            EX_Data2        ,
                            EX_jump_address ,
                            EX_next_pc      ,
                            EX_ALU_result   ,
                            EX_immediate    ,
                            EX_Rs2          ;
    wire    [RBITS-1:0]     EX_rd           ,
                            EX_rs1          ,
                            EX_rs2          ;
    wire    [FBITS-1:0]     EX_funct        ;   //funct7[5],funct3
    wire    [2:0]           EX_sizecontrol  ;   // funct3
    wire                    EX_zero         ;

    assign  EX_sizecontrol  =   EX_funct[2:0]   ;

    // Memory stage
    wire    [NBITS-1:0]     MEM_result          ,
                            MEM_Rs2             ,
                            MEM_next_pc         ,
                            MEM_data            ,
                            MEM_data_from_mem   ;
    wire    [RBITS-1:0]     MEM_rd              ;
    wire    [2:0]           MEM_sizecontrol     ;

    // Write Back stage
    wire    [NBITS-1:0]     WB_result           ,
                            WB_data             ,
                            WB_next_pc          ,
                            WB_data_from_wb     ;
    wire    [RBITS-1:0]     WB_rd               ;
    wire    [1:0]           WB_select           ;

    assign  WB_select   =   {WB_link, WB_memtoreg}  ;

    // Control Signals
    wire    ID_bne      ,   ID_beq      ,   //ID stage
            ID_link     ,   ID_jumpreg  ,
            ID_halt     ,   ID_jump     ,
            ID_regwrite ,   ID_memtoreg ,
            ID_memread  ,   ID_memwrite ,
                            ID_alusource;
    wire    [1:0]           ID_aluop    ;
    wire    EX_bne      ,   EX_beq      ,   //EX stage
            EX_link     ,   EX_jumpreg  ,
                            EX_alusource,
            EX_regwrite ,   EX_memtoreg ,
            EX_memread  ,   EX_memwrite ;
    wire    [1:0]           EX_aluop    ;
    wire                    MEM_link    ,   //MEM stage
            MEM_regwrite,   MEM_memtoreg,
            MEM_memread ,   MEM_memwrite;
    wire                    WB_link     ,   //WB stage
            WB_regwrite ,   WB_memtoreg ;

    // Forwarding Unit
    wire    [1:0]           forward_A   ,
                            forward_B   ;
    
    // Hazard Detection Unit
    wire                    HDU_write_pc    ,
                            HDU_IDEX_flush  ,
                            HDU_IFID_flush  ,
                            HDU_IFID_write  ;
    
    // Branch Control
    wire    [NBITS-1:0]     selected_addr   ;
    wire    [NBITS-1:0]     reg_jump        ;
    wire    [1:0]           branch_sel      ;
    wire    cond_jump   ,   incond_jump     ,
            address_sel ,   branch_taken    ;


    assign  cond_jump       =   (EX_zero & EX_beq)  |   (~EX_zero & EX_bne) ;
    assign  incond_jump     =   ID_jump     |   EX_jumpreg      ;
    assign  branch_taken    =   EX_beq      |   EX_bne          ;
    assign  branch_sel      =   {EX_jumpreg ,   branch_taken}   ;
    assign  address_sel     =   cond_jump   |   incond_jump     ;
    assign  reg_jump        =   EX_ALU_result   &   ~1          ;
    
    /*      Modules     */
    
    // Instruction Fetch
    IF_stage            #(
        .NBITS          (NBITS)         ,
        .MEM_SIZE       (MEM_SIZE)
    )IFSTAGE
    (
        .i_branch_addr  (selected_addr) ,
        .i_write_pc     (HDU_write_pc)  ,
        .i_halt_flag    (ID_halt)       ,
        .i_clk          (i_clk)         ,
        .i_rst          (i_rst)         ,
        .i_branch_flag  (address_sel)   ,
        .o_current_pc   (IF_current_pc) ,
        .o_next_pc      (IF_next_pc)    ,
        .o_current_inst (IF_instruction)
    );

    IF_ID_reg           #(
        .MSB            (NBITS)
    )IFIDREG
    (
        .i_clk          (i_clk)         ,
        .i_rst          (i_rst)         ,
        .flush          (HDU_IFID_flush),
        .We             (IF_ID_write)   ,
        .IF_next_pc     (IF_next_pc)    ,
        .IF_current_pc  (IF_current_pc) ,
        .IF_inst        (IF_instruction),
        .ID_next_pc     (ID_next_pc)    ,
        .ID_current_pc  (ID_current_pc) ,
        .ID_inst        (ID_instruction)
    );
    
    // Instruction Decode
    ID_stage                #(
        .NBITS              (NBITS)             ,
        .RBITS              (RBITS)             ,
        .FBITS              (FBITS)             ,
        .OPBITS             (OPBITS)            ,
        .BANK_SIZE          (BANK_SIZE)
    )IDSTAGE
    (
        .i_ID_current_pc    (ID_current_pc)     ,
        .i_ID_instruction   (ID_instruction)    ,
        .i_reg_data         (WB_data_from_wb)   ,
        .i_reg_address      (WB_rd)             ,
        .i_regwrite         (WB_regwrite)       ,
        .i_clk              (i_clk)             ,
        .i_rst              (i_rst)             ,
        .o_jump_address     (ID_jump_address)   ,
        .o_Data1            (ID_Data1)          ,
        .o_Data2            (ID_Data2)          ,
        .o_immediate        (ID_immediate)      ,
        .o_ID_rs1           (ID_rs1)            ,
        .o_ID_rs2           (ID_rs2)            ,
        .o_opcode           (ID_opcode)         ,
        .o_funct            (ID_funct)          ,
        .o_ID_rd            (ID_rd)
    );

    ID_EX_reg           #(
        .NBITS          (NBITS)             ,
        .FBITS          (FBITS)             ,
        .RBITS          (RBITS)
    )IDEXREG
    (
        .i_clk          (i_clk)             ,
        .i_rst          (i_rst)             ,
        .ID_EX_flush    (HDU_IDEX_flush)    ,
        .ID_Rs1         (ID_Data1)          ,
        .ID_Rs2         (ID_Data2)          ,
        .ID_rs1         (ID_rs1)            ,
        .ID_rs2         (ID_rs2)            ,
        .ID_next_pc     (ID_next_pc)        ,
        .ID_rd          (ID_rd)             ,
        .ID_funct       (ID_funct)          ,
        .ID_immediate   (ID_immediate)      ,
        .ID_jump_address(ID_jump_address)   ,
        .ID_memtoreg    (ID_memtoreg)       ,
        .ID_memread     (ID_memread)        ,
        .ID_memwrite    (ID_memwrite)       ,
        .ID_JumpReg     (ID_jumpreg)        ,
        .ID_BEQ         (ID_beq)            ,
        .ID_BNE         (ID_bne)            ,
        .ID_alusource   (ID_alusource)      ,
        .ID_link        (ID_link)           ,
        .ID_regwrite    (ID_regwrite)       ,
        .ID_aluop       (ID_aluop)          ,
        .EX_Rs1         (EX_Data1)          ,
        .EX_Rs2         (EX_Data2)          ,
        .EX_rs1         (EX_rs1)            ,
        .EX_rs2         (EX_rs2)            ,
        .EX_rd          (EX_rd)             ,
        .EX_funct       (EX_funct)          ,
        .EX_immediate   (EX_immediate)      ,
        .EX_jump_address(EX_jump_address)   ,
        .EX_next_pc     (EX_next_pc)        ,
        .EX_memtoreg    (EX_memtoreg)       ,
        .EX_memread     (EX_memread)        ,
        .EX_memwrite    (EX_memwrite)       ,
        .EX_alusource   (EX_alusource)      ,
        .EX_link        (EX_link)           ,
        .EX_regwrite    (EX_regwrite)       ,
        .EX_JumpReg     (EX_jumpreg)        ,
        .EX_BEQ         (EX_beq)            ,
        .EX_BNE         (EX_bne)            ,
        .EX_aluop       (EX_aluop)
    );
    
    // Execution
    EX_stage #(
        .NBITS              (NBITS)             ,
        .FBITS              (FBITS)             ,
        .CTRBITS            (FBITS)             ,
        .OPBITS             (OPBITS)
    )EXSTAGE
    (
        .i_Data1            (EX_Data1)          ,
        .i_Data2            (EX_Data2)          ,
        .i_immediate        (EX_immediate)      ,
        .i_data_from_mem    (MEM_data_from_mem) ,
        .i_data_from_wb     (WB_data_from_wb)   ,
        .i_funct            (EX_funct)          ,
        .i_forwardA         (forward_A)         ,
        .i_forwardB         (forward_B)         ,
        .i_ALUOp            (EX_aluop)          ,
        .i_ALUSrc           (EX_alusource)      ,
        .o_EX_result        (EX_ALU_result)     ,
        .o_EX_rs2           (EX_Rs2)            ,
        .o_EX_zero          (EX_zero)
    );

    EX_MEM_reg          #(
        .NBITS          (NBITS)     ,
        .RBITS          (RBITS)     ,
        .FBITS          (FBITS-1)
    )EXMEMREG
    (
        .i_clk          (i_clk)         ,
        .i_rst          (i_rst)         ,
        .EX_next_inst   (EX_next_pc)    ,
        .EX_rs2         (EX_Rs2)        ,
        .EX_rd          (EX_rd)         ,
        .EX_result      (EX_ALU_result) ,
        .EX_memtoreg    (EX_memtoreg)   ,
        .EX_memwrite    (EX_memwrite)   ,
        .EX_memread     (EX_memread)    ,
        .EX_regwrite    (EX_regwrite)   ,
        .EX_sizecontrol (EX_sizecontrol),
        .EX_link        (EX_link)       ,
        .MEM_result     (MEM_result)    ,
        .MEM_next_inst  (MEM_next_pc)   ,
        .MEM_rs2        (MEM_Rs2)       ,
        .MEM_rd         (MEM_rd)        ,
        .MEM_memtoreg   (MEM_memtoreg)  ,
        .MEM_memread    (MEM_memread)   ,
        .MEM_memwrite   (MEM_memwrite)  ,
        .MEM_regwrite   (MEM_regwrite)  ,
        .MEM_link       (MEM_link)      ,
        .MEM_sizecontrol(MEM_sizecontrol)
    );
    
    // Memory
    MEM_stage           #(
        .NBITS          (NBITS)             ,
        .MEM_SIZE       (MEM_SIZE)          ,
        .FBITS          (FBITS-1)
    )MEMSTAGE
    (
        .i_ALU_result   (MEM_result)        ,
        .i_rs2          (MEM_Rs2)           ,
        .i_size_control (MEM_sizecontrol)   ,
        .i_memread      (MEM_memread)       ,
        .i_memwrite     (MEM_memwrite)      ,
        .i_clk          (i_clk)             ,
        .i_rst          (i_rst)             ,
        .o_MEM_data     (MEM_data)          ,
        .o_data_from_mem(MEM_data_from_mem)
    );

    MEM_WB_reg          #(
        .NBITS          (NBITS)         ,
        .RBITS          (RBITS)
    )MEMWBREG
    (
        .i_clk          (i_clk)         ,
        .i_rst          (i_rst)         ,
        .MEM_result     (MEM_result)    ,
        .MEM_rd         (MEM_rd)        ,
        .MEM_data       (MEM_data)      ,
        .MEM_next_inst  (MEM_next_pc)   ,
        .MEM_regwrite   (MEM_regwrite)  ,
        .MEM_memtoreg   (MEM_memtoreg)  ,
        .MEM_link       (MEM_link)      ,
        .WB_result      (WB_result)     ,
        .WB_rd          (WB_rd)         ,
        .WB_data        (WB_data)       ,
        .WB_next_inst   (WB_next_pc)    ,
        .WB_regwrite    (WB_regwrite)   ,
        .WB_memtoreg    (WB_memtoreg)   ,
        .WB_link        (WB_link)
    );
    
    // Write Back
    WB_stage        #(
        .NBITS          (NBITS)
    )WBSTAGE
    (
        .i_ALU_result   (WB_result)     ,
        .i_Data         (WB_data)       ,
        .i_next_inst    (WB_next_pc)    ,
        .i_select       (WB_select)     ,
        .o_data_from_wb (WB_data_from_wb)
    );
    
    // Specials
    controller_pipe     #(
        .NSBITS         (OPBITS)
    )CONTROLLER
    (
        .i_opcode       (ID_opcode)        ,
        .Reg_write      (ID_regwrite)     ,
        .ALU_source     (ID_alusource)    ,
        .Mem_write      (ID_memwrite)     ,
        .ALU_op         (ID_aluop)        ,
        .Mem_to_Reg     (ID_memtoreg)    ,
        .Mem_read       (ID_memread)      ,
        .BEQ_flag       (ID_beq)           ,
        .BNE_flag       (ID_bne)           ,
        .Jump_flag      (ID_jump)          ,
        .Jump_reg       (ID_jumpreg)      ,
        .Halt_flag      (ID_halt)          ,
        .Link_flag      (ID_link)
    );

    forwarding_unit         #(
        .RBITS              (RBITS)
    )FORWARDINGUNIT
    (
        .ID_EX_rs1          (EX_rs1)        ,
        .ID_EX_rs2          (EX_rs2)        ,
        .EX_MEM_rd          (MEM_rd)        ,
        .MEM_WB_rd          (WB_rd)         ,
        .EX_MEM_regwrite    (MEM_regwrite)  ,
        .MEM_WB_regwrite    (WB_regwrite)   ,
        .forward_A          (forward_A)     ,
        .forward_B          (forward_B)
    );

    hazard_detection_unit   #(
        .RBITS              (RBITS)
    )HDU
    (
        .IF_ID_rs1          (ID_rs1)        ,
        .IF_ID_rs2          (ID_rs2)        ,
        .ID_EX_rd           (EX_rd)         ,
        .ID_EX_memread      (EX_memread)    ,
        .ID_EX_alusrc       (EX_alusource)  ,
        .ID_EX_memwrite     (EX_memwrite)   ,
        .redirect           (address_sel)   ,
        .write_pc           (HDU_write_pc)  ,
        .IFID_write         (HDU_IFID_write),
        .IFID_flush         (HDU_IFID_flush),
        .IDEX_flush         (HDU_IDEX_flush)
    );

    address_mux             #(
        .NBITS          (NBITS)
    )ADDRESMUX
    (
        .branch_addr    (EX_jump_address)   ,
        .jump_addr      (ID_jump_address)   ,
        .reg_addr       (reg_jump)          ,
        .sel_addr       (branch_sel)        ,
        .mux_addr       (selected_addr)
    );
    
endmodule
