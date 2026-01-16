`timescale 10ns / 10ps

module ta_gen_tb;
    //Param
    localparam  MSB     =   32  ;

    //Inputs
    reg     [MSB-1:0]   current_pc      ;
    reg     [MSB-1:0]   rs1             ;
    reg     [MSB-1:0]   immediate       ;
    reg                 Jump_reg        ;
    
    //Output
    wire    [MSB-1:0]   target_address  ;

    initial begin
        $dumpfile("dump.vcd"); $dumpvars;

        // JAL (Jump_reg = 0): target = PC + imm
        current_pc =    32'h04;
        rs1        =    32'h10;
        immediate  =    32'h08;
        Jump_reg   =    1'b0;
        
        #10;
        // JALR (Jump_reg = 1): target = (rs1 + imm) & ~1
        current_pc =    32'h04;
        rs1        =    32'h01;
        immediate  =    32'h04;
        Jump_reg   =    1'b1;
        
        #10;
        // imm negativo (ejemplo)
        rs1        =    32'h20;
        immediate  =    32'hFFFFFFFC; // -4
        Jump_reg   =    1'b1;
        
        #10;
        Jump_reg   =    1'b0;

        $finish;
    end
    
    target_address_gen  #(
        .MSB        (MSB)
    ) TA_GEN (
        .current_pc     (current_pc)    ,
        .rs1            (rs1)           ,
        .immediate      (immediate)     ,
        .Jump_reg       (Jump_reg)      ,
        .target_address (target_address)
    );

endmodule