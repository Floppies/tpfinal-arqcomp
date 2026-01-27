`timescale 1ns / 1ps

module if_stage_tb();

    //Local Parameters
    localparam NBITS    =   32  ;
    localparam MEM_SIZE =   16  ;

    reg [NBITS-1:0] i_branch_addr   ;
    reg             i_write_pc      ;
    reg             i_halt_flag     ;
    reg             i_clk           ;
    reg             i_rst           ;
    reg             i_branch_flag   ;

    wire    [NBITS-1:0] o_current_pc    ;
    wire    [NBITS-1:0] o_next_pc       ;
    wire    [NBITS-1:0] o_current_inst  ;

    initial begin
        $dumpfile("if_stage_tb.vcd"); $dumpvars;
        i_clk           =   1'b0    ;
        i_rst           =   1'b1    ;
        i_write_pc      =   1'b1    ;
        i_halt_flag     =   1'b0    ;
        i_branch_flag   =   1'b0    ;
        i_branch_addr   =   32'd2   ;

        #10
        i_rst           =   1'b0    ;

        // Let PC run a few cycles
        #40

        // Force a branch/jump
        i_branch_flag   =   1'b1    ;
        #10
        i_branch_flag   =   1'b0    ;

        // Halt should freeze PC
        #20
        i_halt_flag     =   1'b1    ;
        #20;
        i_halt_flag     =   1'b0    ;

        // Disable write_pc (stall)
        #20
        i_write_pc      =   1'b0    ;
        #20
        i_write_pc      =   1'b1    ;

        #40
        $finish;
    end

    always begin
        #5
        i_clk   =   ~i_clk  ;
    end

    IF_stage
    #(
        .NBITS          (NBITS)     ,
        .MEM_SIZE       (MEM_SIZE)
    )IFSTAGE
    (
        .i_branch_addr  (i_branch_addr) ,
        .i_write_pc     (i_write_pc)    ,
        .i_halt_flag    (i_halt_flag)   ,
        .i_clk          (i_clk)         ,
        .i_rst          (i_rst)         ,
        .i_branch_flag  (i_branch_flag) ,
        .o_current_pc   (o_current_pc)  ,
        .o_next_pc      (o_next_pc)     ,
        .o_current_inst (o_current_inst)
    );

endmodule
