`timescale 1ns / 1ps

module full_datapath_tb();

    localparam  MEM_SIZE    =   1024;
    localparam  BANK_SIZE   =   32  ;
    localparam  NBITS       =   32  ;
    localparam  RBITS       =   5   ;
    localparam  DBIT        =   8   ;
    localparam  BAUD_DIV    =   1   ;
    localparam  SB_TICK     =   16  ;
    localparam  BAUD_SIZ    =   8   ;
    localparam  IMEM_ADDR_BITS  =   10  ;
    localparam  DMEM_SNAP_WORDS =   0   ;
    localparam  USE_CLK_WIZ     =   0   ;

    localparam integer CLK_HALF    =   5;
    localparam integer BIT_CYCLES  =   BAUD_DIV * SB_TICK;
    localparam integer PIPE_WORDS  =   17;
    localparam integer REG_WORDS   =   32;
    localparam integer SNAP_BYTES  =   2 + (PIPE_WORDS + REG_WORDS + DMEM_SNAP_WORDS) * 4;

    // Top-state aliases
    localparam [2:0] T_IDLE      = 3'd0;

    // Commands
    localparam [7:0] CMD_LOAD = 8'h4C; // 'L'
    localparam [7:0] CMD_RUN  = 8'h52; // 'R'

    // Status bytes
    localparam [7:0] ACK_CMD_LOAD   = 8'h01;
    localparam [7:0] ACK_LOAD_DONE  = 8'h10;
    localparam [7:0] ACK_RUN_START  = 8'h12;
    localparam [7:0] ACK_RUN_DONE   = 8'h13;
    localparam [7:0] ACK_SNAP_START = 8'h14;
    localparam [7:0] ACK_SNAP_DONE  = 8'h15;

    // Inputs
    reg     i_clk_100mhz ;
    reg     i_rst   ;
    reg     i_rx    ;

    // Outputs
    wire    o_tx    ;
    wire    [2:0]   o_top_state ;
    wire    [3:0]   o_load_state;
    wire    [2:0]   o_snap_state;
    wire    [1:0]   o_tx_state  ;
    wire            o_diag_clk_locked;
    wire            o_diag_rst_sync;

    // UART monitor for DUT TX
    reg                 mon_tx_start;
    reg     [DBIT-1:0]  mon_tx_data ;
    wire                mon_tx;
    wire                mon_tx_done;
    wire                mon_rx_done;
    wire    [DBIT-1:0]  mon_rx_data;

    // UART byte sender (8N1)
    task send_uart_byte(input [7:0] b);
        integer i;
        begin
            // Start bit
            i_rx = 1'b0;
            repeat (BIT_CYCLES) @(posedge i_clk_100mhz);

            // Data bits LSB first
            for (i = 0; i < 8; i = i + 1) begin
                i_rx = b[i];
                repeat (BIT_CYCLES) @(posedge i_clk_100mhz);
            end

            // Stop bit
            i_rx = 1'b1;
            repeat (BIT_CYCLES) @(posedge i_clk_100mhz);
        end
    endtask

    task wait_top_state(input [2:0] st);
    begin
        while (o_top_state != st) @(posedge i_clk_100mhz);
    end
    endtask

    task wait_next_tx_byte;
        integer guard;
    begin
        guard = 0;

        if (mon_rx_done === 1'b1)
            @(posedge i_clk_100mhz);

        while (mon_rx_done !== 1'b1)
        begin
            @(posedge i_clk_100mhz);
            guard = guard + 1;
            if (guard > 200000)
            begin
                $display("ERROR: timeout waiting DUT TX byte");
                $fatal;
            end
        end
    end
    endtask

    task check_next_tx_byte(input [7:0] exp);
    begin
        wait_next_tx_byte();
        if (mon_rx_data !== exp)
        begin
            $display("ERROR: DUT TX=0x%02h expected 0x%02h", mon_rx_data, exp);
            $fatal;
        end
        @(negedge mon_rx_done);
    end
    endtask

    task skip_tx_bytes(input integer n);
        integer j;
    begin
        for (j = 0; j < n; j = j + 1)
        begin
            wait_next_tx_byte();
            @(negedge mon_rx_done);
        end
    end
    endtask

    initial begin
        // Timing-friendly dump: only top-level control pins/state LEDs
        $dumpfile("full_datapath_tb.vcd");
        $dumpvars(0,
            full_datapath_tb.i_clk_100mhz,
            full_datapath_tb.i_rst,
            full_datapath_tb.i_rx,
            full_datapath_tb.o_tx,
            full_datapath_tb.mon_rx_done,
            full_datapath_tb.mon_rx_data,
            full_datapath_tb.o_top_state,
            full_datapath_tb.o_load_state,
            full_datapath_tb.o_snap_state,
            full_datapath_tb.o_tx_state,
            full_datapath_tb.o_diag_clk_locked,
            full_datapath_tb.o_diag_rst_sync
        );
        i_clk_100mhz = 1'b0;
        i_rst   =   1'b1;
        i_rx    =   1'b1;
        mon_tx_start = 1'b0;
        mon_tx_data  = {DBIT{1'b0}};

        repeat (10) @(posedge i_clk_100mhz);
        i_rst = 1'b0;
        wait_top_state(T_IDLE);
        @(posedge i_clk_100mhz);

        // LOAD command
        send_uart_byte(CMD_LOAD);
        check_next_tx_byte(ACK_CMD_LOAD);

        // n_words = 5 (little-endian)
        send_uart_byte(8'h05);
        send_uart_byte(8'h00);

        // Program words (little-endian bytes):
        // 00000000010100000000000010010011 = 0x00500093
        send_uart_byte(8'h93);
        send_uart_byte(8'h00);
        send_uart_byte(8'h50);
        send_uart_byte(8'h00);
        // 00000000011100000000000100010011 = 0x00700113
        send_uart_byte(8'h13);
        send_uart_byte(8'h01);
        send_uart_byte(8'h70);
        send_uart_byte(8'h00);
        // 00000000001000001000000110110011 = 0x002081B3
        send_uart_byte(8'hB3);
        send_uart_byte(8'h81);
        send_uart_byte(8'h20);
        send_uart_byte(8'h00);
        // 00000000001100000010000000100011 = 0x00302023
        send_uart_byte(8'h23);
        send_uart_byte(8'h20);
        send_uart_byte(8'h30);
        send_uart_byte(8'h00);
        // 11111111111111111111111111111111 = 0xFFFFFFFF
        send_uart_byte(8'hFF);
        send_uart_byte(8'hFF);
        send_uart_byte(8'hFF);
        send_uart_byte(8'hFF);

        check_next_tx_byte(ACK_LOAD_DONE);

        // RUN command
        send_uart_byte(CMD_RUN);
        check_next_tx_byte(ACK_RUN_START);

        // RUN done + snapshot framing + payload + SNAP_DONE
        check_next_tx_byte(ACK_RUN_DONE);
        check_next_tx_byte(ACK_SNAP_START);
        check_next_tx_byte(8'hA5);
        check_next_tx_byte(8'h5A);
        skip_tx_bytes(SNAP_BYTES - 2);
        check_next_tx_byte(ACK_SNAP_DONE);

        $display("PASS: full_datapath LOAD/RUN + ACK/snapshot protocol verified");
        repeat (100) @(posedge i_clk_100mhz);
        $finish;
    end

    always begin
        #CLK_HALF i_clk_100mhz = ~i_clk_100mhz;
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
        .DMEM_SNAP_WORDS(DMEM_SNAP_WORDS),
        .USE_CLK_WIZ     (USE_CLK_WIZ)
    )DUT
    (
        .i_clk_100mhz(i_clk_100mhz),
        .i_rst      (i_rst)     ,
        .i_rx       (i_rx)      ,
        .o_tx       (o_tx)      ,
        .o_top_state(o_top_state),
        .o_load_state(o_load_state),
        .o_snap_state(o_snap_state),
        .o_tx_state (o_tx_state),
        .o_diag_clk_locked(o_diag_clk_locked),
        .o_diag_rst_sync(o_diag_rst_sync)
    );

    uart_unit #(
        .SB_TICK    (SB_TICK),
        .BAUD_DIV   (BAUD_DIV),
        .BAUD_SIZ   (BAUD_SIZ),
        .DBIT       (DBIT)
    ) UART_MON (
        .clk        (i_clk_100mhz),
        .reset      (i_rst),
        .rx         (o_tx),
        .tx_start   (mon_tx_start),
        .tx_Data    (mon_tx_data),
        .tx         (mon_tx),
        .tx_done    (mon_tx_done),
        .rx_done    (mon_rx_done),
        .rx_Data    (mon_rx_data)
    );

endmodule
