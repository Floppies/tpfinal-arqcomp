`timescale 1ns / 1ps


module debug_control    #(
    parameter   IM_ADDR_LENGTH      =       32      ,
    parameter   INST_WIDTH          =       32      ,
    parameter   NBITS               =       32
)
(
    /*  Entradas    */
    input   wire    clk         ,       reset       ,
    input   wire    [NBITS-1:0]         rx_Data     ,
    input   wire    rx_done     ,       halt_flag   ,
                                        send_done   ,
    /*  Salidas     */
    output  wire    enable      ,       o_reset     ,
                                        send_flag   ,
                                        IM_We       ,
    output  wire    [IM_ADDR_LENGTH-1:0]IM_Addr     ,
    output  wire    [INST_WIDTH-1:0]    IM_Data
);

    /*      Estados     */
    localparam[3:0]
        RECVPROG        =       4'b0001         ,   //  Recibiendo el programa
        RECVMODE        =       4'b0010         ,   //  Recibiendo el modo de operacion
        RUNPROG         =       4'b0100         ,   //  Correr Programa (Modo Continuo)
        SENDDATA        =       2'b1000         ;   //  Mandando todos los datos
        
    /*      Se�ales auxiliares   */

    reg     [3:0]   state_reg   ,   state_next  ;
    
    //  auxs de salidas
    reg     [IM_ADDR_LENGTH-1:0]    im_addr_reg     ,   im_addr_next    ;
    reg     [INST_WIDTH-1:0]        im_data_reg     ,   im_data_next    ;
    reg                             im_we_reg       ,   im_we_next      ;
    reg                             step_flag_reg   ,   step_flag_next  ;
    reg                             send_flag_reg   ,   send_flag_next  ;
    reg                             enable_reg      ,   enable_next     ;
    reg                             o_reset_reg     ,   o_reset_next    ;
    
    /*      Bloque de reset     */
    always  @(posedge clk, posedge reset)
    begin
        if  (reset)
            begin
                state_reg       <=      RECVPROG        ;
                im_addr_reg     <=      0               ;
                im_data_reg     <=      0               ;
                im_we_reg       <=      0               ;
                step_flag_reg   <=      0               ;
                send_flag_reg   <=      0               ;
                enable_reg      <=      0               ;
                o_reset_reg     <=      1               ;
            end
        else
            begin
                state_reg       <=      state_next      ;
                im_addr_reg     <=      im_addr_next    ;
                im_data_reg     <=      im_data_next    ;
                im_we_reg       <=      im_we_next      ;
                step_flag_reg   <=      step_flag_next  ;
                send_flag_reg   <=      send_flag_next  ;
                enable_reg      <=      enable_next     ;
                o_reset_reg     <=      o_reset_next    ;
            end
    end
    
    /*      Bloque de logica del estado siguiente       */
    always  @*
    begin
        state_next      =       state_reg       ;
        im_addr_next    =       im_addr_reg     ;
        im_data_next    =       im_data_reg     ;
        im_we_next      =       im_we_reg       ;
        step_flag_next  =       step_flag_reg   ;
        send_flag_next  =       send_flag_reg   ;
        enable_next     =       enable_reg      ;
        o_reset_next    =       o_reset_reg     ;
        
        case    (state_reg)
            RECVPROG:
                begin
                    im_data_next    =   rx_Data         ;
                    o_reset_next    =   1               ;
                    step_flag_next  =   0               ;
                    send_flag_next  =   0               ;
                    enable_next     =   0               ;
                    if  (rx_done)
                        begin
                            im_we_next      =   1           ;
                            if  (rx_Data    ==  32'hFFFFFFFF)               //  Ultima instruccion (HALT)
                                begin
                                    im_addr_next    =   0           ;
                                    im_we_next      =   0           ;
                                    state_next      =   RECVMODE    ;
                                end
                            else
                                begin
                                    im_addr_next    =   im_addr_reg + 1     ;
                                    state_next      =   RECVPROG            ;
                                end
                        end
                    else
                        begin
                            im_we_next      =   0           ;
                            im_addr_next    =   im_addr_reg ;
                            state_next      =   RECVPROG    ;
                        end
                end
            RECVMODE:
                begin
                    send_flag_next  =   0               ;
                    im_we_next      =   0               ;
                    o_reset_next    =   0               ;
                    im_addr_next    =   0               ;
                    im_data_next    =   0               ;
                    if  (rx_done)
                        begin
                            enable_next     =       1       ;
                            state_next      =       RUNPROG ;
                            if  (rx_Data    ==  32'h10001000)
                                begin
                                    step_flag_next  =   1       ;
                                end
                            else
                                begin
                                    step_flag_next  =   0       ;
                                end
                            end
                    else
                        begin
                            enable_next     =       0           ;
                            step_flag_next  =       0           ;
                            state_next      =       RECVMODE    ;
                        end
                end
            RUNPROG:
                begin
                    im_we_next      =   0               ;
                    o_reset_next    =   0               ;
                    im_addr_next    =   0               ;
                    im_data_next    =   0               ;
                    if  (step_flag_reg || halt_flag)        //No se si esta bien
                        begin
                            enable_next         =   0           ;
                            step_flag_next      =   0           ;
                            send_flag_next      =   1           ;
                            state_next          =   SENDDATA    ;
                        end
                    /*else if (halt_flag)
                        begin
                            enable_next         =   0           ;
                            step_flag_next      =   0           ;
                            send_flag_next      =   1           ;
                            state_next          =   SENDDATA    ;
                        end*/
                    else
                        begin
                            enable_next         =   1           ;
                            step_flag_next      =   0           ;
                            send_flag_next      =   0           ;
                            state_next          =   RUNPROG     ;
                        end
                end
            SENDDATA:
                begin
                    im_we_next      =   0               ;
                    o_reset_next    =   0               ;
                    im_addr_next    =   0               ;
                    im_data_next    =   0               ;
                    enable_next     =   0               ;
                    if  (send_done)                             // Se termina de transmitir
                        begin
                            send_flag_next  =       0       ;
                            if  (halt_flag)
                                begin
                                    o_reset_next    =   1           ;
                                    state_next      =   RECVPROG    ;
                                end
                            else
                                begin
                                    o_reset_next    =   0           ;
                                    state_next      =   RECVMODE    ;
                                end
                        end
                    else
                        begin
                            send_flag_next  =       1           ;
                            state_next      =       SENDDATA    ;
                        end
                end
            default:
                begin
                    enable_next     =   0           ;
                    im_we_next      =   0           ;
                    o_reset_next    =   1           ;
                    im_addr_next    =   0           ;
                    im_data_next    =   0           ;
                    state_next      =   RECVPROG    ;
                end
        endcase
    end
    
    //  Salidas
    assign      IM_Addr         =       im_addr_reg - 1 ;
    assign      IM_Data         =       im_data_reg     ;
    assign      IM_We           =       im_we_reg       ;
    //assign      step_flag       =       step_flag_reg   ;
    assign      send_flag       =       send_flag_reg   ;
    assign      enable          =       enable_reg      ;
    assign      o_reset         =       o_reset_reg     ;
    
endmodule
