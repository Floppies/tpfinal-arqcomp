//Definicion de Macros para las instrucciones
`define Rtp     6'b000000
`define Addi    6'b001000
`define Andi    6'b001100
`define Beq     6'b000100
`define Bne     6'b000101
`define J       6'b000010
`define Jal     6'b000011
`define Lb      6'b100000
`define Lbu     6'b100100
`define Lh      6'b100001
`define Lhu     6'b100101
`define Lui     6'b001111
`define Lw      6'b100011
`define Lwu     6'b100111
`define Halt    6'b111111
`define Ori     6'b001101
`define Sb      6'b101000
`define Sh      6'b101001
`define Sw      6'b101011
`define Slti    6'b001010
`define Xori    6'b001110

module controller_pipe  #(
    //Parametros
    parameter                       FBITS   =   6   ,
    parameter                       INSBITS =   6
    )
    (
    //Entradas
    input   wire    [INSBITS-1:0]   opcode          ,
    input   wire    [FBITS-1:0]     i_funct         ,
    //Salidas
    output  reg                     Reg_write       ,
    output  reg                     ALU_source      ,
    output  reg                     Mem_write       ,
    output  reg     [2:0]           ALU_op          ,
    output  reg                     Mem_to_Reg      ,
    output  reg                     Mem_read        ,
    output  reg                     BEQ_flag        ,
    output  reg                     BNE_flag        ,
    output  reg                     Jump_flag       ,
    output  reg                     Halt_flag       ,
    output  reg     [1:0]           Reg_dst         ,
    output  reg     [1:0]           Select_Addr     ,
    output  reg     [4:0]           Size_control    ,
    output  reg                     Link_flag
    );
    
    localparam  [FBITS-1:0]
        JALR    =   6'b001001       ,
        JR      =   6'b001000       ;
    
    always @(*)
	begin  :   control
        Reg_write       =   0       ;
        ALU_source      =   0       ;
        Mem_write       =   0       ;
        ALU_op          =   3'b000  ;
        Mem_to_Reg      =   0       ;
        Mem_read        =   0       ;
        BEQ_flag        =   0       ;
        BNE_flag        =   0       ;
        Jump_flag       =   0       ;
        Reg_dst         =   2'b00   ;
        Select_Addr     =   2'b11   ;
        Size_control    =   5'b00000;
        Link_flag       =   0       ;
        
        case(opcode)
            `Rtp        :
                begin   :   RType
                    case(i_funct)
                        JALR    :   begin
                            Reg_write       =   1       ;
                            ALU_source      =   1       ;
                            Reg_dst         =   2'b10   ;
                            Select_Addr     =   2'b10   ;
                            Jump_flag       =   1       ;
                            Link_flag       =   1       ;
                        end
                        JR      :   begin
                            Jump_flag       =   1       ;
                            Select_Addr     =   2'b10   ;
                        end
                        default :   begin
                            Reg_write       =   1       ;
                            Reg_dst         =   2'b10   ;
                        end
                    endcase
                end
            `Addi       :   begin
                Reg_write       =   1           ;
                ALU_source      =   1           ;
                ALU_op          =   3'b001      ;
            end
            `Andi       :   begin
                Reg_write       =   1           ;
                ALU_source      =   1           ;
                ALU_op          =   3'b010      ;
            end
            `Beq        :   begin
                ALU_op          =   3'b110      ;
                BEQ_flag        =   1           ;
                Select_Addr     =   2'b01       ;
            end
            `Bne        :   begin
                ALU_op          =   3'b110      ;
                BNE_flag        =   1           ;
                Select_Addr     =   2'b01       ;
            end
            `J          :   begin
                Select_Addr     =   2'b00       ;
                Jump_flag       =   1           ;
            end
            `Jal        :   begin
                Reg_write       =   1           ;
                ALU_op          =   3'b001      ;
                ALU_source      =   1           ;
                Jump_flag       =   1           ;
                Reg_dst         =   2'b01       ;
                Select_Addr     =   2'b00       ;
                Link_flag       =   1           ;
            end
            `Lb         :   begin
                Reg_write       =   1           ;
                ALU_source      =   1           ;
                ALU_op          =   3'b001      ;
                Mem_to_Reg      =   1           ;
                Mem_read        =   1           ;
                Size_control    =   5'b01100    ;
            end
            `Lbu        :   begin
                Reg_write       =   1           ;
                ALU_source      =   1           ;
                ALU_op          =   3'b001      ;
                Mem_to_Reg      =   1           ;
                Mem_read        =   1           ;
                Size_control    =   5'b01000    ;
            end
            `Lh         :   begin
                Reg_write       =   1           ;
                ALU_source      =   1           ;
                ALU_op          =   3'b001      ;
                Mem_to_Reg      =   1           ;
                Mem_read        =   1           ;
                Size_control    =   5'b10100    ;
            end
            `Lhu        :   begin
                Reg_write       =   1           ;
                ALU_source      =   1           ;
                ALU_op          =   3'b001      ;
                Mem_to_Reg      =   1           ;
                Mem_read        =   1           ;
                Size_control    =   5'b10000    ;
            end
            `Lw         :   begin
                Reg_write       =   1           ;
                ALU_source      =   1           ;
                ALU_op          =   3'b001      ;
                Mem_to_Reg      =   1           ;
                Mem_read        =   1           ;
                Size_control    =   5'b11100    ;
            end
            `Lwu        :   begin
                Reg_write       =   1           ;
                ALU_source      =   1           ;
                ALU_op          =   3'b001      ;
                Mem_to_Reg      =   1           ;
                Mem_read        =   1           ;
                Size_control    =   5'b11000    ;
            end
            `Lui        :   begin
                Reg_write       =   1           ;
                ALU_source      =   1           ;
                ALU_op          =   3'b111      ;
            end
            `Halt       :   begin
                Halt_flag       =   1           ;
            end
            `Ori        :   begin
                Reg_write       =   1           ;
                ALU_source      =   1           ;
                ALU_op          =   3'b011      ;
            end
            `Sb         :   begin
                ALU_source      =   1           ;
                Mem_write       =   1           ;
                ALU_op          =   3'b001      ;
                Size_control    =   5'b00001    ;
            end
            `Sh         :   begin
                ALU_source      =   1           ;
                Mem_write       =   1           ;
                ALU_op          =   3'b001      ;
                Size_control    =   5'b00010    ;
            end
            `Sw         :   begin
                ALU_source      =   1           ;
                Mem_write       =   1           ;
                ALU_op          =   3'b001      ;
                Size_control    =   5'b00011    ;
            end
            `Slti       :   begin
                Reg_write       =   1           ;
                ALU_source      =   1           ;
                ALU_op          =   3'b101      ;
            end
            `Xori       :   begin
                Reg_write       =   1           ;
                ALU_source      =   1           ;
                ALU_op          =   3'b100      ;
            end
        endcase
    end

endmodule
