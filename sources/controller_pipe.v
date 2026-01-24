//Instruction type macros
`define Rtp     7'b0110011
`define Itp     7'b0010011
`define Loads   7'b0000011
`define Stores  7'b0100011
`define Branch  7'b1100011
`define Jal     7'b1101111
`define Jarl    7'b1100111
`define Lui     7'b0110111
`define Halt    7'b1111111

module controller_pipe  #(
    //Parameters
    parameter                       NSBITS  =   8
    )
    (
    //Inputs
    input   wire    [NSBITS-1:0]    i_opcode        ,   //funct3[0],opcode
    //Outputs
    output  reg                     Reg_write       ,
    output  reg                     ALU_source      ,
    output  reg                     Mem_write       ,
    output  reg     [1:0]           ALU_op          ,
    output  reg                     Mem_to_Reg      ,
    output  reg                     Mem_read        ,
    output  reg                     BEQ_flag        ,
    output  reg                     BNE_flag        ,
    output  reg                     Jump_flag       ,
    output  reg                     Jump_reg        ,
    output  reg                     Halt_flag       ,
    output  reg                     Link_flag
    );
    
    wire                    funct3  =   i_opcode[NSBITS-1]  ;
    wire    [NSBITS-2:0]    opcode  =   i_opcode[NSBITS-2:0];

    always @(*)
	begin  :   control
        Reg_write       =   0       ;
        ALU_source      =   0       ;
        Mem_write       =   0       ;
        ALU_op          =   2'b00   ;
        Mem_to_Reg      =   0       ;
        Mem_read        =   0       ;
        BEQ_flag        =   0       ;
        BNE_flag        =   0       ;
        Jump_flag       =   0       ;
        Jump_reg        =   0       ;
        Link_flag       =   0       ;
        Halt_flag       =   0       ;
        
        case(opcode)
            `Rtp        :   begin
                Reg_write       =   1           ;
                ALU_op          =   2'b10       ;
                ALU_source      =   0           ;
            end
            `Itp        :   begin
                Reg_write       =   1           ;
                ALU_source      =   1           ;
                ALU_op          =   2'b10       ;
            end
            `Loads      :   begin
                Reg_write       =   1           ;
                Mem_read        =   1           ;
                Mem_to_Reg      =   1           ;
                ALU_source      =   1           ;
                ALU_op          =   2'b00       ;
            end
            `Stores     :   begin
                Mem_write       =   1           ;
                ALU_source      =   1           ;
                ALU_op          =   2'b00       ;
            end
            `Branch     :   begin
                ALU_op          =   2'b01       ;
                ALU_source      =   0           ;
                if  (funct3)
                begin
                    BNE_flag    =   1           ;
                end
                else
                begin
                    BEQ_flag    =   1           ;
                end
            end
            `Jal        :   begin
                Reg_write       =   1           ;
                Jump_flag       =   1           ;
                Link_flag       =   1           ;
                ALU_source      =   1           ;
            end
            `Jarl       :   begin
                Reg_write       =   1           ;
                Jump_flag       =   1           ;
                Jump_reg        =   1           ;
                Link_flag       =   1           ;
                ALU_source      =   1           ;
            end
            `Lui        :   begin
                Reg_write       =   1           ;
                ALU_source      =   1           ;
                ALU_op          =   2'b11       ;
            end
            `Halt       :   begin
                Halt_flag       =   1           ;
            end
        endcase
    end

endmodule
