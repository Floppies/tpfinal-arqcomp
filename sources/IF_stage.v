module IF_stage #(
    parameter       NBITS       =   32              ,
    parameter       MEM_SIZE    =   5
    )
    (
    //Entradas
    input   wire    [NBITS-1:0]     i_branch_addr   ,   //Branch and jump address
    input   wire    i_write_pc  ,   i_halt_flag     ,
    input   wire    i_clk       ,   i_rst           ,
                                    i_branch_flag   ,
    //Outputs
    output  wire    [NBITS-1:0]     o_current_pc    ,   //PC
    output  wire    [NBITS-1:0]     o_next_pc       ,   //PC+4
    output  wire    [NBITS-1:0]     o_current_inst      //Instruction
    );

    wire    [NBITS-1:0] IF_next_pc  ;
    wire    [NBITS-1:0] current_pc  ;
    wire    [NBITS-1:0] pc_mux      ;
    wire    [NBITS-1:0] IF_inst     ;
    wire    write_pc_and            ;

    assign  write_pc_and    =   ~i_halt_flag    &   i_write_pc  ;

    branch_mux          #(
        .NBITS      (NBITS)
    )BRANCHMUX
    (
        .next_inst  (IF_next_pc)    ,
        .jump_addr  (i_branch_addr) ,
        .branch     (i_branch_flag) ,
        .next_pc    (pc_mux)
    );

    program_counter     #(
        .MSB        (NBITS)
    )PC
    (
        .i_clk      (i_clk)         ,
        .i_rst      (i_rst)         ,
        .next_pc    (pc_mux)        ,
        .write_pc   (write_pc_and)  ,
        .o_pc       (current_pc)
    );

    pc_adder            #(
        .MSB                (NBITS)
    )PCADDER
    (
        .current_pc (current_pc)    ,
        .next_pc    (IF_next_pc)
    );

    instruction_memory  #(
        .MEM_SIZE       (MEM_SIZE)  ,
        .WORD_WIDTH     (NBITS)     ,
        .ADDR_LENGTH    (NBITS)     ,
        .DATA_LENGTH    (NBITS)
    )IMROM
    (
        .i_Addr         (current_pc)    ,
        .o_Data         (IF_inst)
    );

    assign  o_current_pc    =   current_pc  ;
    assign  o_next_pc       =   IF_next_pc  ;
    assign  o_current_inst  =   IF_inst     ;
    
endmodule