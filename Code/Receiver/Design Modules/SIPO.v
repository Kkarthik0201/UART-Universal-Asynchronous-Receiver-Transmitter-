`timescale 1ns / 1ps

module SIPO (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        baud_tick,
    input  wire        data_tx,

    output reg  [10:0] data_parll,
    output reg         active_flag,
    output reg         received_flag
);
    localparam IDLE = 1'b0;
    localparam RECV = 1'b1;

    reg        state;
    reg [10:0] shift_reg;
    reg [3:0]  counter;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state         <= IDLE;
            shift_reg     <= 11'd0;
            counter       <= 4'd0;
            data_parll    <= 11'd0;
            active_flag   <= 1'b0;
            received_flag <= 1'b0;

        end else begin

            // default - pulse clears itself every cycle unless re-driven
            received_flag <= 1'b0;

            case (state)

                //----------------------------------------------
                IDLE: begin
                    counter     <= 4'd0;
                    active_flag <= 1'b0;

                    // start bit = logic 0, must coincide with baud_tick
                    // so we sample at the correct baud boundary
                    if (data_tx == 1'b0 && baud_tick == 1'b1) begin
                        state       <= RECV;
                        active_flag <= 1'b1;
                        shift_reg   <= {data_tx, shift_reg[10:1]};
                        counter     <= 4'd1;
                    end
                end

                //----------------------------------------------
                RECV: begin
                    if (baud_tick) begin
                        shift_reg <= {data_tx, shift_reg[10:1]};
                        counter   <= counter + 4'd1;

                        if (counter == 4'd10) begin
                            // latch complete frame, assert flags,
                            // and return to IDLE - all in the SAME cycle
                            data_parll    <= {data_tx, shift_reg[10:1]};
                            received_flag <= 1'b1;
                            active_flag   <= 1'b0;   // clears here, not next cycle
                            state         <= IDLE;
                            counter       <= 4'd0;
                        end
                    end
                end

            endcase
        end
    end

endmodule
