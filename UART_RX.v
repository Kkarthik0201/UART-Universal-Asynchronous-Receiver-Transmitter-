`timescale 1ns / 1ps

module UART_Rx(
    input  wire        reset_n,     
    input  wire        data_tx,     
    input  wire        clock,       
    input  wire [1:0]  parity_type, 
    input  wire [1:0]  baud_rate,   

    output wire        active_flag, 
    output wire        done_flag,   
    output wire [2:0]  error_flag,  
    output wire [7:0]  data_out     
);

    wire        baud_clk_wire;
    wire [10:0] data_parll_wire;
    wire        received_flag_wire;
    wire        start_bit_wire;
    wire        stop_bit_wire;
    wire        parity_bit_wire;

    Baud_generator baud_gen_inst (
        .clk       (clock),
        .baud_rate (baud_rate),
        .resetn    (reset_n),
        .baud_clk  (baud_clk_wire)
    );

    SIPO sipo_inst (
        .clk           (clock),
        .reset_n       (reset_n),
        .baud_tick     (baud_clk_wire),
        .data_tx       (data_tx),
        .data_parll    (data_parll_wire),
        .active_flag   (active_flag),
        .received_flag (received_flag_wire)
    );

    DeFrame deframe_inst (
        .data_parll    (data_parll_wire),
        .recieved_flag (received_flag_wire),
        .start_bit     (start_bit_wire),
        .raw_data      (data_out),
        .parity_bit    (parity_bit_wire),
        .stop_bit      (stop_bit_wire),
        .done_flag     (done_flag)
    );

    error_check error_check_inst (
        .done_flag   (done_flag),
        .start_bit   (start_bit_wire),
        .stop_bit    (stop_bit_wire),
        .parity_bit  (parity_bit_wire),
        .data        (data_out),
        .parity_type (parity_type),
        .error_flag  (error_flag)
    );

endmodule