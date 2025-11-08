# ⚙️ FSM-Based VHDL Design — Weather Station Project

This folder contains all **VHDL source files (`.vhd`)** used in the FPGA-based **Weather Station** project (EDA234, Chalmers University of Technology).  
The architecture of this project is built around **modular Finite State Machines (FSMs)** controlling each sensor and peripheral device.

---

## 📁 Directory Overview

```
src/
├── counter.vhd
├── clock_generator.vhd
├── DS18B20.vhd
├── DHT11.vhd
├── MCP3202.vhd
├── LCD.vhd
├── UART_transmitter.vhd
├── seven_segment_display.vhd
├── alarm.vhd
├── wrapper.vhd
└── packages.vhd
```

---

## 🧩 Finite State Machines (FSMs)

Each FSM module follows a **Moore-style design** with explicit state transitions and timing control based on sensor communication protocols.

---

### 🌡️ DS18B20 — Temperature Sensor FSM

**Purpose:** Controls the 1-Wire protocol for the DS18B20 digital temperature sensor.

**FSM States:**
```
idle → masterTx → presence → masterRx → recTime → 
startTime → writeTime → waitT → recTimeRead → 
startTimeRead → waitRC → sample → readTime → wait1s → idle
```

**Features:**
- Handles 1-Wire reset, presence detection, and data conversion timing  
- Reads 12-bit temperature data and converts it to binary output  
- Refresh rate: 1 second  

📘 *Reference: Fig. 5 — FSM for DS18B20*

![DS18B20 FSM](../figures/ds18b20_fsm.png)

---

### 💧 DHT11 — Humidity Sensor FSM

**Purpose:** Manages single-wire communication with DHT11 sensor.

**FSM States:**
```
idle → start → release_bus → wait_response → ack → 
wait_transmission → begin_bit → timer → decode → idle
```

**Features:**
- Implements data frame of 40 bits (humidity + temperature + checksum)  
- Uses timing counters for 18 ms start pulse and bit-width decoding  
- Reads humidity data with 8-bit resolution  

📘 *Reference: Fig. 7 — FSM for DHT11*

![DHT11 FSM](../figures/dht11_state.png)

---

### 🌫️ MCP3202 — ADC SPI FSM

**Purpose:** Controls SPI communication with the 12-bit MCP3202 ADC used for air quality measurement.

**FSM States:**
```
IDLE → Input_mode → Read_data → Output_mode → done
```

**Features:**
- Initiates SPI conversion using chip select (CS)  
- Reads serial data (MISO) and outputs 12-bit digital signal  
- Used to digitize analog voltage from the air quality sensor  

📘 *Reference: Fig. 14 — FSM for MCP3202*

![MCP3202 FSM](../figures/mcp3202_state.png)

---

### 🖥️ LCD Display FSM

**Purpose:** Controls initialization and data writing to the LCD via an 8-bit parallel interface.

**FSM States:**
```
IDLE → Display_off → Display_update → Display_on → 
Clear_display → Data_state → Function_set → idle
```

**Features:**
- Sends control and data instructions (RS, RW, E signals)  
- Handles command sequence for initialization and display updates  
- Operates in 8-bit single-line mode  

📘 *Reference: Fig. 18 — FSM for LCD*

![LCD FSM](../figures/lcd_state.png)

---

### 🔤 UART Transmitter FSM

**Purpose:** Implements serial data transmission at 9600 baud.

**FSM States:**
```
idle → start_bit → write_data → stop_bit0 → stop_bit1 → idle
```

**Features:**
- Transmits 8-bit ASCII data per frame  
- Uses start and stop bits for framing  
- Clock divider generates 9600 Hz transmission clock  

📘 *Reference: Fig. 22 — FSM for UART Transmitter*

![UART FSM](../figures/uart_state.png)

---

## 🧠 Design Characteristics

| Feature | Description |
|----------|--------------|
| Language | VHDL (IEEE Std 1076-2008) |
| Simulation Tools | ModelSim |
| Synthesis Tools | Vivado |
| Target FPGA | Nexys A7-100T |
| Timing Base | 100 MHz System Clock |
| FSM Style | Synchronous, Moore-type |

---

## 🧾 Notes

- Each FSM module uses internal counters for timing generation.
- The `wrapper.vhd` integrates all submodules into the top-level entity.
- Simulation waveforms were validated using ModelSim for each FSM individually.

---

## 📚 References

1. DS18B20 — Maxim Integrated Datasheet  
2. DHT11 — OSEEP/Mouser Datasheet  
3. MCP3202 — Microchip Datasheet  
4. Nexys4DDR FPGA Board Reference Manual  
5. UART Protocol — Analog Dialogue (2020)  

---

© 2023 — *Chalmers University of Technology*
