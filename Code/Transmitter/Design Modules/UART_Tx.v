`timescale 1ns / 1ps
module UART_TX(
    input  wire       clk,
    input  wire       resetn,
    input  wire       send,
    input  wire [1:0] baud_rate,
    input  wire [1:0] parity_type,
    input  wire [7:0] data_in,

    output wire       data_tx,
    output wire       active_flag,
    output wire       done_flag
);

    // Internal wires connecting the sub-modules
    wire baud_tick; 
    wire parity_bit;

    // 1. Instantiate the Baud Generator
    Baud_generator Baud_Gen (
        .clk(clk),
        .baud_rate(baud_rate),
        .resetn(resetn),
        .baud_clk(baud_tick) // Output of BaudGen goes to our internal tick wire
    );

    // 2. Instantiate the Parity Generator
    Parity_generator Parity_Gen (
        .data_in(data_in),
        .parity_type(parity_type),
        .parity_bit(parity_bit)
    );

    // 3. Instantiate the Synchronous PISO Shift Register
    PISO Shift_Register (
        .clk(clk),               // NEW: Route the main 5MHz system clock here
        .baud_tick(baud_tick),   // NEW: Route the 1-cycle baud pulse here as an enable
        .resetn(resetn),
        .send(send),
        .parity_bit(parity_bit),
        .data_in(data_in),
        
        .data_tx(data_tx),
        .active_flag(active_flag),
        .done_flag(done_flag)
    );

endmodule