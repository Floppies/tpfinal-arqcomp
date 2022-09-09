`timescale 1ns / 1ps
`define STEPMODE    32'h10001000

module debug_controller #(
    parameter   IM_ADDR_LENGTH      =       32      ,
    parameter   IM_MEM_SIZE         =       5       ,
    parameter   INST_WIDTH          =       32      ,
    parameter   DM_ADDR_LENGTH      =       32      ,
    parameter   DM_MEM_SIZE         =       1024    ,
    parameter   DATA_WIDTH          =       32      ,
    parameter   RBITS               =       5       ,
    parameter   BANK_SIZE           =       32      ,
    parameter   REG_WIDTH           =       32      ,
    parameter   NBITS               =       32
    )
    (
    //Entradas
    input   wire    clk             ,   reset           ,
    input   wire    [NBITS-1:0]         rx_Data         ,
    input   wire    [REG_WIDTH-1:0]     RB_Data         ,
    input   wire    [DATA_WIDTH-1:0]    DM_Data         ,
    input   wire    rx_done         ,   halt_flag       ,
                                        tx_done         ,
    input   wire    [NBITS-1:0]         current_PC      ,
    input   wire    [NBITS-1:0]         clock_count     ,
    //Outputs
    output  wire    [IM_ADDR_LENGTH-1:0]    IM_Addr     ,
    output  wire    [DATA_WIDTH-1:0]        IM_Data     ,
    output  wire    [RBITS-1:0]             RB_Addr     ,
    output  wire    [DM_ADDR_LENGTH-1:0]    DM_Addr     ,
    output  wire    [NBITS-1:0]             tx_Data     ,
    output  wire                            tx_start    ,
    output  wire    clock_enable    ,       o_rst
    );
    
    /*      Estados     */
    localparam[2:0]
        RECVPROG        =       3'b000          ,   //  Recibiendo el programa
        RECVMODE        =       3'b001          ,   //  Recibiendo el modo de operacion
        RUNALL          =       3'b010          ,   //  Correr Programa (Modo Continuo)
        SENDPC          =       3'b011          ,   //  Mandando PC
        SENDDM          =       3'b100          ,   //  Mandando la DM
        SENDRB          =       3'b101          ,   //  Mandando el RB
        SENDCLK         =       3'b110          ,   //  Mandando el clk
        RUNSTEP         =       3'b111          ;   //  Correr un paso
        
    /*      Señales auxiliares   */

    //reg     [IM_ADDR_LENGTH-1:0]    IM_index    ;
    //reg     [DM_ADDR_LENGTH-1:0]    DM_index    ;
    reg     [2:0]   state_reg   ,   state_next  ;
    
    //  auxs de salidas
    reg     [IM_ADDR_LENGTH-1:0]    im_addr_reg     ,   im_addr_next    ;
    reg     [DATA_WIDTH-1:0]        im_data_reg     ,   im_data_next    ;
    reg     [RBITS-1:0]             rb_addr_reg     ,   rb_addr_next    ;
    reg     [NBITS-1:0]             tx_data_reg     ,   tx_data_next    ;
    reg     [DM_ADDR_LENGTH-1:0]    dm_addr_reg     ,   dm_addr_next    ;
    reg                             tx_start_reg    ,   tx_start_next   ;
    reg                             clk_enable_reg  ,   clk_enable_next ;
    reg                             o_reset_reg     ,   o_reset_next    ;
    
    //  auxs contadores
    reg     [IM_ADDR_LENGTH-1:0]    im_index_reg    ,   im_index_next   ;
    reg     [RBITS-1:0]             rb_index_reg    ,   rb_index_next   ;
    reg     [DM_ADDR_LENGTH-1:0]    dm_index_reg     ,  dm_index_next   ;
    
    /*      Bloque de reset     */
    always  @(posedge clk, posedge reset)
    begin
        if  (reset)
            begin
                state_reg       <=      RECVPROG        ;
                im_addr_reg     <=      0               ;
                im_data_reg     <=      0               ;
                rb_addr_reg     <=      0               ;
                tx_data_reg     <=      0               ;
                dm_addr_reg     <=      0               ;
                tx_start_reg    <=      0               ;
                clk_enable_reg  <=      0               ;
                o_reset_reg     <=      1               ;
                im_index_reg    <=      0               ;
                rb_index_reg    <=      0               ;
                dm_index_reg    <=      0               ;
            end
        else
            begin
                state_reg       <=      state_next      ;
                im_addr_reg     <=      im_addr_next    ;
                im_data_reg     <=      im_data_next    ;
                rb_addr_reg     <=      rb_addr_next    ;
                tx_data_reg     <=      tx_data_next    ;
                dm_addr_reg     <=      dm_addr_next    ;
                tx_start_reg    <=      tx_start_next   ;
                clk_enable_reg  <=      clk_enable_next ;
                o_reset_reg     <=      o_reset_next    ;
                im_index_reg    <=      im_index_next   ;
                rb_index_reg    <=      rb_index_next   ;
                dm_index_reg    <=      dm_index_next   ;
            end
    end
    
    /*      Bloque de logica del estado siguiente       */
    always  @*
    begin
        state_next      =       state_reg       ;
        im_addr_next    =       im_addr_reg     ;
        im_data_next    =       im_data_reg     ;
        rb_addr_next    =       rb_addr_reg     ;
        tx_data_next    =       tx_data_reg     ;
        dm_addr_next    =       dm_addr_reg     ;
        tx_start_next   =       tx_start_reg    ;
        clk_enable_next =       clk_enable_reg  ;
        o_reset_next    =       o_reset_reg     ;
        im_index_next   =       im_index_reg    ;
        rb_index_next   =       rb_index_reg    ;
        dm_index_next   =       dm_index_reg    ;
        
        case    (state_reg)
            RECVPROG:
                begin
                    im_addr_next    =   im_index_reg        ;       //  NO SE SI NO ESTA DE MAS alguno de estos registros?
                    im_data_next    =   rx_Data             ;
                    o_reset_next    =   1                   ;       //  CAPAZ ESTA DE MAS PORQUE LO HAGO EN EL RESET?
                    if  (rx_done)
                        begin
                            im_index_next   =   im_index_reg + 1    ;
                            if  (rx_Data    ==  32'hFFFFFFFF)               //  Ultima instruccion (HALT)
                                begin
                                    o_reset_next    =   0               ;
                                    state_next      =   RECVMODE        ;
                                end
                            else
                                begin
                                    state_next      =   RECVPROG        ;
                                end
                        end
                    // habra un else ACA?
                end
            RECVMODE:
                begin
                    if  (rx_done)
                        begin
                        if  (rx_Data    ==  "STEPMODE")         // NO SE SI SE USA ASI ?
                            begin
                                state_next      =   RUNSTEP     ;
                            end
                        else
                            begin
                                state_next      =   RUNALL      ;
                            end
                        end
                    else
                        begin
                            state_next      =   RECVMODE        ;
                        end
                end
            RUNALL:
                begin
                    clk_enable_next     =       1       ;
                    if  (halt_flag)                                 //  El programa llego a su fin
                        begin
                            state_next      =   SENDPC          ;
                        end
                    else
                        begin
                            state_next      =   RUNALL          ;
                        end
                end
            SENDPC:
                begin
                    clk_enable_next     =       0               ;
                    tx_data_next        =       current_PC      ;
                    tx_start_next       =       1               ;
                    if  (tx_done)                                   // Se termina de transmitir
                        begin
                            tx_start_next   =       0           ;
                            state_next      =       SENDDM      ;
                        end
                    else
                        begin
                            state_next      =       SENDPC      ;
                        end
                end
            SENDDM:
                begin
                    dm_addr_next        =       dm_index_reg    ;
                    tx_data_next        =       DM_Data         ;
                    tx_start_next       =       1               ;
                    if  (tx_done)                                   //  Se termina de transmitir
                        begin
                            tx_start_next   =   0       ;
                            if  (dm_addr_reg    ==  DM_MEM_SIZE)    //  Se llega al final de la memoria de datos
                                begin
                                    dm_addr_next    =   0               ;
                                    state_next      =   SENDRB          ;
                                end
                            else
                                begin
                                    dm_index_next   =   dm_index_reg + 1;
                                    state_next      =   SENDDM          ;
                                end
                        end
                    // Capaz que hay que poner un else aca
                end
            SENDRB:
                begin
                    rb_addr_next        =       rb_index_reg    ; 
                    tx_data_next        =       RB_Data         ;
                    tx_start_next       =       1               ;
                    if  (tx_done)                                   //  Se termina de transmitir
                        begin
                            tx_start_next   =   0       ;
                            if  (rb_addr_reg    ==  BANK_SIZE)      //  Se llega al final del banco de registros
                                begin
                                    rb_index_next   =   0               ;
                                    state_next      =   SENDCLK         ;
                                end
                            else
                                begin
                                    rb_index_next   =   rb_index_reg + 1;
                                    state_next      =   SENDRB          ;
                                end
                        end
                    // Capaz que hay que poner un else aca
                end
            SENDCLK:
                begin
                    tx_data_next        =       clock_count     ;
                    tx_start_next       =       1               ;
                    if  (tx_done)                                   //  Se termina de transmitir
                        begin
                            tx_start_next   =   0       ;
                            if  (halt_flag)                         //  Se termino el programa
                                begin
                                    state_next      =   RECVPROG        ;
                                end
                            else
                                begin
                                    state_next      =   RECVMODE        ;
                                end
                        end
                end
             RUNSTEP:
                begin
                    clk_enable_next     =       1       ;
                    state_next          =       SENDPC  ;
                end
        endcase
    end
    
    //  Salidas
    assign      tx_Data         =       tx_data_reg     ;
    assign      IM_Addr         =       im_addr_reg     ;
    assign      IM_Data         =       im_data_reg     ;
    assign      RB_Addr         =       rb_addr_reg     ;
    assign      DM_Addr         =       dm_addr_reg     ;
    assign      tx_start        =       tx_start_reg    ;
    assign      clock_enable    =       clk_enable_reg  ;
    assign      o_rst           =       o_reset_reg     ;
    
endmodule
