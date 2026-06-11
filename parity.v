module Parity_generator(
input wire [7:0]data_in,
input wire [1:0] parity_type,
output reg parity_bit
    );
    always @(*)
    begin
    case(parity_type)
    2'b00 : parity_bit = 1'b0;
    2'b01 : parity_bit = ^data_in; //even parity
    2'b10 : parity_bit = ~(^data_in); // odd parity
    2'b11 : parity_bit = 1'b1; 
    default : parity_bit = 1'b0;
    endcase
    end
endmodule