`timescale 1ns/1ps

module UART_TX_tb;

    reg clk;
    reg resetn;
    reg send;
    reg [1:0] baud_rate;
    reg [1:0] parity_type;
    reg [7:0] data_in;
    
    wire data_tx;
    wire active_flag;
    wire done_flag;

    // Instantiate Top-Level Module
    UART_TX uut(
        .clk        (clk),
        .resetn     (resetn),
        .send       (send),
        .baud_rate  (baud_rate),
        .parity_type(parity_type),
        .data_in    (data_in),
        .data_tx    (data_tx),
        .active_flag(active_flag),
        .done_flag  (done_flag)
    );

    initial begin
        $dumpfile("UART_TX.vcd");
        $dumpvars(0, UART_TX_tb);
    end

    // Declarations for Sampler
    integer    pkt;
    integer    idx;
    reg [10:0] frame;

    // -----------------------------------------------------------
    // System clock: 5MHz -> 200ns period (Matches BaudGen math)
    // -----------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #100 clk = ~clk;
    end

    initial begin
        $monitor($time,
        " data_tx=%b active_flag=%b done_flag=%b send=%b resetn=%b parity_type=%b baud_rate=%b data_in=%b",
        data_tx, active_flag, done_flag, send, resetn, parity_type, baud_rate, data_in);
    end

    // -----------------------------------------------------------
    // Synchronous Bit Sampler (Protocol Analyzer)
    // -----------------------------------------------------------
    initial begin
        pkt = 0; idx = 0; frame = 0;
        @(posedge resetn);

        forever begin
            // 1. Wait for module to become active
            while (!active_flag) @(posedge clk);

            pkt   = pkt + 1;
            idx   = 0;
            frame = 0;

            $display("\n=== Packet %0d ===", pkt);
            $display("data_in=%b | parity_type=%b | baud_rate=%b", data_in, parity_type, baud_rate);
            $display("Bit  | Value | Label");
            $display("-----|-------|------");

            // 2. Wait for the FIRST baud tick (this outputs the START bit)
            // Note: We "peek" into the uut hierarchy to see the internal baud_tick wire
            while (!uut.baud_tick) @(posedge clk);
            #1; // Settle time
            
            frame[0] = data_tx;
            $display("[ 0] |   %b   | START", data_tx);
            idx = 1;

            // 3. Sample remaining 10 bits on subsequent ticks
            repeat(10) begin
                @(posedge clk); // Step past the current tick
                while (!uut.baud_tick) @(posedge clk); // Wait for the next tick
                #1; 
                
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

            // Wait for transmission to complete
            while (active_flag) @(posedge clk);
        end
    end

    // -----------------------------------------------------------
    // Stimulus
    // -----------------------------------------------------------
    initial begin
        resetn      = 0;
        send        = 0;
        baud_rate   = 2'b00;       // 9600 baud
        parity_type = 2'b10;       // Even Parity (10)
        data_in     = 8'b01001010; // 0x4A (Three 1s -> Parity bit should be 1)
        
        #250;
        resetn = 1;

        // --- Packet 1 ---
        @(posedge clk);
        send = 1;       // Trigger send
        @(posedge clk); 
        send = 0;       // Send is now a clean 1-cycle pulse
        
        // Let simulation run until the module finishes
        @(negedge active_flag);
        #1000;

        // --- Packet 2 ---
        data_in     = 8'b01011010; // 0x5A (Four 1s -> Parity bit should be 1)
        parity_type = 2'b01;       // Odd Parity (01)
        baud_rate   = 2'b01;       // 19200 baud (Pulses will happen 2x faster!)
        
        @(posedge clk);
        send = 1;
        @(posedge clk);
        send = 0;

        @(negedge active_flag);
        #1000;
        
        $display("--- Top-Level Simulation Complete ---");
        $finish; 
    end

endmodule
