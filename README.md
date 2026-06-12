# UART Transmitter and Receiver using Verilog

## Overview

This project implements a **Universal Asynchronous Receiver/Transmitter (UART)** in Verilog HDL. UART is a serial communication protocol widely used for communication between microcontrollers, computers, sensors, and FPGA-based systems.

The design supports configurable baud rates and parity modes, and provides error detection mechanisms for reliable data transmission.

-------

## Features

* Full duplex serial communication.
* Configurable baud rate.
* Supports:

  * Zero parity
  * Even parity
  * Odd parity
  * One parity
* Start bit and stop bit generation.
* Parallel-to-Serial conversion for transmission.
* Serial-to-Parallel conversion for reception.
* Error detection:

  * Start bit error
  * Stop bit error
  * Parity error
* Status flags:

  * Transmission Active
  * Transmission Complete
  * Reception Active
  * Reception Complete

---

## Project Structure

```
UART_Project/
│
├── BaudGenerator.v
├── PISO.v
├── SIPO.v
├── ParityGenerator.v
├── ErrorCheck.v
├── UART_TX.v
├── UART_RX.v
├── UART_Top.v
├── UART_Top_tb.v
└── README.md
```

---

## Block Diagram

```
                 +----------------+
                 | Baud Generator |
                 +----------------+
                         |
             -------------------------
             |                       |
             V                       V

      +-------------+         +-------------+
      | UART TX     |         | UART RX     |
      |-------------|         |-------------|
      | PISO        |         | SIPO        |
      | Parity Gen  |         | Error Check |
      +-------------+         +-------------+
             |                       |
             -------- Serial Line ----
```

---

## UART Frame Format

The transmitted frame consists of:

```
+---------+----------+---------+----------+
| Start   | Data     | Parity  | Stop Bit |
| Bit (0) | 8 bits   | Optional| 1        |
+---------+----------+---------+----------+
```

Data bits are transmitted **Least Significant Bit (LSB) first**.

Example for transmitting 0xA5:

```
Start  Data Bits (LSB first)     Stop
 0     1 0 1 0 0 1 0 1           1
```

---

## Modules Description

### 1. Baud Generator

Generates the baud clock required for serial communication.

#### Inputs

* clk
* reset_n
* baud_rate

#### Output

* baud_clk

---

### 2. PISO (Parallel-In Serial-Out)

Converts 8-bit parallel data into serial data for transmission.

#### Inputs

* clk
* reset_n
* load
* data_in

#### Output

* serial_out

---

### 3. Parity Generator

Generates parity bit based on the selected parity mode.

#### Inputs

* data_in
* parity_type

#### Output

* parity_bit

Parity modes:

| Parity Type | Mode        |
| ----------- | ----------- |
| 00          | Zero parity |
| 01          | Even parity |
| 10          | Odd parity  |
| 11          | One Parity  |

---

### 4. UART Transmitter

Responsible for transmitting:

1. Start bit
2. Data bits
3. Parity bit
4. Stop bit

#### Inputs

* clk
* reset_n
* send
* data_in
* parity_type
* baud_rate

#### Outputs

* tx
* tx_active_flag
* tx_done_flag

---

### 5. SIPO (Serial-In Parallel-Out)

Converts incoming serial bits into parallel data.

#### Inputs

* clk
* reset_n
* serial_in

#### Outputs

* data_out
* received_flag

---

### 6. Error Check Module

Verifies:

* Start bit correctness
* Stop bit correctness
* Parity correctness

#### Output Flags

| Bit | Error           |
| --- | --------------- |
| 0   | Start Bit Error |
| 1   | Stop Bit Error  |
| 2   | Parity Error    |

---

### 7. UART Receiver

Receives the serial frame and reconstructs the original byte.

#### Outputs

* data_out
* rx_active_flag
* rx_done_flag
* error_flag

---

## Simulation

Testbench file:

```
UART_Top_tb.v
```

Simulation can be performed using:

* ModelSim
* Vivado Simulator
* Icarus Verilog
* GTKWave

Compile:

```bash
iverilog *.v -o uart.out
```

Run:

```bash
vvp uart.out
```

View waveforms:

```bash
gtkwave dump.vcd
```

---

## Example

### Input

```
Data In      = 8'hA5
Parity Type  = Even
Baud Rate    = 9600
Send         = 1
```

### Transmitted Frame

```
Start : 0
Data  : 10100101 (LSB first)
Parity: 0
Stop  : 1
```

### Receiver Output

```
Data Out      = 8'hA5
Error Flag    = 000
Rx Done Flag  = 1
```

---

## Applications

* FPGA communication
* Microcontroller interfaces
* RS-232 communication
* Sensor data transmission
* Embedded systems
* Serial peripherals

---

## Future Improvements

* FIFO buffer support.
* Configurable data width.
* Multiple stop bits.
* Hardware flow control.
* Interrupt generation.
* Support for RS-232 level shifting.

---

