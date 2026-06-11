
`timescale 1ns / 1ps

module DeFrame_tb;

    // 1. Declare Signals
    reg  [10:0] tb_data_parll;
    reg         tb_received_flag;
    
    wire        tb_parity_bit;
    wire        tb_start_bit;
    wire        tb_stop_bit;
    wire        tb_done_flag;
    wire [7:0]  tb_raw_data;

    // 2. Instantiate DUT
    DeFrame uut (
        .data_parll(tb_data_parll),
        .recieved_flag(tb_received_flag), // Intentionally matching your spelling
        .parity_bit(tb_parity_bit),
        .start_bit(tb_start_bit),
        .stop_bit(tb_stop_bit),
        .done_flag(tb_done_flag),
        .raw_data(tb_raw_data)
    );

    // 3. Stimulus Block
    initial begin
        $display("========================================");
        $display("   DeFrame Module Console Output");
        $display("========================================");
        
        $monitor("Time:%0t | flag_in:%b -> flag_out:%b | Bus:%b -> Start:%b Data:%b Parity:%b Stop:%b",
                 $time, tb_received_flag, tb_done_flag, tb_data_parll, tb_start_bit, tb_raw_data, tb_parity_bit, tb_stop_bit);

        // Test 1: All Zeros
        tb_received_flag = 1'b0;
        tb_data_parll    = 11'b00000000000;
        #10;
        
        // Test 2: The packet we just simulated (0x4A with Even Parity)
        // Format: {Stop(1), Parity(1), Data(01001010), Start(0)}
        tb_received_flag = 1'b1;
        tb_data_parll    = 11'b1_1_01001010_0; 
        #10;
        
        // Test 3: Drop the flag (done_flag should drop instantly)
        tb_received_flag = 1'b0;
        #10;

        // Test 4: All Ones
        tb_received_flag = 1'b1;
        tb_data_parll    = 11'b11111111111;
        #10;

        $display("========================================");
        $finish;
    end

endmodule
