`timescale 1ns / 1ps

module MEM_WB_reg   #(
    parameter       NBITS   =   32      ,
    parameter       RBITS   =   5
)
(
    //Entradas
    input   wire    i_clk   ,       i_rst           ,
    input   wire    [NBITS-1:0]     MEM_result      ,   //Resultado de la ALU
    input   wire    [RBITS-1:0]     MEM_rd          ,   //Nombre del registro destino
    input   wire    [NBITS-1:0]     MEM_data        ,   //Datos de la memoria
    input   wire    MEM_regwrite,   MEM_memtoreg    ,
                                    MEM_haltflag    ,
    //Salidas
    output  reg     [NBITS-1:0]     WB_result       ,   //Resultado de la ALU
    output  reg     [RBITS-1:0]     WB_rd           ,   //Nombre del registro destino
    output  reg     [NBITS-1:0]     WB_data         ,   //Datos de la memoria
    output  reg     WB_regwrite,    WB_memtoreg     ,
                                    WB_haltflag
);

always  @(posedge i_clk)
    begin
        if  (i_rst)
        begin
            WB_result       <=      32'b0           ;
            WB_data         <=      32'b0           ;
            WB_rd           <=      5'b0            ;
            WB_regwrite     <=      0               ;
            WB_memtoreg     <=      0               ;
        end
        else
        begin
            WB_result       <=      MEM_result      ;
            WB_data         <=      MEM_data        ;
            WB_rd           <=      MEM_rd          ;
            WB_regwrite     <=      MEM_regwrite    ;
            WB_memtoreg     <=      MEM_memtoreg    ;
        end
    end

endmodule
