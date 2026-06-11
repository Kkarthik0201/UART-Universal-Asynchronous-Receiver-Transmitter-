`timescale 1ns / 1ps

module UART_tb;

    //-------------------------------------
    // Testbench signals
    //-------------------------------------
    reg        reset_n_tb;
    reg        send_tb;
    reg        clock_tb;
    reg  [1:0] parity_type_tb;
    reg  [1:0] baud_rate_tb;
    reg  [7:0] data_in_tb;

    wire        tx_active_flag_tb;
    wire        tx_done_flag_tb;
    wire        rx_active_flag_tb;
    wire        rx_done_flag_tb;
    wire [7:0]  data_out_tb;
    wire [2:0]  error_flag_tb;

    //-------------------------------------
    // DUT instantiation
    //-------------------------------------
    UART dut (
        .reset_n      (reset_n_tb),
        .send         (send_tb),
        .clock        (clock_tb),
        .parity_type  (parity_type_tb),
        .baud_rate    (baud_rate_tb),
        .data_in      (data_in_tb),
        .tx_active_flag (tx_active_flag_tb),
        .tx_done_flag   (tx_done_flag_tb),
        .rx_active_flag (rx_active_flag_tb),
        .rx_done_flag   (rx_done_flag_tb),
        .data_out     (data_out_tb),
        .error_flag   (error_flag_tb)
    );

    //-------------------------------------
    // Clock generation - 100 MHz
    //-------------------------------------
    initial clock_tb = 0;
    always #5 clock_tb = ~clock_tb;

    //-------------------------------------
    // $monitor - fires on any signal change
    //-------------------------------------
    initial begin
        $monitor($time,
            "   The Outputs:  Data Out = %h  Error Flag = %b  Tx Active Flag = %b  Tx Done Flag = %b  Rx Active Flag = %b  Rx Done Flag = %b  The Inputs:   Reset = %b  Send = %b  Data In = %h  Parity Type = %b  Baud Rate = %b ",
            data_out_tb[7:0],
            error_flag_tb[2:0],
            tx_active_flag_tb,
            tx_done_flag_tb,
            rx_active_flag_tb,
            rx_done_flag_tb,
            reset_n_tb,
            send_tb,
            data_in_tb[7:0],
            parity_type_tb[1:0],
            baud_rate_tb[1:0]
        );
    end

    //-------------------------------------
    // Test sequence
    //-------------------------------------
    initial begin

        // ---------- initialise ----------
        reset_n_tb     = 0;
        send_tb        = 0;
        data_in_tb     = 8'h00;
        parity_type_tb = 2'b00;
        baud_rate_tb   = 2'b00;

        // ---------- release reset -------
        #50;
        reset_n_tb = 1;

        // ================================
        // TEST 1 - No parity  |  data = A5
        // ================================
        #20;
        data_in_tb     = 8'hA5;
        parity_type_tb = 2'b00;          // NONE

        @(posedge clock_tb);
        send_tb = 1;
        @(posedge clock_tb);
        send_tb = 0;

        wait (rx_done_flag_tb);
        #20;

        $display("\n--- TEST 1 COMPLETE ---");
        $display("  Sent     = 0x%h", 8'hA5);
        $display("  Received = 0x%h", data_out_tb);
        $display("  Parity   = NONE");
        $display("  Error    = %b", error_flag_tb);

        // ================================
        // TEST 2 - Even parity  |  data = 3C
        // ================================
        #100;
        data_in_tb     = 8'h3C;
        parity_type_tb = 2'b01;          // EVEN

        @(posedge clock_tb);
        send_tb = 1;
        @(posedge clock_tb);
        send_tb = 0;

        wait (rx_done_flag_tb);
        #20;

        $display("\n--- TEST 2 COMPLETE ---");
        $display("  Sent     = 0x%h", 8'h3C);
        $display("  Received = 0x%h", data_out_tb);
        $display("  Parity   = EVEN");
        $display("  Error    = %b", error_flag_tb);

        // ================================
        // TEST 3 - Odd parity  |  data = F0
        // ================================
        #100;
        data_in_tb     = 8'hF0;
        parity_type_tb = 2'b10;          // ODD

        @(posedge clock_tb);
        send_tb = 1;
        @(posedge clock_tb);
        send_tb = 0;

        wait (rx_done_flag_tb);
        #20;

        $display("\n--- TEST 3 COMPLETE ---");
        $display("  Sent     = 0x%h", 8'hF0);
        $display("  Received = 0x%h", data_out_tb);
        $display("  Parity   = ODD");
        $display("  Error    = %b", error_flag_tb);

        // ================================
        // TEST 4 - Mark parity  |  data = 55
        // ================================
        #100;
        data_in_tb     = 8'h55;
        parity_type_tb = 2'b11;          // MARK (parity bit always 1)

        @(posedge clock_tb);
        send_tb = 1;
        @(posedge clock_tb);
        send_tb = 0;

        wait (rx_done_flag_tb);
        #20;

        $display("\n--- TEST 4 COMPLETE ---");
        $display("  Sent     = 0x%h", 8'h55);
        $display("  Received = 0x%h", data_out_tb);
        $display("  Parity   = MARK");
        $display("  Error    = %b", error_flag_tb);

        // ================================
        // Final status
        // ================================
        #100;
        $display("\n========== FINAL STATUS ==========");
        $display("  TX Active = %b", tx_active_flag_tb);
        $display("  TX Done   = %b", tx_done_flag_tb);
        $display("  RX Active = %b", rx_active_flag_tb);
        $display("  RX Done   = %b", rx_done_flag_tb);
        $display("  Error     = %b", error_flag_tb);
        $display("==================================\n");

        #100;
        $finish;
    end

endmodule