module forwarding_unit  #(
    parameter   RBITS       =   5   ,
    parameter   FBITS       =   2
    )
    (
    //Entradas
    input   wire    [RBITS-1:0]     IF_ID_rs        ,
    input   wire    [RBITS-1:0]     IF_ID_rt        ,
    input   wire    [RBITS-1:0]     ID_EX_rd        ,
    input   wire    [RBITS-1:0]     EX_MEM_rd       ,
    input   wire    [RBITS-1:0]     MEM_WB_rd       ,
    input   wire                    ID_EX_regwrite  ,
    input   wire                    EX_MEM_regwrite ,
    input   wire                    MEM_WB_regwrite ,
    //Salidas
    output  wire    [FBITS-1:0]     forward_A       ,
    output  wire    [FBITS-1:0]     forward_B
    );
    
    localparam  [FBITS-1:0]
        REGBNK      =   2'b00   ,
        ALUSTG      =   2'b01   ,
        MEMSTG      =   2'b10   ,
        WBSTG       =   2'b11   ;
        
    reg [FBITS-1:0] fwdA_tmp, fwdB_tmp  ;
    
    //  Forwarding rs
    always  @(*)
    begin
        //  Forwarding from ALU Stage
        if  ((ID_EX_regwrite)&&(ID_EX_rd == IF_ID_rs))
            fwdA_tmp    =   ALUSTG  ;
        //  Forwarding from MEM Stage
        else if ((EX_MEM_regwrite)&&(EX_MEM_rd == IF_ID_rs))
            fwdA_tmp    =   MEMSTG  ;
        //  Forwarding from WB Stage
        else if ((MEM_WB_regwrite)&&(MEM_WB_rd == IF_ID_rs))
            fwdA_tmp    =   WBSTG   ;
        //  No forwarding
        else
            fwdA_tmp    =   REGBNK  ;
    end
    
    //  Forwarding rt
    always  @(*)
    begin
        //  Forwarding from ALU Stage
        if  ((ID_EX_regwrite)&&(ID_EX_rd == IF_ID_rt))
            fwdB_tmp    =   ALUSTG  ;
        //  Forwarding from MEM Stage
        else if ((EX_MEM_regwrite)&&(EX_MEM_rd == IF_ID_rt))
            fwdB_tmp    =   MEMSTG  ;
        //  Forwarding from WB Stage
        else if ((MEM_WB_regwrite)&&(MEM_WB_rd == IF_ID_rt))
            fwdB_tmp    =   WBSTG   ;
        //  No forwarding
        else
            fwdB_tmp    =   REGBNK  ;
    end
    
    assign  forward_A   =   fwdA_tmp    ;
    assign  forward_B   =   fwdB_tmp    ;
                
endmodule
