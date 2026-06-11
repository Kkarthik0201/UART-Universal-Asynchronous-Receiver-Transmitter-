`timescale 1ns / 1ps


module parity_generator_tb(

    );
    reg [7:0]  data_in;
    reg [1:0]  parity_type;
    wire       parity_bit;
    Parity_generator dut_parity (.data_in(data_in),.parity_type(parity_type),.parity_bit(parity_bit));
    initial begin 
$monitor("Time: %0t | Data: %b | Type: %b | Parity Out: %b", 
                 $time, data_in, parity_type, parity_bit);

        $display("--- Starting Parity Tests ---");
        parity_type = 2'b00;
        data_in     = 8'b11110000;
        #20;
        parity_type = 2'b10;
        data_in     = 8'b10101010; // Four 1s (Even)
        #20;
        parity_type = 2'b10;
        data_in     = 8'b10101011; // Five 1s (Odd)
        #20;
        parity_type = 2'b01;
        data_in     = 8'b10101010; // Four 1s (Even)
        #20;
        parity_type = 2'b01;
        data_in     = 8'b10101011; // Five 1s (Odd)
        #20;
        parity_type = 2'b11;
        data_in     = 8'b00000000;
        #20;

        $display("--- End of Parity Tests ---");
        $finish;
    end
endmodule
