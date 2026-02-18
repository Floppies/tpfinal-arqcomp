`timescale 1ns / 1ps

module MEM_WB_reg   #(
    parameter       NBITS   =   32      ,
    parameter       RBITS   =   5
)
(
    //Entradas
    input   wire    i_clk   ,   i_rst   ,   flush   ,   cpu_en  ,
    input   wire    [NBITS-1:0]     MEM_result      ,   //ALU result
    input   wire    [RBITS-1:0]     MEM_rd          ,   //Register
    input   wire    [NBITS-1:0]     MEM_data        ,   //Mem data
    input   wire    [NBITS-1:0]     MEM_next_inst   ,   //PC+4
    input   wire    MEM_regwrite,   MEM_memtoreg    ,
                    MEM_halt    ,   MEM_link        ,
    //Salidas
    output  reg     [NBITS-1:0]     WB_result       ,   //ALU result
    output  reg     [RBITS-1:0]     WB_rd           ,   //Register
    output  reg     [NBITS-1:0]     WB_data         ,   //Mem data
    output  reg     [NBITS-1:0]     WB_next_inst    ,   //PC+4
    output  reg     WB_regwrite ,   WB_memtoreg     ,
                    WB_halt     ,   WB_link
);

always  @(posedge i_clk or posedge i_rst)
    begin
        if  (i_rst)
        begin
            WB_result       <=      32'b0           ;
            WB_data         <=      32'b0           ;
            WB_next_inst    <=      32'b0           ;
            WB_rd           <=      5'b0            ;
            WB_regwrite     <=      0               ;
            WB_memtoreg     <=      0               ;
            WB_link         <=      0               ;
            WB_halt         <=      0               ;
        end
        else if (cpu_en)
        begin
            WB_result       <=      flush   ?   32'b0       :   MEM_result      ;
            WB_data         <=      flush   ?   32'b0       :   MEM_data        ;
            WB_next_inst    <=      flush   ?   32'b0       :   MEM_next_inst   ;
            WB_rd           <=      flush   ?   5'b0        :   MEM_rd          ;
            WB_regwrite     <=      flush   ?   1'b0        :   MEM_regwrite    ;
            WB_memtoreg     <=      flush   ?   1'b0        :   MEM_memtoreg    ;
            WB_link         <=      flush   ?   1'b0        :   MEM_link        ;
            WB_halt         <=      flush   ?   1'b0        :   MEM_halt        ;
        end
    end

endmodule
