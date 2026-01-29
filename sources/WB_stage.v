module WB_stage #(
    parameter       NBITS       =   32
    )
    (
    //Inputs
    input   wire    [NBITS-1:0]     i_ALU_result    ,   //WB ALU Result
    input   wire    [NBITS-1:0]     i_Data          ,   //WB mem data
    input   wire    [NBITS-1:0]     i_next_inst     ,   //PC+4
    input   wire    [1:0]           i_select        ,   //Link, MemToReg
    //Outputs
    output  wire    [NBITS-1:0]     o_data_from_wb
    );

    wb_mux      #(
        .NBITS              (NBITS)
    )WBMUX
    (
        .i_aluresult        (i_ALU_result)  ,
        .i_wbstgdata        (i_Data)        ,
        .i_nextinst         (i_next_inst)   ,
        .i_sel              (i_select)      ,
        .o_regdata          (o_data_from_wb)
    );

endmodule