module EX_stage #(
    parameter       NBITS       =   32              ,
    parameter       FBITS       =   4               ,
    parameter       CTRBITS     =   4               ,
    parameter       OPBITS      =   2
    )
    (
    //Inputs
    input   wire    [NBITS-1:0]     i_Data1         ,
    input   wire    [NBITS-1:0]     i_Data2         ,
    input   wire    [NBITS-1:0]     i_immediate     ,
    input   wire    [NBITS-1:0]     i_data_from_mem ,
    input   wire    [NBITS-1:0]     i_data_from_wb  ,
    input   wire    [FBITS-1:0]     i_funct         ,   //funct[5], funct3
    input   wire    [OPBITS-1:0]    i_forwardA      ,
                    i_forwardB  ,   i_ALUOp         ,
    input   wire                    i_ALUSrc        , 
    //Outputs
    output  wire    [NBITS-1:0]     o_EX_result     ,   //ALU result
    output  wire    [NBITS-1:0]     o_EX_rs2        ,
    output  wire                    o_EX_zero
    );

    wire    [NBITS-1:0]     mux_a   ,   mux_b   ,
                            mux_source          ;
    wire    [CTRBITS-1:0]   alu_control         ;

    //Forwarding Muxes
    forw_mux        #(
        .NBITS          (NBITS)
    )FORWAMUX
    (
        .alustg_data    (i_Data1)           ,
        .memstg_data    (i_data_from_mem)   ,
        .wbstg_data     (i_data_from_wb)    ,
        .sel_addr       (i_forwardA)        ,
        .mux_forw       (mux_a)
    );

    forw_mux        #(
        .NBITS          (NBITS)
    )FORWBMUX
    (
        .alustg_data    (i_Data2)           ,
        .memstg_data    (i_data_from_mem)   ,
        .wbstg_data     (i_data_from_wb)    ,
        .sel_addr       (i_forwardB)        ,
        .mux_forw       (mux_b)
    );

    //ALU modules
    alu_source_mux  #(
        .NBITS          (NBITS)
    )ALUSRCMUX
    (
        .i_reg          (mux_b)         ,
        .i_immediate    (i_immediate)   ,
        .alu_source     (i_ALUSrc)      ,
        .o_aluinB       (mux_source)
    );

    ALU_Control     #(
        .FBITS          (FBITS)
    )ALUCTRL
    (
        .ALU_op         (i_ALUOp)       ,
        .i_funct        (i_funct)       ,
        .ALU_control    (alu_control)
    );

    ALU             #(
        .NBITS          (NBITS)
    )ALUALU
    (
        .operando_A     (mux_a)         ,
        .operando_B     (mux_source)    ,
        .ALU_control    (alu_control)   ,
        .result_op      (o_EX_result)   ,
        .zero           (o_EX_zero)
    );

    assign  o_EX_rs2    =   mux_b       ;
    
endmodule