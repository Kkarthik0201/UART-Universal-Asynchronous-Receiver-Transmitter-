`timescale 1ns / 1ps

module piso_tb;

    // -----------------------------------------------------------
    // 1. Signal Declarations
    // -----------------------------------------------------------
    reg        clk;
    reg        baud_tick;
    reg        resetn;
    reg        send;
    reg        parity_bit;
    reg [7:0]  data_in;

    wire       data_tx;
    wire       active_flag;
    wire       done_flag;

    // -----------------------------------------------------------
    // 2. Instantiate the DUT (Device Under Test)
    // -----------------------------------------------------------
    PISO uut (
        .clk(clk),
        .baud_tick(baud_tick),
        .resetn(resetn),
        .send(send),
        .parity_bit(parity_bit),
        .data_in(data_in),
        .data_tx(data_tx),
        .active_flag(active_flag),
        .done_flag(done_flag)
    );

    // -----------------------------------------------------------
    // 3. Clock & Baud Tick Generation
    // -----------------------------------------------------------
    // 5 MHz System Clock (200ns period)
    initial begin
        clk = 1'b0;
        forever #100 clk = ~clk;
    end

    // Accelerated Baud Tick (Pulses every 5 clock cycles for fast simulation)
    initial begin
        baud_tick = 1'b0;
        forever begin
            repeat(4) @(posedge clk);
            baud_tick = 1'b1;
            @(posedge clk);
            baud_tick = 1'b0;
        end
    end

    // VCD Dumping
    initial begin
        $dumpfile("piso_tb.vcd");
        $dumpvars(0, piso_tb);
    end

    // -----------------------------------------------------------
    // 4. Automated Protocol Analyzer / Sampler
    // -----------------------------------------------------------
    integer    pkt;
    integer    idx;
    reg [10:0] frame;
    reg [10:0] expected_frame;

    initial begin
        pkt = 0; frame = 0;
        @(posedge resetn);

        forever begin
            // 1. Wait for PISO to become ACTIVE
            while (!active_flag) @(posedge clk);

            pkt = pkt + 1;
            frame = 11'b0;
            expected_frame = {1'b1, parity_bit, data_in, 1'b0};

            $display("\n==============================================");
            $display(" 📤 PISO TRANSMITTING PACKET %0d", pkt);
            $display("==============================================");
            $display(" Input -> Data: %b | Parity: %b", data_in, parity_bit);
            $display("----------------------------------------------");
            $display(" Bit  | Value | Label");
            $display("------|-------|-------------------------------");

            // 2. Sample all 11 bits EXACTLY on the baud_tick
            for (idx = 0; idx < 11; idx = idx + 1) begin
                // Wait for the tick
                while (!baud_tick) @(posedge clk);
                #1; // Wait 1ns for the data_tx line to stabilize after the clock edge
                
                frame[idx] = data_tx;
                
                case(idx)
                    0:       $display(" [ 0] |   %b   | START", data_tx);
                    9:       $display(" [%2d] |   %b   | PARITY", idx, data_tx);
                    10:      $display(" [%2d] |   %b   | STOP", idx, data_tx);
                    default: $display(" [%2d] |   %b   | DATA[%0d]", idx, data_tx, idx-1);
                endcase
                
                // Move past the current tick so we don't double-sample
                @(posedge clk); 
            end

            $display("----------------------------------------------");
            $display(" Captured Frame : %b", frame);
            $display(" Expected Frame : %b", expected_frame);
            
            if (frame == expected_frame) begin
                $display(" Status         : ✅ PASS (Perfect Shift!)");
            end else begin
                $display(" Status         : ❌ ALARM! Data mismatch.");
            end
            $display("==============================================\n");
            
            // Wait for module to return to IDLE before looping
            while (active_flag) @(posedge clk);
        end
    end

    // -----------------------------------------------------------
    // 5. Main Stimulus Block (Golden Master Tests)
    // -----------------------------------------------------------
    initial begin
        // Initialize
        resetn     = 1'b0;
        send       = 1'b0;
        parity_bit = 1'b0;
        data_in    = 8'b0;
        
        #250;
        resetn = 1'b1;
        repeat(5) @(posedge clk);

        $display("--- Starting PISO Module Tests ---");

        // TEST 1: Send 0x4A with Parity 1
        data_in    = 8'b01001010;
        parity_bit = 1'b1;
        
        @(posedge clk);
        send = 1'b1;
        @(posedge clk);
        send = 1'b0; // Clean 1-cycle trigger
        
        // Wait for the done_flag to signal completion
        @(posedge done_flag);
        repeat(20) @(posedge clk); // Give some breathing room between packets

        // TEST 2: Send 0x5A with Parity 0
        data_in    = 8'b01011010;
        parity_bit = 1'b0;
        
        @(posedge clk);
        send = 1'b1;
        @(posedge clk);
        send = 1'b0;
        
        @(posedge done_flag);
        repeat(20) @(posedge clk);

        // TEST 3: Send All 1s (0xFF) with Parity 1
        data_in    = 8'b11111111;
        parity_bit = 1'b1;
        
        @(posedge clk);
        send = 1'b1;
        @(posedge clk);
        send = 1'b0;
        
        @(posedge done_flag);
        repeat(20) @(posedge clk);

        $display("--- PISO Testing Complete ---");
        $finish;
    end

endmodule