module Baud_generator(
    input  wire       clk,
    input  wire [1:0] baud_rate,
    input  wire       resetn,
    output reg        baud_clk
);

    reg [15:0] ticks;
    reg [15:0] ticker_reg;     // registered divisor
    reg [1:0]  baud_rate_reg;  // remembers last selected baud rate

    // Combinational next divisor
    reg [15:0] ticker_next;
    always @(*) begin
        case (baud_rate)
            2'b00: ticker_next = 16'd521;  // 9600
            2'b01: ticker_next = 16'd260;  // 19200
            2'b10: ticker_next = 16'd130;  // 38400
            2'b11: ticker_next = 16'd43;   // 115200
            default: ticker_next = 16'd521;
        endcase
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            ticks         <= 16'd0;
            ticker_reg    <= 16'd521;
            baud_rate_reg  <= 2'b00;
            baud_clk     <= 1'b0;
        end
        else begin
            // If baud selection changed, load new divisor and restart counting
            if (baud_rate != baud_rate_reg) begin
                baud_rate_reg <= baud_rate;
                ticker_reg    <= ticker_next;
                ticks         <= 16'd0;
                baud_clk    <= 1'b0;
            end
            else if (ticks == ticker_reg - 1) begin
                ticks     <= 16'd0;
                baud_clk <= 1'b1;   // one-clock pulse
            end
            else begin
                ticks     <= ticks + 16'd1;
                baud_clk <= 1'b0;
            end
        end
    end

endmodule