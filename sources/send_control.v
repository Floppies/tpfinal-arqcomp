`timescale 1ns / 1ps

module send_control #(
    parameter   DM_ADDR_LENGTH      =       32      ,
    parameter   DM_MEM_SIZE         =       1024    ,
    parameter   DATA_WIDTH          =       32      ,
    parameter   RBITS               =       5       ,
    parameter   BANK_SIZE           =       32      ,
    parameter   REG_WIDTH           =       32      ,
    parameter   NBITS               =       32
)
(
    /*  Entradas    */
    input   wire    clk         ,           reset       ,
    input   wire    [DATA_WIDTH-1:0]        DM_Data     ,
    input   wire    [REG_WIDTH-1:0]         RB_Data     ,
    input   wire    [NBITS-1:0]             current_pc  ,
                                            clock_count ,
    input   wire    send_flag   ,           tx_done     ,
    
    /*  Salidas     */
    output  wire    [DM_ADDR_LENGTH-1:0]    DM_Addr     ,
    output  wire    [RBITS-1:0]             RB_Addr     ,
    output  wire    [NBITS-1:0]             tx_Data     ,
    output  wire    tx_start    ,           send_done
);

    /*      Estados     */
    localparam[4:0]
        WAIT            =       5'b00001        ,   //  Esperando
        SENDPC          =       5'b00010        ,   //  Mandando el PC
        SENDDM          =       5'b00100        ,   //  Mandando la DM
        SENDRB          =       5'b01000        ,   //  Mandando el RB
        SENDCLK         =       5'b10000        ;   //  Mandando el clock clount
        
    /*      Señales auxiliares   */

    reg     [4:0]   state_reg   ,   state_next  ;
    
    //  auxs de salidas
    reg     [DM_ADDR_LENGTH-1:0]    dm_addr_reg     ,   dm_addr_next    ;
    reg     [RBITS-1:0]             rb_addr_reg     ,   rb_addr_next    ;
    reg     [NBITS-1:0]             tx_data_reg     ,   tx_data_next    ;
    reg                             tx_start_reg    ,   tx_start_next   ;
    reg                             send_done_reg   ,   send_done_next  ;
    
    /*      Bloque de reset     */
    always  @(posedge clk, posedge reset)
    begin
        if  (reset)
            begin
                state_reg       <=      WAIT    ;
                dm_addr_reg     <=      0       ;
                rb_addr_reg     <=      0       ;
                tx_data_reg     <=      0       ;
                tx_start_reg    <=      0       ;
                send_done_reg   <=      0       ;
            end
        else
            begin
                state_reg       <=      state_next      ;
                dm_addr_reg     <=      dm_addr_next    ;
                rb_addr_reg     <=      rb_addr_next    ;
                tx_data_reg     <=      tx_data_next    ;
                tx_start_reg    <=      tx_start_next   ;
                send_done_reg   <=      send_done_next  ;
            end
    end
    
    /*      Bloque de logica del estado siguiente       */
    always  @*
    begin
        state_next      =       state_reg       ;
        dm_addr_next    =       dm_addr_reg     ;
        rb_addr_next    =       rb_addr_reg     ;
        tx_data_next    =       tx_data_reg     ;
        tx_start_next   =       tx_start_reg    ;
        send_done_next  =       send_done_reg   ;
        
        case    (state_reg)
            WAIT:
                begin
                    tx_data_next    =       0       ;
                    dm_addr_next    =       0       ;
                    rb_addr_next    =       0       ;
                    send_done_next  =       0       ;
                    if  (send_flag)
                        begin
                            tx_start_next   =   1       ;
                            state_next      =   SENDPC  ;
                        end
                    else
                        begin
                            tx_start_next   =   0       ;
                            state_next      =   WAIT    ;
                        end
                end
            SENDPC:
                begin
                    tx_data_next    =       current_pc  ;
                    dm_addr_next    =       0           ;
                    rb_addr_next    =       0           ;
                    send_done_next  =       0           ;
                    tx_start_next   =       1           ;
                    if  (tx_done)
                        begin
                            state_next      =       SENDCLK ;
                        end
                    else
                        begin
                            state_next      =       SENDPC  ;
                        end
                end
            SENDDM:
                begin
                    tx_data_next    =       DM_Data     ;
                    rb_addr_next    =       0           ;
                    send_done_next  =       0           ;
                    tx_start_next   =       1           ;
                    
                    if  (tx_done)
                        begin
                            if  (DM_Addr    >= DM_MEM_SIZE)
                                begin
                                    dm_addr_next    =   0       ;
                                    state_next      =   SENDRB  ;
                                end
                            else
                                begin
                                    dm_addr_next    =   dm_addr_reg + 1 ;
                                    state_next      =   SENDDM          ;
                                end
                        end
                    else
                        begin
                            dm_addr_next    =   dm_addr_reg ;
                            state_next      =   SENDDM      ;
                        end
                end
            SENDRB:
                begin
                    tx_data_next    =       RB_Data     ;
                    dm_addr_next    =       0           ;
                    send_done_next  =       0           ;
                    tx_start_next   =       1           ;
                    if  (tx_done)
                        begin
                            if  (rb_addr_reg >= BANK_SIZE)
                                begin
                                    rb_addr_next    =   0       ;
                                    state_next      =   SENDCLK ;
                                end
                            else
                                begin
                                    rb_addr_next    =   rb_addr_reg + 1 ;
                                    state_next      =   SENDRB          ;
                                end
                        end
                    else
                        begin
                            rb_addr_next    =   rb_addr_reg ;
                            state_next      =   SENDRB      ;
                        end
                end
            SENDCLK:
                begin
                    tx_data_next    =       clock_count ;
                    dm_addr_next    =       0           ;
                    rb_addr_next    =       0           ;
                    if  (tx_done)
                        begin
                            tx_start_next   =   0           ;
                            send_done_next  =   1           ;
                            state_next      =   WAIT        ;
                        end
                    else
                        begin
                            tx_start_next   =   1           ;
                            send_done_next  =   0           ;
                            state_next      =   SENDCLK     ;
                        end
                end
            default:
                begin
                    tx_data_next    =       0       ;
                    dm_addr_next    =       0       ;
                    rb_addr_next    =       0       ;
                    send_done_next  =       0       ;
                    tx_start_next   =       0       ;
                    state_next      =       WAIT    ;
                end
        endcase
    end
    
    //  Salida
    assign      DM_Addr         =       dm_addr_reg     ;
    assign      RB_Addr         =       rb_addr_reg     ;
    assign      tx_Data         =       tx_data_reg     ;
    assign      send_done       =       send_done_reg   ;
    assign      tx_start        =       tx_start_reg    ;
endmodule
