`timescale 1ns / 1ps

module baud_generator_tb();

    // 1. Signal Declarations
    reg        clk;
    reg        resetn;
    reg [1:0]  baud_rate;
    wire       baud_clk;

    // 2. Instantiate DUT
    Baud_generator dut_baud (
        .clk(clk),
        .baud_rate(baud_rate),
        .resetn(resetn),
        .baud_clk(baud_clk)
    );

    // 3. Clock Generation: Toggles every 100ns (200ns period = 5 MHz)
    always #100 clk = ~clk; 

    // 4. Stimulus and Setup
    initial begin 
        // --- THIS SECTION FIXES YOUR "TICKS" VISIBILITY ---
        // This forces the simulator to record all internal signals 
        // (like dut_baud.ticks) so they appear in your waveform.
        $dumpfile("dump.vcd");
        $dumpvars(0, baud_generator_tb); 
        // --------------------------------------------------

        // Initial State
        clk       = 1'b0;
        resetn    = 1'b0;   
        baud_rate = 2'b00;  // 9600 baud
        
        // Wait 250ns, then release reset
        #250;
        resetn = 1'b1;

        // Monitor console output whenever the baud_clk pulses
        $display("Testing 9600 Baud...");
        
        // Run for 250,000 ns (Enough to see about 2 pulses at 9600 baud)
        #250000;
        
        $display("Switching to 115200 Baud...");
        baud_rate = 2'b11;  // 115200 baud
        
        // Run for 40,000 ns (Enough to see about 4 or 5 pulses at 115200)
        #250000;
        $display("Switching to 38400 Baud...");
        baud_rate = 2'b10;
        #250000;
        $display("Switching to 19200 Baud...");
        baud_rate = 2'b01;
        #250000;
        $display("--- Simulation Complete ---");
        $finish;
    end

    // Optional: Print to console exactly when the baud_clk goes high
    always @(posedge baud_clk) begin
        $display("Time: %0t | Baud Pulse Generated! | Internal Ticks Reset", $time);
    end

endmodule