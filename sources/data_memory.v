`timescale 1ns / 1ps

module data_memory  #(

    parameter       MEM_SIZE        =   1024    ,
    parameter       WORD_WIDTH      =   32      ,
    parameter       ADDR_LENGTH     =   32      ,
    parameter       DATA_LENGTH     =   32
)
(
    //Entradas
    input   wire    i_clk   ,           i_rst           ,
    input   wire    [ADDR_LENGTH-1:0]   i_Addr          ,
    input   wire                        We              ,
    input   wire                        Re              ,
    input   wire    [4:0]               size_control    ,
    input   wire    [DATA_LENGTH-1:0]   i_Data          ,
    output  reg     [DATA_LENGTH-1:0]   o_Data
);

reg [WORD_WIDTH-1:0]    RAM_mem[0:MEM_SIZE-1]   ;

localparam  [1:0]
        BYTE        =   2'b01   ,
        HALF        =   2'b10   ;

//  Bloque que maneja la lectura de la RAM
always  @(i_clk)
    begin
        case(size_control[4:3])
        BYTE        :
        begin
            if(size_control[2])
                o_Data  <=  (RAM_mem[i_Addr][DATA_LENGTH-1] == 1) ? {24'hFFFFFF, RAM_mem[i_Addr][7:0]} : {24'h000000, RAM_mem[i_Addr][7:0]} ;
            else
                o_Data  <=  {24'h000000, RAM_mem[i_Addr][7:0]}  ;
        end
        HALF        :
        begin
            if(size_control[2])
                o_Data  <=  (RAM_mem[i_Addr][DATA_LENGTH-1] == 1) ? {16'hFFFFFF, RAM_mem[i_Addr][15:0]} : {16'h000000, RAM_mem[i_Addr][15:0]} ;
            else
                o_Data  <=  {16'h000000, RAM_mem[i_Addr][15:0]}  ;
        end
        default     :
        begin
            o_Data  <=  RAM_mem[i_Addr] ;
        end
        endcase       ;
    end
    
//  Bloque que maneja la escritura de la RAM
always @(negedge i_clk)
begin
    if  (We)
        case(size_control[1:0])
            BYTE    :   RAM_mem[i_Addr][7:0]    <=  i_Data[7:0] ;
            HALF    :   RAM_mem[i_Addr][15:0]   <=  i_Data[15:0];
            default :   RAM_mem[i_Addr]         <=  i_Data      ;
        endcase
end

endmodule
