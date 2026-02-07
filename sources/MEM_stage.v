module MEM_stage #(
    parameter       NBITS       =   32              ,
    parameter       MEM_SIZE    =   1024            ,
    parameter       FBITS       =   3
    )
    (
    //Inputs
    input   wire    [NBITS-1:0]     i_ALU_result    ,
    input   wire    [NBITS-1:0]     i_rs2           ,
    input   wire    [FBITS-1:0]     i_size_control  ,   //Only funct3
    input   wire    i_memread   ,   i_memwrite      ,
                    i_clk       ,   i_rst           ,
                                    cpu_en          ,
    //Outputs
    output  wire    [NBITS-1:0]     o_MEM_data      ,   //Data from memory
    output  wire    [NBITS-1:0]     o_data_from_mem
    );

    mem_stage_mux   #(
        .NBITS              (NBITS)
    )MEMSTGMUX
    (
        .i_aluresult        (i_ALU_result)      ,
        .i_memdata          (o_MEM_data)        ,
        .memread            (i_memread)         ,
        .o_memstgdata       (o_data_from_mem)
    );

    data_memory     #(
        .MEM_SIZE           (MEM_SIZE)          ,
        .WORD_WIDTH         (NBITS)             ,
        .ADDR_LENGTH        (NBITS)             ,
        .DATA_LENGTH        (NBITS)
    )DMRAM
    (
        .i_clk              (i_clk)             ,
        .i_rst              (i_rst)             ,
        .i_Addr             (i_ALU_result)      ,
        .i_Data             (i_rs2)             ,
        .We                 (i_memwrite)        ,
        .Re                 (i_memread)         ,
        .cpu_en             (cpu_en)            ,
        .size_control       (i_size_control)    ,
        .o_Data             (o_MEM_data)
    );

endmodule