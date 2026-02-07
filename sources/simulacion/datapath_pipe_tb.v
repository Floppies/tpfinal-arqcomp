`timescale 10ns / 10ps

module datapath_pipe_tb();

    //Parametros
    localparam      MEM_SIZE        =   8   ;
    localparam      BANK_SIZE       =   32  ;
    localparam      NBITS           =   32  ;
    localparam      RBITS           =   5   ;
    
    //Entradas
    reg             i_clk       ,   i_rst       ;
    reg             debug_mode  ,   step_pulse  ;
    reg             dbg_imem_we             ;
    reg     [NBITS-1:0] dbg_imem_addr        ;
    reg     [NBITS-1:0] dbg_imem_data        ;
    reg     [RBITS-1:0] dbg_reg_index        ;
    reg     [NBITS-1:0] dbg_dmem_addr        ;

    //Salidas
    wire    [NBITS-1:0] dbg_reg_data         ;
    wire    [NBITS-1:0] dbg_dmem_data        ;
    wire    [NBITS-1:0] o_IF_inst            ;
    wire    [NBITS-1:0] o_IF_next_pc         ;
    wire    [NBITS-1:0] o_IF_pc              ;
    wire    [NBITS-1:0] o_ID_inst            ;
    wire    [NBITS-1:0] o_ID_next_pc         ;
    wire    [NBITS-1:0] o_ID_pc              ;
    wire    [NBITS-1:0] o_ID_imm             ;
    wire    [NBITS-1:0] o_ID_Rs1             ;
    wire    [NBITS-1:0] o_ID_Rs2             ;
    wire    [RBITS-1:0] o_ID_rd              ;
    wire    [NBITS-1:0] o_EX_result          ;
    wire    [NBITS-1:0] o_EX_Rs2             ;
    wire    [RBITS-1:0] o_EX_rd              ;
    wire    [NBITS-1:0] o_MEM_result         ;
    wire    [NBITS-1:0] o_MEM_data           ;
    wire    [RBITS-1:0] o_MEM_rd             ;
    wire    [NBITS-1:0] o_WB_data            ;
    wire    [RBITS-1:0] o_WB_rd              ;
    wire    [NBITS-1:0] o_inst_data          ;
    wire    [NBITS-1:0] o_reg_data           ;
    wire    [NBITS-1:0] o_mem_data           ;
    wire                o_haltflag           ;

    reg     [NBITS-1:0] hold_pc              ;
    
    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        i_clk       =       1       ;
        i_rst       =       1       ;
        debug_mode  =       0       ;
        step_pulse  =       0       ;
        dbg_imem_we =       0       ;
        dbg_imem_addr =     0       ;
        dbg_imem_data =     0       ;
        dbg_reg_index =     0       ;
        dbg_dmem_addr =     0       ;
        
        #10
        i_rst       =       0       ;

        // Run a few cycles in normal mode
        #40

        // Enter debug mode: CPU should hold
        debug_mode  =   1   ;
        #5
        hold_pc = o_IF_pc;
        #20
        if (o_IF_pc !== hold_pc)
            $display("ERROR: PC changed while debug_mode=1 without step_pulse");

        // Single-step the CPU
        step_pulse  =   1   ;
        #10
        step_pulse  =   0   ;
        #10
        if (o_IF_pc === hold_pc)
            $display("ERROR: PC did not advance on step_pulse");

        // Debug reads (addresses only, data depends on init)
        dbg_reg_index = 5'd1;
        dbg_dmem_addr = 32'd0;
        #10
        
        // Back to run mode
        debug_mode  =   0   ;
        #40

        $finish;
    end
    
    always begin
        #5
        i_clk       =       ~i_clk  ;
    end
    
    datapath_pipe
    #(
        .MEM_SIZE       (MEM_SIZE)      ,
        .BANK_SIZE      (BANK_SIZE)     ,
        .NBITS          (NBITS)         ,
        .RBITS          (RBITS)
    )DATAPATHPIPE
    (
        .i_clk          (i_clk)         ,
        .i_rst          (i_rst)         ,
        .debug_mode     (debug_mode)    ,
        .step_pulse     (step_pulse)    ,
        .dbg_imem_we    (dbg_imem_we)   ,
        .dbg_imem_addr  (dbg_imem_addr) ,
        .dbg_imem_data  (dbg_imem_data) ,
        .dbg_reg_index  (dbg_reg_index) ,
        .dbg_dmem_addr  (dbg_dmem_addr) ,
        .dbg_reg_data   (dbg_reg_data)  ,
        .dbg_dmem_data  (dbg_dmem_data) ,
        .o_IF_inst      (o_IF_inst)     ,
        .o_IF_next_pc   (o_IF_next_pc)  ,
        .o_IF_pc        (o_IF_pc)       ,
        .o_ID_inst      (o_ID_inst)     ,
        .o_ID_next_pc   (o_ID_next_pc)  ,
        .o_ID_pc        (o_ID_pc)       ,
        .o_ID_imm       (o_ID_imm)      ,
        .o_ID_Rs1       (o_ID_Rs1)      ,
        .o_ID_Rs2       (o_ID_Rs2)      ,
        .o_ID_rd        (o_ID_rd)       ,
        .o_EX_result    (o_EX_result)   ,
        .o_EX_Rs2       (o_EX_Rs2)      ,
        .o_EX_rd        (o_EX_rd)       ,
        .o_MEM_result   (o_MEM_result)  ,
        .o_MEM_data     (o_MEM_data)    ,
        .o_MEM_rd       (o_MEM_rd)      ,
        .o_WB_data      (o_WB_data)     ,
        .o_WB_rd        (o_WB_rd)       ,
        .o_inst_data    (o_inst_data)   ,
        .o_reg_data     (o_reg_data)    ,
        .o_mem_data     (o_mem_data)    ,
        .o_haltflag     (o_haltflag)
    );
    
endmodule
