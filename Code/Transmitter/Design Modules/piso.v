`timescale 1ns / 1ps

module PISO (
    input  wire       clk,
    input  wire       baud_tick,
    input  wire       resetn,
    input  wire       send,
    input  wire       parity_bit,
    input  wire [7:0] data_in,

    output reg        data_tx,
    output reg        active_flag,
    output reg        done_flag
);
    localparam IDLE   = 1'b0;
    localparam ACTIVE = 1'b1;

    reg        state;
    reg [3:0]  stop_count;
    reg [10:0] frame_man;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state       <= IDLE;
            stop_count  <= 4'd0;
            frame_man   <= 11'h7FF;
            data_tx     <= 1'b1;
            active_flag <= 1'b0;
            done_flag   <= 1'b1;

        end else begin
            case (state)

                //--------------------------------------------------
                IDLE: begin
                    data_tx     <= 1'b1;
                    active_flag <= 1'b0;
                    done_flag   <= 1'b1;

                    if (send) begin
                        state       <= ACTIVE;
                        active_flag <= 1'b1;
                        done_flag   <= 1'b0;
                        stop_count  <= 4'd0;
                        // frame = stop(1) | parity | data[7:0] | start(0)
                        frame_man   <= {1'b1, parity_bit, data_in, 1'b0};
                    end
                end

                //--------------------------------------------------
                ACTIVE: begin
                    if (baud_tick) begin

                        // output LSB, then shift right (fill with 1s)
                        data_tx   <= frame_man[0];
                        frame_man <= {1'b1, frame_man[10:1]};

                        if (stop_count == 4'd10) begin
                            // last bit (index 10) is being clocked out -
                            // de-assert flags in the SAME cycle, not after
                            // transitioning to IDLE next clock
                            state       <= IDLE;
                            active_flag <= 1'b0;
                            done_flag   <= 1'b1;
                            stop_count  <= 4'd0;
                        end else begin
                            stop_count <= stop_count + 4'd1;
                        end

                    end
                end

            endcase
        end
    end

endmodule