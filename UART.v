`timescale 1ns / 1ps

module UART (
    input   wire         reset_n,       
    input   wire         send,          
    input   wire         clock,         
    input   wire  [1:0]  parity_type,   
    input   wire  [1:0]  baud_rate,     
    input   wire  [7:0]  data_in,       

    output  wire         tx_active_flag, 
    output  wire         tx_done_flag,   
    output  wire         rx_active_flag, 
    output  wire         rx_done_flag,   
    output  wire  [7:0]  data_out,       
    output  wire  [2:0]  error_flag
);

    wire serial_loopback;

    UART_TX tx_inst (
        .clk         (clock),
        .resetn      (reset_n),
        .send        (send),
        .baud_rate   (baud_rate),
        .parity_type (parity_type),
        .data_in     (data_in),
        .data_tx     (serial_loopback),
        .active_flag (tx_active_flag),
        .done_flag   (tx_done_flag)
    );

    UART_Rx rx_inst (
        .clock       (clock),
        .reset_n     (reset_n),
        .data_tx     (serial_loopback),
        .baud_rate   (baud_rate),
        .parity_type (parity_type),
        .data_out    (data_out),
        .active_flag (rx_active_flag),
        .done_flag   (rx_done_flag),
        .error_flag  (error_flag)
    );

endmodule