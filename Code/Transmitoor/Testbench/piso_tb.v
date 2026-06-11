`timescale 1ns/1ps

module PisoTest;

    // --- Signal Declarations ---
    reg        clk;
    reg        baud_tick;
    reg        resetn;
    reg        send;
    reg        parity_bit;
    reg [7:0]  data_in;
    
    wire       data_tx;
    wire       active_flag;
    wire       done_flag;

    // --- Instantiate the Synchronous PISO ---
    PISO uut (
        .clk        (clk),
        .baud_tick  (baud_tick),
        .resetn     (resetn),
        .send       (send),
        .parity_bit (parity_bit),
        .data_in    (data_in),
        .data_tx    (data_tx),
        .active_flag(active_flag),
        .done_flag  (done_flag)
    );

    integer    pkt;
    integer    idx;
    reg [10:0] frame;

    // --- VCD Dumping ---
    initial begin
        $dumpfile("PisoTest.vcd");
        $dumpvars(0, PisoTest);
    end

    // --- Main System Clock (e.g., 50MHz = 20ns period) ---
    initial begin
        clk = 0;
        forever #10 clk = ~clk; 
    end

    // --- Baud Tick Generator (Simulates a fast BaudGen for testing) ---
    initial begin
        baud_tick = 0;
        forever begin
            repeat(4) @(posedge clk); // Wait 4 clocks
            baud_tick = 1;            // Pulse high for 1 clock
            @(posedge clk);
            baud_tick = 0;
        end
    end

    // --- Protocol Analyzer / Bit Sampler ---
    initial begin
        pkt = 0; idx = 0; frame = 0;
        @(posedge resetn);

        forever begin
            // 1. Wait for the module to become ACTIVE
            while (!active_flag) @(posedge clk);

            pkt   = pkt + 1;
            idx   = 0;
            frame = 0;

            $display("\n=== Packet %0d ===", pkt);
            $display("data_in=%b  parity_bit=%b", data_in, parity_bit);
            $display("Bit  | Value | Label");
            $display("-----|-------|------");

            // 2. Wait for the FIRST baud tick (which outputs the START bit)
            while (!baud_tick) @(posedge clk);
            #1; // Wait 1ns for the signal to settle after the clock edge
            
            frame[0] = data_tx;
            $display("[ 0] |   %b   | START", data_tx);
            idx = 1;

            // 3. Sample the remaining 10 bits on subsequent baud ticks
            repeat(10) begin
                @(posedge clk); // Move past the current tick
                while (!baud_tick) @(posedge clk); // Wait for the next tick
                #1; // Settle time
                
                frame[idx] = data_tx;
                case(idx)
                    9:       $display("[%2d] |   %b   | PARITY",    idx, data_tx);
                    10:      $display("[%2d] |   %b   | STOP",      idx, data_tx);
                    default: $display("[%2d] |   %b   | DATA[%0d]", idx, data_tx, idx-1);
                endcase
                idx = idx + 1;
            end

            $display("---------------------");
            $display("Frame  : %b", frame);
            $display("START  : %b", frame[0]);
            $display("DATA   : %b", frame[8:1]);
            $display("PARITY : %b", frame[9]);
            $display("STOP   : %b\n", frame[10]);

            // Wait for transmission to complete and go back to IDLE
            while (active_flag) @(posedge clk);
        end
    end

    // --- Stimulus Block ---
    initial begin
        resetn     = 0;
        send       = 0;
        data_in    = 8'b0;
        parity_bit = 0;
        
        #45; // Wait a bit
        resetn = 1;
        @(posedge clk);

        // Packet 1 - Even Parity
        data_in    = 8'b01001010;
        parity_bit = ^data_in;       // = 1
        
        // Pulse 'send' for exactly one clock cycle
        send = 1;
        @(posedge clk); 
        send = 0;
        
        // Wait for PISO to finish sending
        @(negedge active_flag);
        #100;

        // Packet 2 - Odd Parity
        data_in    = 8'b01011010;
        parity_bit = ~(^data_in);    // = 1
        
        send = 1;
        @(posedge clk); 
        send = 0;
        
        @(negedge active_flag);
        #100;
        
        $display("--- Simulation Complete ---");
        $finish;
    end

endmodule