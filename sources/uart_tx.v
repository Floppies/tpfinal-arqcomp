`timescale 10ns / 10ns

module uart_tx  #(
        parameter       DBIT    =   8   ,   //  Cantidad de bits
        parameter       SB_TICK =   16
    )
    (
        input   wire    clk,    reset   ,
        input   wire    tx_start, s_tick,   //  Entrada que habilita la transmision y otra que da los pulsos del baud generator
        input   wire    [DBIT-1:0]  din ,
        output  reg     tx_done         ,   //  Se?al de final de la transmision
        output  wire    tx                  // Trama UART de salida
    );
    
    //  Declaracion de estados
    localparam[1:0]
        IDLE        =   2'b00           ,   //  No esta habilitado
        START       =   2'b01           ,   //  Envia el bit de START
        DATA        =   2'b10           ,   //  Envia los bits de datos
        STOP        =   2'b11           ;   //  Envia el o los bits de STOP
        
    //  Declaracion de se;ales
    reg [1:0]   state_reg,  state_next  ;   //  Estado actual y proximo
    reg [3:0]   s_reg,      s_next      ;   //  Contadores de ticks
    reg [2:0]   n_reg,      n_next      ;   //  Contadores de bits
    reg [7:0]   b_reg,      b_next      ;   //  Indices del regristro de entrada
    reg         tx_reg,     tx_next     ;   //  Registro auxiliar de la salida
    
    //  Logica de la memoria
    always  @(posedge clk, posedge reset)
        if  (reset)
            begin
                state_reg   <=  IDLE    ;
                s_reg       <=  0       ;
                n_reg       <=  0       ;
                b_reg       <=  0       ;
                tx_reg      <=  1'b1    ;
            end
        else
            begin
                state_reg   <=  state_next  ;
                s_reg       <=  s_next  ;
                n_reg       <=  n_next  ;
                b_reg       <=  b_next  ;
                tx_reg      <=  tx_next ;
            end
    
    //  Logica de proximo estado y la salida
    always  @*
    begin
        state_next      =   state_reg   ;
        tx_done         =   1'b0        ;
        s_next          =   s_reg       ;
        n_next          =   n_reg       ;
        b_next          =   b_reg       ;
        tx_next         =   tx_reg      ;
        
        case    (state_reg)
            IDLE:
                begin
                    tx_next     =   1'b1            ;   //  Salida en alto que muestra que no se estan enviando datos por dise?o
                    if  (tx_start)                      //  Inicia la transmision
                        begin
                            state_next  =   START   ;
                            s_next      =   0       ;
                            b_next      =   din     ;
                        end
                end
            START:
                begin
                    tx_next     =   1'b0            ;   //  Bit de start
                    if  (s_tick)
                        if  (s_reg==15)
                            begin
                                state_next  =   DATA;
                                s_next      =   0   ;
                                n_next      =   0   ;
                            end
                        else
                            s_next  =   s_reg + 1   ;
                end
            DATA:
                begin
                    tx_next     =   b_reg[0]        ;   //  Envia el primer bit
                    if  (s_tick)
                        if  (s_reg==15)
                            begin
                                s_next      =   0   ;
                                b_next  =   b_reg>>1;   //  Se corre al siguiente bit
                                if  (n_reg == (DBIT - 1))
                                    state_next  =   STOP    ;   //  Cuando se llega al numero de bits del dato, se termina la transmision
                                else
                                    n_next  =   n_reg + 1   ;
                            end
                        else
                            s_next  =   s_reg + 1   ;
                end
            STOP:
                begin
                    tx_next     =   1'b1            ;   //  Bit de STOP
                    if  (s_tick)
                        if  (s_reg==(SB_TICK-1))
                            begin
                                state_next  =   IDLE;
                                tx_done     =   1'b1;
                            end
                        else
                            s_next  =   s_reg + 1   ;
                end
        endcase
    end
    
    //  Salida
    assign  tx  =   tx_reg  ;
        
endmodule