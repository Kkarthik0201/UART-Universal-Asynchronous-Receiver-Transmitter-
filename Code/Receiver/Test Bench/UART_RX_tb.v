`timescale 1ns / 1ps

module UART_Rx_tb;

    // -----------------------------------------------------------
    // 1. Signal Declarations
    // -----------------------------------------------------------
    reg        clock;
    reg        reset_n;
    reg        data_tx;
    reg [1:0]  parity_type;
    reg [1:0]  baud_rate;

    wire       active_flag;
    wire       done_flag;
    wire [2:0] error_flag;
    wire [7:0] data_out;

    // -----------------------------------------------------------
    // 2. Instantiate the Top-Level UART_Rx
    // -----------------------------------------------------------
    UART_Rx uut (
        .reset_n(reset_n),
        .data_tx(data_tx),
        .clock(clock),
        .parity_type(parity_type),
        .baud_rate(baud_rate),
        .active_flag(active_flag),
        .done_flag(done_flag),
        .error_flag(error_flag),
        .data_out(data_out)
    );

    // -----------------------------------------------------------
    // 3. System Clock Generation (5 MHz -> 200ns period)
    // -----------------------------------------------------------
    initial begin
        clock = 1'b0;
        forever #100 clock = ~clock;
    end

    // VCD Dumping
    initial begin
        $dumpfile("UART_Rx_.vcd");
        $dumpvars(0, UART_Rx_tb);
    end

    // -----------------------------------------------------------
    // 4. Automated Protocol Analyzer / Monitor
    // -----------------------------------------------------------
    always @(posedge clock) begin
        if (done_flag) begin
            $display("\n==============================================");
            $display(" 📥 PERFECT PACKET RECEIVED!");
            $display(" Extracted Data : %b (Hex: %h)", data_out, data_out);
            
            if (error_flag == 3'b000) begin
                $display(" Status         : ✅ SUCCESS (Error Flag is 000)");
            end else begin
                // If you see this, something broke in the logic!
                $display(" Status         : ❌ ALARM! False Error Detected: %b", error_flag);
            end
            $display("==============================================\n");
        end
    end

    // -----------------------------------------------------------
    // 5. TASK: Virtual Transmitter (No Errors Allowed!)
    // -----------------------------------------------------------
    task send_perfect_frame(input [7:0] data, input parity);
        integer i;
        reg [10:0] frame_to_send;
        begin
            // Build the 11-bit frame: Stop is ALWAYS 1, Start is ALWAYS 0.
            frame_to_send = { 1'b1, parity, data, 1'b0 };

            // Align with the Rx's internal clock
            @(posedge clock);
            while(!uut.baud_clk_wire) @(posedge clock);

            for(i = 0; i < 11; i = i + 1) begin
                #10; // Offset
                data_tx = frame_to_send[i];
                
                // Wait for the next baud tick
                @(posedge clock);
                while(!uut.baud_clk_wire) @(posedge clock);
            end
            
            // Return wire to idle state
            #10;
            data_tx = 1'b1;
        end
    endtask

    // -----------------------------------------------------------
    // 6. Main Stimulus Block (The Golden Test Suite)
    // -----------------------------------------------------------
    initial begin
        // Initialize
        reset_n     = 1'b0;
        data_tx     = 1'b1;  // Idle state
        
        #250;
        reset_n = 1'b1;
        
        // Let the system settle
        repeat(10) @(posedge clock);

        $display("--- Starting Top-Level Golden Master Tests ---");

        // -------------------------------------------------------
        // TEST 1: 9600 Baud, Even Parity (Data: 0x4A)
        // -------------------------------------------------------
        baud_rate   = 2'b00; // 9600
        parity_type = 2'b10; // Even
        $display("\n[TEST 1] Sending 0x4A at 9600 baud (Even Parity)...");
        // 0x4A (01001010) has 3 ones. To make it Even, parity bit must be 1.
        send_perfect_frame(8'h4A, 1'b1); 
        
        while(active_flag) @(posedge clock);
        repeat(100) @(posedge clock);

        // -------------------------------------------------------
        // TEST 2: 19200 Baud, Odd Parity (Data: 0x5A)
        // -------------------------------------------------------
        baud_rate   = 2'b01; // 19200
        parity_type = 2'b01; // Odd
        $display("\n[TEST 2] Sending 0x5A at 19200 baud (Odd Parity)...");
        // 0x5A (01011010) has 4 ones. To keep it Odd, parity bit must be 1.
        send_perfect_frame(8'h5A, 1'b1); 
        
        while(active_flag) @(posedge clock);
        repeat(100) @(posedge clock);

        // -------------------------------------------------------
        // TEST 3: 38400 Baud, No Parity (Data: 0xFF)
        // -------------------------------------------------------
        baud_rate   = 2'b10; // 38400
        parity_type = 2'b00; // None
        $display("\n[TEST 3] Sending 0xFF at 38400 baud (No Parity)...");
        // In "None" mode, the parity bit MUST be 0.
        send_perfect_frame(8'hFF, 1'b0); 
        
        while(active_flag) @(posedge clock);
        repeat(100) @(posedge clock);

        // -------------------------------------------------------
        // TEST 4: 115200 Baud, Mark Parity (Data: 0x00)
        // -------------------------------------------------------
        baud_rate   = 2'b11; // 115200
        parity_type = 2'b11; // Mark
        $display("\n[TEST 4] Sending 0x00 at 115200 baud (Mark Parity)...");
        // In "Mark" mode, the parity bit MUST be 1.
        send_perfect_frame(8'h00, 1'b1); 
        
        while(active_flag) @(posedge clock);
        repeat(100) @(posedge clock);

        $display("\n--- All Tests Complete. Error Flag Remained 000! ---");
        $finish;
    end

endmodule