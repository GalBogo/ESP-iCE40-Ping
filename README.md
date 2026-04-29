# ESP32 & FPGA Real-Time Notification System

## Overview
A real-time hardware-software integration project that bridges an ESP32 microcontroller with a Lattice iCE40 FPGA to process and physicalize network notifications. The ESP32 acts as the web server and display manager (OLED), while the FPGA drives the physical environment (Servo motor, Buzzers, and a 9-LED array) based on direct GPIO hardware triggers.

## System Architecture
* **Firmware (C++):** An ESP32 runs a local WebServer handling `/message` and `/call` HTTP requests. It drives an I2C SSD1306 OLED to display incoming text/caller IDs and triggers dedicated GPIO pins based on the event.
* **Hardware-Software Bridge:** Direct, asynchronous GPIO signaling between the ESP32 and the FPGA. 
* **Hardware RTL (SystemVerilog):** The Lattice iCE40 FPGA runs a custom FSM operating at 12MHz, continuously polling the input pins to execute precise, state-dependent physical responses.

## Physical Integration & Pinout
| Function | ESP32 Pin | FPGA Pin (IceBreaker) | Description |
| :--- | :--- | :--- | :--- |
| **Message Trigger** | GPIO 16 | Pin 27 | Goes HIGH for 2.5s on incoming message |
| **Call Trigger** | GPIO 4 | Pin 25 | Goes HIGH for 10s on incoming call |
| **Servo PWM** | N/A | Pin 31 | Custom PWM generation |
| **Buzzers (x2)** | N/A | Pins 42, 36 | ~3kHz tone generation |
| **LED Array (x9)**| N/A | PMOD1A / PMOD1B | State-dependent visual patterns |
| **Common GND** | GND | GND | Essential for signal integrity |

## RTL Module Breakdown
* `top_notifi_project.sv`: The top-level entity managing the global FSM (`S_IDLE`, `S_MSG`, `S_CALL`) and routing the ESP32 triggers to the output controllers.
* `servo_notifi.sv`: Generates a custom 50Hz PWM signal. Implements a sweeping logic based on the state:
  * **Call State:** Sweeps 0° to 180°.
  * **Message State:** Sweeps 0° to 45°.
* `leds_buzzers_notifi.sv`: Manages precise timing sequences for visual and audio alerts using synchronized counters. Features a 3kHz tone generator for the buzzers and distinct cascading/blinking logic for the 9 LEDs based on the active state.

## Toolchain & Build Instructions
The FPGA RTL is synthesized using the open-source OSS CAD Suite.
```bash
# 1. Synthesis
yosys -p "synth_ice40 -top top_notifi_project -json project.json" *.sv

# 2. Place and Route
nextpnr-ice40 --up5k --package sg48 --json project.json --pcf pins.pcf --asc project.asc

# 3. Bitstream Generation
icepack project.asc project.bin

# 4. Flash to Board
iceprog project.bin
