module ID_stage #(
    parameter       NBITS       =   32              ,
    parameter       RBITS       =   5               ,
    parameter       FBITS       =   4               ,
    parameter       OPBITS      =   8               ,
    parameter       BANK_SIZE   =   32
    )
    (
    //Inputs
    input   wire    [NBITS-1:0]     i_ID_current_pc ,
    input   wire    [NBITS-1:0]     i_ID_instruction,
    input   wire    [NBITS-1:0]     i_reg_data      ,
    input   wire    [RBITS-1:0]     i_reg_address   ,
                                    dbg_reg_index   ,
    input   wire    cpu_en      ,   i_regwrite      ,
                    i_clk       ,   i_rst           ,
                                    debug_mode      ,   
    //Outputs
    output  wire    [NBITS-1:0]     o_jump_address  ,   //JAL target address
    output  wire    [NBITS-1:0]     o_Data1         ,
    output  wire    [NBITS-1:0]     o_Data2         ,
    output  wire    [NBITS-1:0]     o_immediate     ,
    output  wire    [RBITS-1:0]     o_ID_rs1        ,
    output  wire    [RBITS-1:0]     o_ID_rs2        ,
    output  wire    [OPBITS-1:0]    o_opcode        ,   //funct3[0],opcode
    output  wire    [FBITS-1:0]     o_funct         ,   //funct7[5],funct3
    output  wire    [RBITS-1:0]     o_ID_rd
    );

    wire    [RBITS-1:0] rs1 ,   rs2 ;
    wire    [NBITS-1:0] immediate   ;
    wire                enable_bank ;

    assign  rs1         =   debug_mode ? dbg_reg_index  :   i_ID_instruction[19:15] ;
    assign  rs2         =   i_ID_instruction[24:20] ;
    assign  enable_bank =   cpu_en  &   i_regwrite  ;

    branch_adder     #(
        .MSB            (NBITS)
    )BRANCHADD
    (
        .current_pc     (i_ID_current_pc)   ,
        .offset         (immediate)         ,
        .branch_addr    (o_jump_address)
    );

    register_bank   #(
        .BANK_SIZE      (BANK_SIZE)         ,
        .WORD_WIDTH     (NBITS)             ,
        .ADDR_LENGTH    (RBITS)             ,
        .DATA_LENGTH    (NBITS)
    )REGBANK
    (
        .i_clk          (i_clk)             ,
        .i_rst          (i_rst)             ,
        .enable         (enable_bank)        ,
        .i_reg1         (rs1)               ,
        .i_reg2         (rs2)               ,
        .i_regW         (i_reg_address)     ,
        .i_Data         (i_reg_data)        ,
        .o_rg1D         (o_Data1)           ,
        .o_rg2D         (o_Data2)
    );

    imm_gen         #(
        .NBITS          (NBITS)
    )IMMGEN
    (
        .instr          (i_ID_instruction)  ,
        .imm            (immediate)
    );

    assign  o_ID_rs1    =   rs1         ;
    assign  o_ID_rs2    =   rs2         ;
    assign  o_funct     =   {i_ID_instruction[30], i_ID_instruction[14:12]} ;
    assign  o_opcode    =   {i_ID_instruction[12], i_ID_instruction[6:0]}   ;
    assign  o_immediate =   immediate   ;
    assign  o_ID_rd     =   i_ID_instruction[11:7]  ;
    
endmodule