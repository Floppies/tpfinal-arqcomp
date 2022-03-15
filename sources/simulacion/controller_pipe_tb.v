`timescale 1ns / 1ps

module controller_pipe_tb();

    //Local parameters
    localparam  FBITS       =       6   ;
    
    //Entradas
    reg     [FBITS-1:0]     opcode      ;
    reg     [FBITS-1:0]     funct       ;
    
    //Salidas
    wire    reg_write   ,   alu_source  ,
            mem_write   ,   mem_read    ,
            beq ,   bne ,   jump        ,
            mem_to_reg  ,   link        ;
    wire    [2:0]           alu_op      ;
    wire    [1:0]           reg_dst     ;
    wire    [1:0]           select_addr ;
    wire    [4:0]           size_control;
    
    initial begin
    $dumpfile("dump.vcd"); $dumpvars;
        #10
        opcode      =   6'b000000   ;
        funct       =   6'b100000   ;
        #10
        funct       =   6'b001001   ;
        #10
        funct       =   6'b001000   ;
        #10
        opcode      =   6'b001000   ;
        #10
        opcode      =   6'b001100   ;
        #10
        opcode      =   6'b000100   ;
        #10
        opcode      =   6'b000101   ;
        #10
        opcode      =   6'b000010   ;
        #10
        opcode      =   6'b000011   ;
        #10
        opcode      =   6'b100000   ;
        #10
        opcode      =   6'b100100   ;
        #10
        opcode      =   6'b100001   ;
        #10
        opcode      =   6'b100101   ;
        #10
        opcode      =   6'b001111   ;
        #10
        opcode      =   6'b100011   ;
        #10
        opcode      =   6'b100111   ;
        #10
        opcode      =   6'b001101   ;
        #10
        opcode      =   6'b101000   ;
        #10
        opcode      =   6'b101001   ;
        #10
        opcode      =   6'b001010   ;
        #10
        opcode      =   6'b101011   ;
        #10
        opcode      =   6'b001110   ;
        #10
        $finish;
    end
    
    controller_pipe
    #(
        .FBITS          (FBITS)         ,
        .INSBITS        (FBITS)
    )ctrctrpp
    (
        .opcode         (opcode)        ,
        .i_funct        (funct)         ,
        .Reg_write      (reg_write)     ,
        .ALU_source     (alu_source)    ,
        .Mem_write      (mem_write)     ,
        .ALU_op         (alu_op)        ,
        .Mem_to_Reg     (mem_to_reg)    ,
        .Mem_read       (mem_read)      ,
        .BEQ_flag       (beq)           ,
        .BNE_flag       (bne)           ,
        .Jump_flag      (jump)          ,
        .Reg_dst        (reg_dst)       ,
        .Select_Addr    (select_addr)   ,
        .Size_control   (size_control)  ,
        .Link_flag      (link)
    );

endmodule
