`timescale 1ns / 1ps

module datapath_pipe    #(
    parameter   NBITS   =   32  ,
    parameter   RBITS   =   5
)
(
    input   wire    clk ,
    input   wire    rst
);

    // Parametros locales
    localparam      OPBITS      =   6       ;
    localparam      IMMBITS     =   16      ;
    
    /* Internal signals */
    
    // Instruction Fecth
    wire    [NBITS-1:0]     IF_next_pc      ;
    wire    [NBITS-1:0]     current_pc      ;
    wire    [NBITS-1:0]     jump_addr       ;
    wire    [NBITS-1:0]     IF_inst         ;
    
    // Instruction Decode
    wire    [NBITS-1:0]     ID_inst         ;
    wire    [NBITS-1:0]     ID_next_pc      ;
    wire    [OPBITS-1:0]    opcode          ;
    wire    [RBITS-1:0]     ID_rs           ;
    wire    [RBITS-1:0]     ID_rt           ;
    wire    [RBITS-1:0]     ID_rd           ;
    wire    [IMMBITS-1:0]   immediate       ;
    wire    [NBITS-1:0]     ID_immediate    ;
    wire    [NBITS-1:0]     ext_immediate   ;
    wire    [NBITS-1:0]     link_pc         ;
    wire    [OPBITS-1:0]    ID_funct        ;
    wire    [NBITS-1:0]     ID_Rs           ;
    wire    [NBITS-1:0]     ID_Rt           ;
    wire    [NBITS-1:0]     data1           ;
    wire    [NBITS-1:0]     data2           ;
    wire    [NBITS-1:0]     data_from_ALU   ;
    wire    [NBITS-1:0]     data_from_MEM   ;
    wire    [NBITS-1:0]     data_from_WB    ;
    
    // Execution
    wire    [NBITS-1:0]     EX_Rs           ;
    wire    [NBITS-1:0]     EX_Rt           ;
    wire    [NBITS-1:0]     EX_immediate    ;
    wire    [RBITS-1:0]     EX_rt           ;
    wire    [RBITS-1:0]     EX_rd           ;
    wire    [RBITS-1:0]     ID_EX_rd        ;
    wire    [OPBITS-1:0]    EX_funct        ;
    wire    [NBITS-1:0]     EX_result       ;
    wire    [NBITS-1:0]     inA             ;
    wire    [NBITS-1:0]     inB             ;
    wire    [3:0]           ALUctr          ;
    
    // Memory
    wire    [NBITS-1:0]     MEM_result      ;
    wire    [NBITS-1:0]     MEM_Rt          ;
    wire    [NBITS-1:0]     MEM_data        ;
    wire    [RBITS-1:0]     MEM_rd          ;
    
    // Write Back
    wire    [NBITS-1:0]     WB_result       ;
    wire    [NBITS-1:0]     WB_data         ;
    wire    [RBITS-1:0]     WB_rd           ;
    
    // Control Unit
    wire    RegWrite    ,   MemtoReg        ,
            MemWrite    ,   MemRead         ,
            ALUSrc      ,   Link            ,
            BEQ     ,   BNE     ,   Jump    ;
    wire    [4:0]           SizeControl     ;
    wire    [1:0]           ALUOp           ;
    wire    [1:0]           RegDst          ;
    wire    [1:0]           SelectAddr      ;
    wire    [4:0]           EX_SizeControl  ;
    wire    EX_RegWrite ,   EX_MemtoReg     ,
            EX_MemWrite ,   EX_MemRead      ,
            EX_ALUSrc   ,   EX_Link         ;
    wire    [1:0]           EX_ALUOp        ;
    wire    [1:0]           EX_RegDst       ;
    wire    [4:0]           MEM_SizeControl ;
    wire    MEM_RegWrite,   MEM_MemtoReg    ,
            MEM_MemWrite,   MEM_MemRead     ;
    wire    WB_RegWrite ,   WB_MemtoReg     ;
    
    // Forwarding Unit
    wire    [1:0]   fwd_A   ,   Fwd_B       ;
    
    // Hazard Detection Unit
    wire    writePC     ,   StallID         ;
    
    // Branch Control
    wire    branch_sel  ,   branch_comparer ;
    wire    [NBITS-1:0]     branch_addr     ;
    wire    [NBITS-1:0]     jump_target_addr;
    wire                    flush           ;
    
endmodule
