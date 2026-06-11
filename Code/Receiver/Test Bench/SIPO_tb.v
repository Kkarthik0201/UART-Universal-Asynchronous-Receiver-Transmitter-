`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.06.2026 16:21:48
// Design Name: 
// Module Name: SIPO_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module SIPO_tb;

    // 1. Signal Declarations
    reg         clk;
    reg         reset_n;
    reg         baud_tick;
    reg         data_tx;
    
    wire [10:0] data_parll;
    wire        active_flag;
    wire        received_flag;

    // 2. Instantiate the SIPO Module (Device Under Test)
    SIPO uut (
        .clk(clk),
        .reset_n(reset_n),
        .baud_tick(baud_tick),
        .data_tx(data_tx),
        .data_parll(data_parll),
        .active_flag(active_flag),
        .received_flag(received_flag)
    );

    // 3. VCD Dumping for Waveforms
    initial begin
        $dumpfile("SIPO_tb.vcd");
        $dumpvars(0, SIPO_tb);
    end

    // 4. System Clock Generation (5 MHz -> 200ns period)
    initial begin
        clk = 1'b0;
        forever #100 clk = ~clk;
    end

    // 5. Simulated Baud Tick Generator
    // Pulses high for 1 clock cycle every 5 clock cycles
    initial begin
        baud_tick = 1'b0;
        forever begin
            repeat(4) @(posedge clk);
            baud_tick = 1'b1;
            @(posedge clk);
            baud_tick = 1'b0;
        end
    end

    // 6. UART Data Receiver Monitor (Protocol Analyzer)
    // This automatically prints to the console the moment received_flag goes high!
    always @(posedge clk) begin
        if (received_flag == 1'b1) begin
            $display("\n=== 📥 SIPO FRAME RECEIVED ===");
            $display("Time             : %0t ns", $time);
            $display("Raw 11-bit Bus   : %b", data_parll);
            $display("--------------------------------");
            $display("Extracted Start  : %b (Should be 0)", data_parll[0]);
            $display("Extracted Data   : %b", data_parll[8:1]);
            $display("Extracted Parity : %b", data_parll[9]);
            $display("Extracted Stop   : %b (Should be 1)", data_parll[10]);
            $display("================================\n");
        end
    end

    // 7. TASK: A helper function to act like a Transmitter
    task send_frame(input [7:0] data, input parity);
        integer i;
        reg [10:0] frame_to_send;
        begin
            // Assemble the frame exactly like our Tx PISO block does
            frame_to_send = {1'b1, parity, data, 1'b0}; 
            
            $display("Sending Data: %b | Parity: %b...", data, parity);
            
            for(i = 0; i < 11; i = i + 1) begin
                // Put the bit on the wire
                data_tx = frame_to_send[i];
                
                // Wait for the baud tick to pass so the SIPO can grab it
                @(posedge clk);
                while(!baud_tick) @(posedge clk);
            end
        end
    endtask

    // 8. Main Stimulus Block
    initial begin
        // Initialize everything
        reset_n = 1'b0;
        data_tx = 1'b1; // UART idles High
        
        #250;
        reset_n = 1'b1; // Release reset
        @(posedge clk);

        // --- Test Packet 1 ---
        // Let's send 0x4A (01001010) with an Even Parity bit of 1
        send_frame(8'b01001010, 1'b1);
        
        // Wait a few baud ticks between packets
        repeat(5) begin
            @(posedge clk);
            while(!baud_tick) @(posedge clk);
        end

        // --- Test Packet 2 ---
        // Let's send 0x5A (01011010) with an Odd Parity bit of 1
        send_frame(8'b01011010, 1'b1);
        
        // Wait a bit for the final processing
        #2000;
        
        $display("--- Simulation Complete ---");
        $finish;
    end

endmodule
