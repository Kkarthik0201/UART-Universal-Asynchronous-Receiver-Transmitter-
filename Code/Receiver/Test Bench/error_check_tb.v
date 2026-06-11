`timescale 1ns / 1ps

module error_check_tb;

    // 1. Declare Signals
    reg        tb_done_flag;
    reg        tb_start_bit;
    reg        tb_stop_bit;
    reg        tb_parity_bit;
    reg  [7:0] tb_data;
    reg  [1:0] tb_parity_type;
    
    wire [2:0] tb_error_flag;

    // 2. Instantiate DUT
    error_check uut (
        .done_flag(tb_done_flag),
        .start_bit(tb_start_bit),
        .stop_bit(tb_stop_bit),
        .parity_bit(tb_parity_bit),
        .data(tb_data),
        .parity_type(tb_parity_type),
        .error_flag(tb_error_flag)
    );

    // Helper task to format output clearly
    task check_errors(input [8*20:1] test_name);
        begin
            #5; // Wait for combinational logic to settle
            $display("Test: %s", test_name);
            $display("Input -> Start:%b Data:%b Parity:%b Stop:%b | Type:%b", 
                     tb_start_bit, tb_data, tb_parity_bit, tb_stop_bit, tb_parity_type);
            $display("Result-> Error Flag: %b [StartErr:%b, StopErr:%b, ParityErr:%b]\n", 
                     tb_error_flag, tb_error_flag[2], tb_error_flag[1], tb_error_flag[0]);
        end
    endtask

    // 3. Stimulus Block
    initial begin
        $display("========================================");
        $display("   ErrorCheck Module Testing");
        $display("========================================\n");

        // Initialization
        tb_done_flag   = 1'b0;
        tb_start_bit   = 1'b0;
        tb_stop_bit    = 1'b1;
        tb_parity_bit  = 1'b0;
        tb_data        = 8'b00000000;
        tb_parity_type = 2'b00;
        #10;

        // ----------------------------------------------------
        // TEST 1: The "Flag Off" Test
        // ----------------------------------------------------
        tb_done_flag = 1'b0; 
        tb_start_bit = 1'b1; // Horribly broken frame
        tb_stop_bit  = 1'b0;
        check_errors("No Done Flag (Should be 000)");

        // Turn flag on for the rest of the tests
        tb_done_flag = 1'b1; 

        // ----------------------------------------------------
        // TEST 2: Perfect Packet (Even Parity)
        // ----------------------------------------------------
        tb_start_bit   = 1'b0;           // Correct
        tb_stop_bit    = 1'b1;           // Correct
        tb_data        = 8'b01001010;    // Three 1s
        tb_parity_bit  = 1'b1;           // Makes total four 1s (Even)
        tb_parity_type = 2'b10;          // Even Parity Mode
        check_errors("Perfect Even Parity Packet");

        // ----------------------------------------------------
        // TEST 3: Parity Error! (Bit 0 should flip)
        // ----------------------------------------------------
        tb_parity_bit  = 1'b0;           // WRONG parity bit for Even mode
        check_errors("Parity Error Induced");

        // ----------------------------------------------------
        // TEST 4: Framing Error - Bad Stop Bit! (Bit 1 should flip)
        // ----------------------------------------------------
        tb_parity_bit  = 1'b1;           // Fix parity
        tb_stop_bit    = 1'b0;           // WRONG stop bit
        check_errors("Bad Stop Bit Induced");

        // ----------------------------------------------------
        // TEST 5: Framing Error - Bad Start Bit! (Bit 2 should flip)
        // ----------------------------------------------------
        tb_stop_bit    = 1'b1;           // Fix Stop bit
        tb_start_bit   = 1'b1;           // WRONG start bit
        check_errors("Bad Start Bit Induced");

        // ----------------------------------------------------
        // TEST 6: The "Total Garbage" Packet (All error bits should flip)
        // ----------------------------------------------------
        tb_start_bit   = 1'b1;           // Bad Start
        tb_stop_bit    = 1'b0;           // Bad Stop
        tb_data        = 8'b01001010;    // Three 1s
        tb_parity_bit  = 1'b0;           // Bad Parity (Even mode)
        check_errors("Total Garbage Packet (Should be 111)");

        $display("========================================");
        $finish;
    end

endmodule