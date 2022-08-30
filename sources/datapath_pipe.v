`timescale 1ns / 1ps

module datapath_pipe    #(
    parameter   MEM_SIZE    =       1024    ,
    parameter   BANK_SIZE   =       32      ,
    parameter   NBITS       =       32      ,
    parameter   RBITS       =       5
)
(
    input       wire                clk     ,
    input       wire                rst
);

    // Parametros locales
    localparam      OPBITS      =   6       ;
    localparam      IMMBITS     =   16      ;
    
    /* Internal signals */
    
    // Instruction Fecth
    wire    [NBITS-1:0]     IF_next_pc      ;
    wire    [NBITS-1:0]     current_pc      ;
    wire    [NBITS-1:0]     pc_mux          ;
    wire    [NBITS-1:0]     IF_inst         ;
    
    // Instruction Decode
    wire    [NBITS-1:0]     ID_inst         ;
    wire    [NBITS-1:0]     ID_next_pc      ;
    wire    [OPBITS-1:0]    opcode          ;
    assign  opcode      =   ID_inst[31:26]  ;
    wire    [RBITS-1:0]     ID_rs           ;
    assign  ID_rs       =   ID_inst[25:21]  ;
    wire    [RBITS-1:0]     ID_rt           ;
    assign  ID_rt       =   ID_inst[20:16]  ;
    wire    [RBITS-1:0]     ID_rd           ;
    assign  ID_rd       =   ID_inst[15:11]  ;
    wire    [IMMBITS-1:0]   immediate       ;
    assign  immediate   =   ID_inst[15:0]   ;
    wire    [NBITS-1:0]     ID_immediate    ;
    wire    [NBITS-1:0]     ext_imm         ;
    wire    [NBITS-1:0]     link_pc         ;
    assign  link_pc     =   ID_next_pc + 1  ;
    wire    [NBITS-1:0]     branch_addr     ;
    wire                    zero_Rs_Rt      ;
    wire    [OPBITS-1:0]    ID_funct        ;
    assign  ID_funct    =   ext_imm[5:0]    ;
    wire    [NBITS-1:0]     ID_Rs           ;
    wire    [NBITS-1:0]     ID_Rt           ;
    wire    [NBITS-1:0]     data1           ;
    wire    [NBITS-1:0]     data2           ;
    
    // Execution
    wire    [NBITS-1:0]     EX_Rs           ;
    wire    [NBITS-1:0]     EX_Rt           ;
    wire    [NBITS-1:0]     EX_immediate    ;
    wire    [RBITS-1:0]     EX_rt           ;
    wire    [RBITS-1:0]     EX_rd           ;
    wire    [RBITS-1:0]     ID_EX_rd        ;
    wire    [OPBITS-1:0]    EX_funct        ;
    wire    [NBITS-1:0]     data_from_ALU   ;
    wire    [NBITS-1:0]     inA             ;
    wire    [NBITS-1:0]     inB             ;
    wire    [3:0]           ALUctr          ;
    
    // Memory
    wire    [NBITS-1:0]     MEM_Rt          ;
    wire    [NBITS-1:0]     MEM_result      ;
    wire    [NBITS-1:0]     MEM_data        ;
    wire    [RBITS-1:0]     MEM_rd          ;
    wire    [NBITS-1:0]     data_from_MEM   ;
    
    // Write Back
    wire    [NBITS-1:0]     WB_result       ;
    wire    [NBITS-1:0]     data_from_WB    ;
    wire    [NBITS-1:0]     WB_data         ;
    wire    [RBITS-1:0]     WB_rd           ;
    
    // Control Unit
    wire    RegWrite    ,   MemtoReg        ,
            MemWrite    ,   MemRead         ,
            ALUSrc      ,   Link            ,
            BEQ     ,   BNE     ,   Jump    ;
    wire    [4:0]           SizeControl     ;
    wire    [2:0]           ALUOp           ;
    wire    [1:0]           RegDst          ;
    wire    [1:0]           SelectAddr      ;
    wire    [4:0]           EX_SizeControl  ;
    wire    EX_RegWrite ,   EX_MemtoReg     ,
            EX_MemWrite ,   EX_MemRead      ,
            EX_ALUSrc   ,   EX_Link         ;
    wire    [2:0]           EX_ALUOp        ;
    wire    [1:0]           EX_RegDst       ;
    wire    [4:0]           MEM_SizeControl ;
    wire    MEM_RegWrite,   MEM_MemtoReg    ,
            MEM_MemWrite,   MEM_MemRead     ;
    wire    WB_RegWrite ,   WB_MemtoReg     ;
    
    // Forwarding Unit
    wire    [1:0]   fwd_A   ,   fwd_B       ;
    
    // Hazard Detection Unit
    wire    writePC     ,   stallID         ;
    
    // Branch Control
    wire    branch_sel  ,   branch_comparer ;
    wire    [NBITS-1:0]     selected_addr   ;
    wire    [NBITS-1:0]     jump_addr       ;
    assign jump_addr    =   {ID_next_pc[31:28]  ,   (ID_inst[25:0]<<2)}     ;
    wire                    flush           ;
    wire                    cond_jump       ;
    assign  cond_jump   =   (zero_Rs_Rt & BEQ)  |   (~(zero_Rs_Rt) & BNE)   ;
    assign flush        =   cond_jump           |   Jump                    ;
    
    /*      Modules     */
    
    // Instruction Fetch
    program_counter     #(
        .MSB                (NBITS)
    )PC
    (
        .i_clk              (clk)           ,
        .i_rst              (rst)           ,
        .next_pc            (pc_mux)        ,
        .write_pc           (writePC)       ,
        .o_pc               (current_pc)
    );
    address_mux         #(
        .NBITS              (NBITS)
    )ADDRMUX
    (
        .branch_addr        (branch_addr)   ,
        .jump_addr          (jump_addr)     ,
        .reg_addr           (ID_Rs)         ,
        .sel_addr           (SelectAddr)    ,
        .mux_addr           (selected_addr)
    );
    branch_mux          #(
        .NBITS              (NBITS)
    )BRANCHMUX
    (
        .next_inst          (IF_next_pc)    ,
        .jump_addr          (selected_addr) ,
        .branch             (flush)         ,
        .next_pc            (pc_mux)
    );
    pc_adder            #(
        .MSB                (NBITS)
    )PCADDER
    (
        .current_pc         (current_pc)    ,
        .next_pc            (IF_next_pc)
    );
    IF_ID_reg           #(
        .MSB                (NBITS)
    )IFIDREG
    (
        .i_clk              (clk)           ,
        .i_rst              (rst)           ,
        .flush              (flush)         ,
        .IF_next_pc         (IF_next_pc)    ,
        .IF_inst            (IF_inst)       ,
        .ID_next_pc         (ID_next_pc)    ,
        .ID_inst            (ID_inst)
    );
    instruction_memory  #(
        .MEM_SIZE           (MEM_SIZE)      ,
        .WORD_WIDTH         (NBITS)         ,
        .ADDR_LENGTH        (NBITS)         ,
        .DATA_LENGTH        (NBITS)
    )IMROM
    (
        .i_Addr             (current_pc)    ,
        .o_Data             (IF_inst)
    );
    
    // Instruction Decode
    branch_adder     #(
        .MSB                (NBITS)
    )BRANCHADD
    (
        .next_pc            (ID_next_pc)    ,
        .offset             (ext_imm)       ,
        .branch_addr        (branch_addr)
    );
    sign_extend     #(
        .EXTBITS            (NBITS)         ,
        .NBITS              (IMMBITS)
    )SIGNEXTEND
    (
        .i_sign             (immediate)     ,
        .o_ext              (ext_imm)
    );
    link_mux        #(
        .NBITS              (NBITS)
    )LINKMUX
    (
        .i_linkinst         (link_pc)       ,
        .i_immediate        (ext_imm)       ,
        .link_flag          (Link)          ,
        .o_imm              (ID_immediate)
    );
    forw_mux        #(
        .NBITS              (NBITS)
    )FORWAMUX
    (
        .regbnk_data        (data1)         ,
        .alustg_data        (data_from_ALU) ,
        .memstg_data        (data_from_MEM) ,
        .wbstg_data         (data_from_WB)  ,
        .sel_addr           (fwd_A)         ,
        .mux_forw           (ID_Rs)
    );
    forw_mux        #(
        .NBITS              (NBITS)
    )FORWBMUX
    (
        .regbnk_data        (data2)         ,
        .alustg_data        (data_from_ALU) ,
        .memstg_data        (data_from_MEM) ,
        .wbstg_data         (data_from_WB)  ,
        .sel_addr           (fwd_B)         ,
        .mux_forw           (ID_Rt)
    );
    branch_comparer #(
        .RBITS              (NBITS)
    )ZERO
    (
        .i_rs               (ID_Rs)         ,
        .i_rt               (ID_Rt)         ,
        .zero               (zero_Rs_Rt)
    );
    register_bank   #(
        .BANK_SIZE          (BANK_SIZE)     ,
        .WORD_WIDTH         (NBITS)         ,
        .ADDR_LENGTH        (RBITS)         ,
        .DATA_LENGTH        (NBITS)
    )REGBANK
    (
        .i_clk              (clk)           ,
        .i_rst              (rst)           ,
        .enable             (WB_RegWrite)   ,
        .i_reg1             (ID_rs)         ,
        .i_reg2             (ID_rt)         ,
        .i_regW             (WB_rd)         ,
        .i_Data             (data_from_WB)  ,
        .o_rg1D             (data1)         ,
        .o_rg2D             (data2)
    );
    ID_EX_reg       #(
        .NBITS              (NBITS)         ,
        .RBITS              (RBITS)         ,
        .FBITS              (OPBITS)
    )IDEXREG
    (
        .i_clk              (clk)           ,
        .i_rst              (rst)           ,
        .stallID            (stallID)       ,
        .ID_Rs              (ID_Rs)         ,
        .ID_Rt              (ID_Rt)         ,
        .ID_rd              (ID_rd)         ,
        .ID_rt              (ID_rt)         ,
        .ID_funct           (ID_funct)      ,
        .ID_immediate       (ID_immediate)  ,
        .ID_sizecontrol     (SizeControl)   ,
        .ID_memtoreg        (MemtoReg)      ,
        .ID_alusource       (ALUSrc)        ,
        .ID_memwrite        (MemWrite)      ,
        .ID_memread         (MemRead)       ,
        .ID_link            (Link)          ,
        .ID_regwrite        (RegWrite)      ,
        .ID_aluop           (ALUOp)         ,
        .ID_regdst          (RegDst)        ,
        .EX_Rs              (EX_Rs)         ,
        .EX_Rt              (EX_Rt)         ,
        .EX_rd              (EX_rd)         ,
        .EX_rt              (EX_rt)         ,
        .EX_funct           (EX_funct)      ,
        .EX_immediate       (EX_immediate)  ,
        .EX_sizecontrol     (EX_SizeControl),
        .EX_memtoreg        (EX_MemtoReg)   ,
        .EX_memread         (EX_MemRead)    ,
        .EX_memwrite        (EX_MemWrite)   ,
        .EX_alusource       (EX_ALUSrc)     ,
        .EX_link            (EX_Link)       ,
        .EX_regwrite        (EX_RegWrite)   ,
        .EX_aluop           (EX_ALUOp)      ,
        .EX_regdst          (EX_RegDst)
    );
    
    // Execution
    link_alu_mux    #(
        .NBITS              (NBITS)
    )LINKALUMUX
    (
        .i_rs               (EX_Rs)         ,
        .link_flag          (EX_Link)       ,
        .o_aluinA           (inA)
    );
    alu_source_mux  #(
        .NBITS              (NBITS)
    )ALUSRCMUC
    (
        .i_reg              (EX_Rt)         ,
        .i_immediate        (EX_immediate)  ,
        .alu_source         (EX_ALUSrc)     ,
        .o_aluinB           (inB)
    );
    reg_dst_mux     #(
        .NBITS              (RBITS)
    )REGDSTMUX
    (
        .reg_rt             (EX_rt)         ,
        .reg_rd             (EX_rd)         ,
        .sel_reg            (EX_RegDst)     ,
        .mux_reg            (ID_EX_rd)
    );
    ALU             #(
        .NBITS              (NBITS)
    )ALUALU
    (
        .operando_A         (inA)           ,
        .operando_B         (inB)           ,
        .ALU_control        (ALUctr)        ,
        .result_op          (data_from_ALU)
    );
    ALU_Control     #(
        .FBITS              (OPBITS)
    )ALUCTRL
    (
        .ALU_op             (EX_ALUOp)      ,
        .i_funct            (EX_funct)      ,
        .ALU_control        (ALUctr)
    );
    EX_MEM_reg       #(
        .NBITS              (NBITS)         ,
        .RBITS              (RBITS)
    )EXMEMREG
    (
        .i_clk              (clk)           ,
        .i_rst              (rst)           ,
        .EX_result          (data_from_ALU) ,
        .EX_rd              (ID_EX_rd)      ,
        .EX_Rt              (EX_Rt)         ,
        .EX_sizecontrol     (EX_SizeControl),
        .EX_memtoreg        (EX_MemtoReg)   ,
        .EX_memread         (EX_MemRead)    ,
        .EX_memwrite        (EX_MemWrite)   ,
        .EX_regwrite        (EX_RegWrite)   ,
        .MEM_result         (MEM_result)    ,
        .MEM_rd             (MEM_rd)        ,
        .MEM_Rt             (MEM_Rt)        ,
        .MEM_sizecontrol    (MEM_SizeControl)   ,
        .MEM_memtoreg       (MEM_MemtoReg)  ,
        .MEM_memread        (MEM_MemRead)   ,
        .MEM_memwrite       (MEM_MemWrite)  ,
        .MEM_regwrite       (MEM_RegWrite)
    );
    
    // Memory
    mem_stage_mux   #(
        .NBITS              (NBITS)
    )MEMSTGMUX
    (
        .i_aluresult        (MEM_result)    ,
        .i_memdata          (MEM_data)      ,
        .memread            (MEM_MemRead)   ,
        .o_memstgdata       (data_from_MEM)
    );
    data_memory     #(
        .MEM_SIZE           (MEM_SIZE)      ,
        .WORD_WIDTH         (NBITS)         ,
        .ADDR_LENGTH        (NBITS)         ,
        .DATA_LENGTH        (NBITS)
    )DMRAM
    (
        .i_clk              (clk)           ,
        .i_rst              (rst)           ,
        .i_Addr             (MEM_result)    ,
        .i_Data             (MEM_Rt)        ,
        .We                 (MEM_MemWrite)  ,
        .Re                 (MEM_MemRead)   ,
        .size_control       (MEM_SizeControl)   ,
        .o_Data             (MEM_data)
    );
    MEM_WB_reg     #(
        .NBITS              (NBITS)         ,
        .RBITS              (RBITS)
    )MEMWBREG
    (
        .i_clk              (clk)           ,
        .i_rst              (rst)           ,
        .MEM_result         (MEM_result)    ,
        .MEM_rd             (MEM_rd)        ,
        .MEM_data           (MEM_data)      ,
        .MEM_memtoreg       (MEM_MemtoReg)  ,
        .MEM_regwrite       (MEM_RegWrite)  ,
        .WB_result          (WB_result)     ,
        .WB_rd              (WB_rd)         ,
        .WB_data            (WB_data)       ,
        .WB_regwrite        (WB_RegWrite)   ,
        .WB_memtoreg        (WB_MemtoReg)
    );
    
    // Write Back
    wb_mux      #(
        .NBITS              (NBITS)
    )WBMUX
    (
        .i_aluresult        (WB_result)     ,
        .i_wbstgdata        (WB_data)       ,
        .memtoreg           (WB_MemtoReg)   ,
        .o_regdata          (data_from_WB)
    );
    
    // Specials
    controller_pipe #(
        .FBITS              (OPBITS)        ,
        .INSBITS            (OPBITS)
    )CONTROLLER
    (
        .opcode             (opcode)        ,
        .i_funct            (ID_funct)      ,
        .Reg_write          (RegWrite)      ,
        .ALU_source         (ALUSrc)        ,
        .Mem_write          (MemWrite)      ,
        .ALU_op             (ALUOp)         ,
        .Mem_to_Reg         (MemtoReg)      ,
        .Mem_read           (MemRead)       ,
        .BEQ_flag           (BEQ)           ,
        .BNE_flag           (BNE)           ,
        .Jump_flag          (Jump)          ,
        .Reg_dst            (RegDst)        ,
        .Select_Addr        (SelectAddr)    ,
        .Size_control       (SizeControl)   ,
        .Link_flag          (Link)
    );
    forwarding_unit #(
        .RBITS              (RBITS)
    )FWDUNIT
    (
        .IF_ID_rs           (ID_rs)         ,
        .IF_ID_rt           (ID_rt)         ,
        .ID_EX_rd           (ID_EX_rd)      ,
        .EX_MEM_rd          (MEM_rd)        ,
        .MEM_WB_rd          (WB_rd)         ,
        .ID_EX_regwrite     (EX_RegWrite)   ,
        .EX_MEM_regwrite    (MEM_RegWrite)  ,
        .MEM_WB_regwrite    (WB_RegWrite)   ,
        .forward_A          (fwd_A)         ,
        .forward_B          (fwd_B)
    );
    hazard_detection_unit   #(
        .RBITS              (RBITS)
    )HAZDETECTUNIT
    (
        .IF_ID_rs           (ID_rs)         ,
        .IF_ID_rt           (ID_rt)         ,
        .ID_EX_rd           (ID_EX_rd)      ,
        .ID_EX_memread      (EX_MemRead)    ,
        .write_pc           (writePC)       ,
        .stall_ID           (stallID)
    );
    
endmodule
