# UART

## Description
This project implements a Universal Asynchronous Receiver Transmitter (UART) using Verilog. It includes modules for a Receiver, a Transmitter and a testbench for verification.

## Directory Structure
```
uart/
├── modules/         # Verilog modules for UART
├── testbench/       # Testbench for simulation
```

## Key Files
- **Modules**:
  - `uart_rx.v` : Implements a Receiver with 1 start bit, 8 data bits, 1 stop bit and no parity bits.
  - `uart_tx.v` : Implements a Transmitter with 1 start bit, 8 data bits, 1 stop bit and no parity bits.
- **Testbenches**:
  - `tb_uart.v` : Testbench for both Receiver and Transmitter modules.

## How to Use
1. **Simulation**:
   - Use a Verilog simulator (e.g., Vivado) to simulate the testbench.
   - Adjust Radix and Waveform according to format.
2. **Synthesis**:
   - Use a synthesis tool (e.g., Vivado) to synthesize the design.
