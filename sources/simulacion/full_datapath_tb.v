`timescale 1ns / 1ps

module full_datapath_tb();

    localparam  MEM_SIZE    =   1024;
    localparam  BANK_SIZE   =   32  ;
    localparam  NBITS       =   32  ;
    localparam  RBITS       =   5   ;
    localparam  DBIT        =   8   ;
    localparam  BAUD_DIV    =   163 ;
    localparam  SB_TICK     =   16  ;
    localparam  BAUD_SIZ    =   8   ;
    localparam  IMEM_ADDR_BITS  =   10  ;
    localparam  DMEM_SNAP_WORDS =   0   ;

    localparam integer CLK_HALF    =   5;
    localparam integer BIT_CYCLES  =   BAUD_DIV * SB_TICK;

    // Inputs
    reg     i_clk   ;
    reg     i_rst   ;
    reg     i_rx    ;

    // Outputs
    wire    o_tx    ;
    wire    [2:0]   o_top_state ;
    wire    [3:0]   o_load_state;
    wire    [2:0]   o_snap_state;
    wire    [1:0]   o_tx_state  ;

    // UART byte sender (8N1)
    task send_uart_byte(input [7:0] b);
        integer i;
        begin
            // Start bit
            i_rx = 1'b0;
            repeat (BIT_CYCLES) @(posedge i_clk);

            // Data bits LSB first
            for (i = 0; i < 8; i = i + 1) begin
                i_rx = b[i];
                repeat (BIT_CYCLES) @(posedge i_clk);
            end

            // Stop bit
            i_rx = 1'b1;
            repeat (BIT_CYCLES) @(posedge i_clk);
        end
    endtask

    initial begin
        $dumpfile("full_datapath_tb.vcd"); $dumpvars;
        i_clk   =   1'b0;
        i_rst   =   1'b1;
        i_rx    =   1'b1;

        repeat (10) @(posedge i_clk);
        i_rst = 1'b0;

        // LOAD command: 'L' (0x4C)
        send_uart_byte(8'h4C);
        // n_words = 5 (little-endian)
        send_uart_byte(8'h05);
        send_uart_byte(8'h00);

        // Word 0: 0x00500093 (addi x1,x0,5)
        send_uart_byte(8'h93);
        send_uart_byte(8'h00);
        send_uart_byte(8'h50);
        send_uart_byte(8'h00);
        // Word 1: 0x00700113 (addi x2,x0,7)
        send_uart_byte(8'h13);
        send_uart_byte(8'h01);
        send_uart_byte(8'h70);
        send_uart_byte(8'h00);
        // Word 2: 0x002081B3 (add x3,x1,x2)
        send_uart_byte(8'hB3);
        send_uart_byte(8'h81);
        send_uart_byte(8'h20);
        send_uart_byte(8'h00);
        // Word 3: 0x00302023 (sw x3,0(x0))
        send_uart_byte(8'h23);
        send_uart_byte(8'h20);
        send_uart_byte(8'h30);
        send_uart_byte(8'h00);
        // Word 4: 0xFFFFFFFF (halt)
        send_uart_byte(8'hFF);
        send_uart_byte(8'hFF);
        send_uart_byte(8'hFF);
        send_uart_byte(8'hFF);

        // RUN command: 'R' (0x52)
        send_uart_byte(8'h52);

        // Wait some time for execution
        repeat (20000) @(posedge i_clk);
        $finish;
    end

    always begin
        #CLK_HALF i_clk = ~i_clk;
    end

    full_datapath #(
        .MEM_SIZE       (MEM_SIZE)      ,
        .BANK_SIZE      (BANK_SIZE)     ,
        .NBITS          (NBITS)         ,
        .RBITS          (RBITS)         ,
        .BAUD_DIV       (BAUD_DIV)      ,
        .BAUD_SIZ       (BAUD_SIZ)      ,
        .SB_TICK        (SB_TICK)       ,
        .DBIT           (DBIT)          ,
        .IMEM_ADDR_BITS (IMEM_ADDR_BITS),
        .DMEM_SNAP_WORDS(DMEM_SNAP_WORDS)
    )DUT
    (
        .i_clk      (i_clk)     ,
        .i_rst      (i_rst)     ,
        .i_rx       (i_rx)      ,
        .o_tx       (o_tx)      ,
        .o_top_state(o_top_state),
        .o_load_state(o_load_state),
        .o_snap_state(o_snap_state),
        .o_tx_state (o_tx_state)
    );

endmodule
