`timescale 1ns / 1ps

module controller_pipe_tb();

    //Local parameters
    localparam  NSBITS      =       8   ;
    
    //Entradas
    reg     [NSBITS-1:0]    opcode      ;
    
    //Salidas
    wire    reg_write   ,   alu_source  ,
            mem_write   ,   mem_read    ,
            beq ,   bne ,   jump        ,
            mem_to_reg  ,   link        ,
            jump_reg    ,   halt        ;
    wire    [1:0]           alu_op      ;
    
    initial begin
    $dumpfile("dump.vcd"); $dumpvars;
        #10 
        //R-Type
        opcode      =   8'b00110011 ;
        #10
        //I-Type
        opcode      =   8'b00010011 ;
        #10
        //Load
        opcode      =   8'b00000011 ;
        #10
        //Store
        opcode      =   8'b00100011 ;
        #10
        //BEQ
        opcode      =   8'b01100011 ;
        #10
        //BNE
        opcode      =   8'b11100011 ;
        #10
        //JAL
        opcode      =   8'b01101111 ;
        #10
        //JARL
        opcode      =   8'b01100111 ;
        #10
        //LUI
        opcode      =   8'b00110111 ;
        #10
        //HALT
        opcode      =   8'b11111111 ;
        #10
        $finish;
    end
    
    controller_pipe
    #(
        .NSBITS        (NSBITS)
    )ctrctrpp
    (
        .i_opcode       (opcode)        ,
        .Reg_write      (reg_write)     ,
        .ALU_source     (alu_source)    ,
        .Mem_write      (mem_write)     ,
        .ALU_op         (alu_op)        ,
        .Mem_to_Reg     (mem_to_reg)    ,
        .Mem_read       (mem_read)      ,
        .BEQ_flag       (beq)           ,
        .BNE_flag       (bne)           ,
        .Jump_flag      (jump)          ,
        .Jump_reg       (jump_reg)      ,
        .Halt_flag      (halt)          ,
        .Link_flag      (link)
    );

endmodule
