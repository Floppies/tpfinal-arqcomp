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
    input   wire                        cpu_en          ,
    input   wire    [2:0]               size_control    ,
    input   wire    [DATA_LENGTH-1:0]   i_Data          ,
    output  reg     [DATA_LENGTH-1:0]   o_Data
);

localparam integer ADDR_IDX_BITS = $clog2(MEM_SIZE);
wire [ADDR_IDX_BITS-1:0] addr_idx;
assign addr_idx = i_Addr[ADDR_IDX_BITS-1:0];
(* ram_style = "block" *) reg [WORD_WIDTH-1:0] RAM_mem[0:MEM_SIZE-1];

localparam  [1:0]
        BYTE        =   2'b00   ,
        HALF        =   2'b01   ;

//  Bloque que maneja la escritura (posedge)
always @(posedge i_clk)
begin
    if  (cpu_en && We)
        case(size_control[1:0])
            BYTE    :   RAM_mem[addr_idx][7:0]    <=  i_Data[7:0] ;
            HALF    :   RAM_mem[addr_idx][15:0]   <=  i_Data[15:0];
            default :   RAM_mem[addr_idx]         <=  i_Data      ;
        endcase
end

//  Bloque que maneja la lectura (combinacional)
always  @(*)
begin
    if (i_rst)
        o_Data = {DATA_LENGTH{1'b0}};
    else
        if (!Re)
            o_Data = {DATA_LENGTH{1'b0}};
        else
            case(size_control[1:0])
                BYTE    :
                    if(size_control[2])
                        o_Data  =  (RAM_mem[addr_idx][7] == 1) ? {24'hFFFFFF, RAM_mem[addr_idx][7:0]} : {24'h000000, RAM_mem[addr_idx][7:0]} ;
                    else
                        o_Data  =  {24'h000000, RAM_mem[addr_idx][7:0]}  ;
                HALF    :
                    if(size_control[2])
                        o_Data  =  (RAM_mem[addr_idx][15] == 1) ? {16'hFFFF, RAM_mem[addr_idx][15:0]} : {16'h0000, RAM_mem[addr_idx][15:0]} ;
                    else
                        o_Data  =  {16'h0000, RAM_mem[addr_idx][15:0]}  ;
                default :
                    o_Data  =  RAM_mem[addr_idx] ;
            endcase
end

endmodule
