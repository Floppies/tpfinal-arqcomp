`timescale 10ns / 10ps

module if_id_reg_tb();

    //Parametro
    localparam      MSB     =   32      ;
    
    //Entradas
    reg     [MSB-1:0]   if_nxt_pc   ,   if_inst     ,
                        if_current_pc                  ;
    reg     i_clk   ,   i_rst       ,   flush       ,
            cpu_en                                  ;
    reg     i_if_id_write                           ;
    //Salidas
    wire    [MSB-1:0]   id_nxt_pc   ,   id_inst     ,
                        id_current_pc                  ;
    
    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        i_clk       =       1       ;
        i_rst       =       1       ;   // Reset
        cpu_en      =       1       ;
        i_if_id_write =     1       ;
        flush       =       0       ;
        if_nxt_pc   =       4       ;
        if_inst     =       5       ;
        if_current_pc =     0       ;
        #5
        i_rst       =       0       ;
        #10
        if_nxt_pc   =       8       ;   // Save instruction
        if_inst     =       6       ;
        if_current_pc =     4       ;
        #5
        i_if_id_write =     0       ;   // Stall
        flush       =       1       ;
        #10
        i_if_id_write =     1       ;   // Enable and flush
        #10
        flush       =       0       ;
        #20
        $finish;
    end
    
    always begin
        #5
        i_clk       =       ~i_clk  ;
    end
    
    IF_ID_reg
    #(
        .MSB            (MSB)
    )ifidreg
    (
        .i_clk          (i_clk)     ,
        .i_rst          (i_rst)     ,
        .flush          (flush)     ,
        .cpu_en         (cpu_en)    ,
        .We             (i_if_id_write) ,
        .IF_next_pc     (if_nxt_pc) ,
        .IF_current_pc  (if_current_pc) ,
        .IF_inst        (if_inst)   ,
        .ID_next_pc     (id_nxt_pc) ,
        .ID_current_pc  (id_current_pc) ,
        .ID_inst        (id_inst)
    );
        
endmodule
