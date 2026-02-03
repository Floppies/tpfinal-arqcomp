module hazard_detection_unit    #(
    parameter                       RBITS   =   5
    )
    (
    //Inputs
    input   wire    [RBITS-1:0]     IF_ID_rs1           ,
    input   wire    [RBITS-1:0]     IF_ID_rs2           ,
    input   wire    [RBITS-1:0]     ID_EX_rd            ,
    input   wire                    ID_EX_memread       ,
    input   wire                    ID_EX_alusrc        ,
    input   wire                    ID_EX_memwrite      ,
    input   wire                    redirect            ,
    //Outputs
    output  reg     write_pc,       IFID_write          ,
                    IFID_flush,     IDEX_flush
    );

    //Auxiliary signals
    wire    ID_uses_rs2,    stall                       ;

    assign  ID_uses_rs2 =   (~ID_EX_alusrc) | ID_EX_memwrite  ;

    assign  stall   =   ID_EX_memread
                        && ( (ID_EX_rd == IF_ID_rs1)
                        || (ID_uses_rs2 && (ID_EX_rd == IF_ID_rs2)) );
    
    always  @(*)
    begin
        write_pc    =   1   ;
        IFID_write  =   1   ;
        IDEX_flush  =   0   ;
        IFID_flush  =   0   ;

        // Flush IF/ID on redirect (control hazard), but ONLY if not stalling
        IFID_flush  = redirect & (~stall)   ;

        // Stall has priority over redirect
        if (stall) begin
            write_pc    =   0   ;   //freeze PC
            IFID_write  =   0   ;   // freeze IF/ID
            IDEX_flush  =   1   ;   // bubble into EX (zero out control bits in ID/EX)
            IFID_flush  =   0   ;   // keep current ID instruction (do not kill it)
        end
    end
    
endmodule
