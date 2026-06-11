`timescale 1ns / 1ps
////////////////////////

module error_check(
    input  wire       done_flag,
    input  wire       start_bit,
    input  wire       stop_bit,
    input  wire       parity_bit,
    input  wire [7:0] data,
    input  wire [1:0] parity_type,
    
    output reg  [2:0] error_flag
);

    always @(*) begin 
        if (!done_flag) begin
            error_flag = 3'b000;
        end else begin 
            
            error_flag[2] = (start_bit != 1'b0);
            error_flag[1] = (stop_bit != 1'b1);
            case(parity_type)
                2'b00: error_flag[0] = (parity_bit != 1'b0); // None
                
                2'b01: error_flag[0] = (parity_bit != ^data); // Odd
                
                2'b10: error_flag[0] = (parity_bit != ~(^data)); // Even
                
                2'b11: error_flag[0] = (parity_bit != 1'b1);  // Mark
                
                default: error_flag[0] = 1'b0;
            endcase
        end
    end 

endmodule