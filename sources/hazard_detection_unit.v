module hazard_detection_unit    #(
    parameter                       RBITS   =   5
    )
    (
    //Entradas
    input   wire    [RBITS-1:0]     IF_ID_rs        ,
    input   wire    [RBITS-1:0]     IF_ID_rt        ,
    input   wire    [RBITS-1:0]     ID_EX_rd        ,
    input   wire                    ID_EX_memread   ,
    //Salidas
    output  reg     write_pc,       stall_ID
    );
    
    always  @(*)
    begin
        if((ID_EX_memread)&&((ID_EX_rd == IF_ID_rs)|| (ID_EX_rd == IF_ID_rt)))
        begin
            write_pc    =   0   ;
            stall_ID    =   1   ;
        end
        else
        begin
            write_pc    =   1   ;
            stall_ID    =   0   ;
        end
    end
    
endmodule
