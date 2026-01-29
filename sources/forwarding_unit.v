module forwarding_unit  #(
    parameter   RBITS       =   5   ,
    parameter   FBITS       =   2
    )
    (
    //Entradas
    input   wire    [RBITS-1:0]     ID_EX_rs1       ,
    input   wire    [RBITS-1:0]     ID_EX_rs2       ,
    input   wire    [RBITS-1:0]     EX_MEM_rd       ,
    input   wire    [RBITS-1:0]     MEM_WB_rd       ,
    input   wire                    EX_MEM_regwrite ,
    input   wire                    MEM_WB_regwrite ,
    //Salidas
    output  wire    [FBITS-1:0]     forward_A       ,
    output  wire    [FBITS-1:0]     forward_B
    );
    
    localparam  [FBITS-1:0]
        REGBNK      =   2'b00   ,
        MEMSTG      =   2'b01   ,
        WBSTG       =   2'b01   ;
        
    reg [FBITS-1:0] fwdA_tmp, fwdB_tmp  ;
    
    //  Forwarding rs1 for EX Stage or for JARL
    always  @(*)
    begin
        //  Forwarding from MEM Stage
        if ((EX_MEM_regwrite)&&(EX_MEM_rd == ID_EX_rs1))
            fwdA_tmp    =   MEMSTG  ;
        //  Forwarding from WB Stage
        else if ((MEM_WB_regwrite)&&(MEM_WB_rd == ID_EX_rs1))
            fwdA_tmp    =   WBSTG   ;
        //  No forwarding
        else
            fwdA_tmp    =   REGBNK  ;
    end
    
    //  Forwarding rs2
    always  @(*)
    begin
        //  Forwarding from MEM Stage
        if ((EX_MEM_regwrite)&&(EX_MEM_rd == ID_EX_rs2))
            fwdB_tmp    =   MEMSTG  ;
        //  Forwarding from WB Stage
        else if ((MEM_WB_regwrite)&&(MEM_WB_rd == ID_EX_rs2))
            fwdB_tmp    =   WBSTG   ;
        //  No forwarding
        else
            fwdB_tmp    =   REGBNK  ;
    end
    
    assign  forward_A   =   fwdA_tmp    ;
    assign  forward_B   =   fwdB_tmp    ;
                
endmodule
