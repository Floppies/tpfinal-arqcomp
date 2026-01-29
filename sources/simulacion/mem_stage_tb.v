`timescale 1ns / 1ps

module mem_stage_tb();

    localparam  NBITS       =   32  ;
    localparam  MEM_SIZE    =   16  ;
    localparam  FBITS       =   3   ;

    reg     [NBITS-1:0]     i_ALU_result    ;
    reg     [NBITS-1:0]     i_rs2           ;
    reg     [FBITS-1:0]     i_size_control  ;
    reg     i_memread   ,   i_memwrite      ,
            i_clk       ,   i_rst           ;

    wire    [NBITS-1:0]     o_MEM_data      ;
    wire    [NBITS-1:0]     o_data_from_mem ;

    initial begin
        $dumpfile("mem_stage_tb.vcd"); $dumpvars;
        i_clk           =   1'b0    ;
        i_rst           =   1'b1    ;
        i_memread       =   1'b0    ;
        i_memwrite      =   1'b0    ;
        i_size_control  =   3'b010  ;   // word
        i_ALU_result    =   32'h0   ;
        i_rs2           =   32'h0   ;

        #10
        i_rst = 1'b0;

        // Store word at addr 0
        i_memwrite      =   1'b1        ;
        i_memread       =   1'b0        ;
        i_ALU_result    =   32'h0       ;
        i_rs2           =   32'h11223344;
        i_size_control  =   3'b010      ;
        #10

        // Store word at addr 1
        i_ALU_result    =   32'h1       ;
        i_rs2           =   32'hAABBCCDD;
        #10

        // Read word from addr 0
        i_memwrite      =   1'b0    ;
        i_memread       =   1'b1    ;
        i_ALU_result    =   32'h0   ;
        i_size_control  =   3'b010  ;
        #10

        // Read word from addr 1
        i_ALU_result    =   32'h1   ;
        #10

        // Store byte at addr 2
        i_memread       =   1'b0        ;
        i_memwrite      =   1'b1        ;
        i_ALU_result    =   32'h2       ;
        i_rs2           =   32'h000000FF;
        i_size_control  =   3'b000      ;   // byte
        #10

        // Unsigned load byte from addr 2
        i_memwrite      =   1'b0        ;
        i_memread       =   1'b1        ;
        i_size_control  =   3'b000      ;
        #10

        // Signed load byte from addr 2
        i_size_control  =   3'b100      ;
        #10

        // Store halfword at addr 3
        i_memread       =   1'b0        ;
        i_memwrite      =   1'b1        ;
        i_ALU_result    =   32'h3       ;
        i_rs2           =   32'h00008001;
        i_size_control  =   3'b001      ;   // halfword
        #10

        // Unsigned load halfword from addr 3
        i_memwrite      =   1'b0    ;
        i_memread       =   1'b1    ;
        i_size_control  =   3'b001  ;
        #10

        // Signed load halfword from addr 3
        i_size_control  =   3'b101  ;
        #10

        $finish;
    end

    always begin
        #5
        i_clk   =   ~i_clk  ;
    end

    MEM_stage #(
        .NBITS          (NBITS)         ,
        .MEM_SIZE       (MEM_SIZE)      ,
        .FBITS          (FBITS)
    ) dut (
        .i_ALU_result   (i_ALU_result)  ,
        .i_rs2          (i_rs2)         ,
        .i_size_control (i_size_control),
        .i_memread      (i_memread)     ,
        .i_memwrite     (i_memwrite)    ,
        .i_clk          (i_clk)         ,
        .i_rst          (i_rst)         ,
        .o_MEM_data     (o_MEM_data)    ,
        .o_data_from_mem(o_data_from_mem)
    );

endmodule
