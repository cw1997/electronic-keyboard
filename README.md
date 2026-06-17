# Electronic Keyboard

**SystemVerilog RTL Design | 88-key Fully Polyphonic | ASIC (LibreLane / sky130) Ready**

## Overview

This project implements the digital logic core of an 88-key fully polyphonic electronic keyboard in SystemVerilog, targeting ASIC (LibreLane on the [sky130](https://github.com/google/skywater-pdk) open PDK) and future FPGA platforms. It drives a **passive buzzer** with 1-bit OR-mixed square waves.

### Features

- 88-key standard piano layout (A0–C8), 12-TET tuning
- Fully polyphonic (all keys can be pressed simultaneously), each key has an independent frequency generator
- Debounced inputs with configurable debounce time (default 10 ms)
- 1-bit digital audio output (OR-mixed square waves, drives a passive buzzer directly)
- Parametric master clock frequency (default 50 MHz)
- Single clock domain, asynchronous reset
- Note frequencies (Hz) and half-period counters computed at elaboration time from integer constants — no floating-point, no external scripts required for synthesis

### Block Diagram

```
                    ┌───────────────────────────────────────────────────┐
 keys[87:0] ──────► │                                                   │
                    │    ┌──────────┐    ┌───────────┐                  │
                    │    │Debounce  │    │Freq Gen   │                  │
                    │    │ [0] ────────►  [0] ──────►│ square_wires[0] │
                    │    └──────────┘    └───────────┘                  │
                    │         ...              ...                      │
                    │    ┌──────────┐    ┌───────────┐                  │
                    │    │Debounce  │    │Freq Gen   │                  │
                    │    │ [87] ────────► [87] ──────►│ square_wires[87]│
                    │    └──────────┘    └───────────┘                  │
                    │                          │                        │
                    │                          ▼                        │
                    │              ┌─────────────────────┐             │
                    │              │  OR tree (88→1)     │             │
                    │              │  audio_out = |wires │             │
                    │              └────────┬────────────┘             │
                    └───────────────────────┼───────────────────────────┘
                                            ▼
                                     audio_out  (1-bit)
```

### Module Hierarchy

```
electronic_keyboard
├── debounce × 88        — debounce each key input
└── freq_gen × 88        — generate square wave per key (OR-mixed)
```

### Module Ports

| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `clk` | input | 1 | Master clock |
| `rst_n` | input | 1 | Asynchronous reset (active low) |
| `keys` | input | 88 | Key inputs, `keys[k]=1` means key k is pressed |
| `audio_out` | output | 1 | Digital audio output to passive buzzer |

### Key Mapping

| Key Index k | Note | Frequency (Hz) |
|-------------|------|----------------|
| 0 | A0 | 27.500 |
| 1 | A#0 | 29.135 |
| 2 | B0 | 30.868 |
| 3 | C1 | 32.703 |
| 4 | C#1 | 34.648 |
| 5 | D1 | 36.708 |
| 6 | D#1 | 38.891 |
| 7 | E1 | 41.203 |
| 8 | F1 | 43.654 |
| 9 | F#1 | 46.249 |
| 10 | G1 | 48.999 |
| 11 | G#1 | 51.913 |
| 12 | A1 | 55.000 |
| 13 | A#1 | 58.270 |
| 14 | B1 | 61.735 |
| 15 | C2 | 65.406 |
| 16 | C#2 | 69.296 |
| 17 | D2 | 73.416 |
| 18 | D#2 | 77.782 |
| 19 | E2 | 82.407 |
| 20 | F2 | 87.307 |
| 21 | F#2 | 92.499 |
| 22 | G2 | 97.999 |
| 23 | G#2 | 103.826 |
| 24 | A2 | 110.000 |
| 25 | A#2 | 116.541 |
| 26 | B2 | 123.471 |
| 27 | C3 | 130.813 |
| 28 | C#3 | 138.591 |
| 29 | D3 | 146.832 |
| 30 | D#3 | 155.563 |
| 31 | E3 | 164.814 |
| 32 | F3 | 174.614 |
| 33 | F#3 | 184.997 |
| 34 | G3 | 195.998 |
| 35 | G#3 | 207.652 |
| 36 | A3 | 220.000 |
| 37 | A#3 | 233.082 |
| 38 | B3 | 246.942 |
| 39 | C4 | 261.626 |
| 40 | C#4 | 277.183 |
| 41 | D4 | 293.665 |
| 42 | D#4 | 311.127 |
| 43 | E4 | 329.628 |
| 44 | F4 | 349.228 |
| 45 | F#4 | 369.994 |
| 46 | G4 | 391.995 |
| 47 | G#4 | 415.305 |
| 48 | A4 | 440.000 |
| 49 | A#4 | 466.164 |
| 50 | B4 | 493.883 |
| 51 | C5 | 523.251 |
| 52 | C#5 | 554.365 |
| 53 | D5 | 587.330 |
| 54 | D#5 | 622.254 |
| 55 | E5 | 659.255 |
| 56 | F5 | 698.456 |
| 57 | F#5 | 739.989 |
| 58 | G5 | 783.991 |
| 59 | G#5 | 830.609 |
| 60 | A5 | 880.000 |
| 61 | A#5 | 932.328 |
| 62 | B5 | 987.767 |
| 63 | C6 | 1046.502 |
| 64 | C#6 | 1108.731 |
| 65 | D6 | 1174.659 |
| 66 | D#6 | 1244.508 |
| 67 | E6 | 1318.510 |
| 68 | F6 | 1396.913 |
| 69 | F#6 | 1479.978 |
| 70 | G6 | 1567.982 |
| 71 | G#6 | 1661.219 |
| 72 | A6 | 1760.000 |
| 73 | A#6 | 1864.655 |
| 74 | B6 | 1975.533 |
| 75 | C7 | 2093.005 |
| 76 | C#7 | 2217.461 |
| 77 | D7 | 2349.318 |
| 78 | D#7 | 2489.016 |
| 79 | E7 | 2637.020 |
| 80 | F7 | 2793.826 |
| 81 | F#7 | 2959.955 |
| 82 | G7 | 3135.963 |
| 83 | G#7 | 3322.438 |
| 84 | A7 | 3520.000 |
| 85 | A#7 | 3729.310 |
| 86 | B7 | 3951.066 |
| 87 | C8 | 4186.009 |

> RTL uses integer-rounded Hz values derived from the 12-TET formula above (e.g. A4 → 440 Hz, C8 → 4186 Hz). The table lists the theoretical target frequencies.

### Frequency Generation Principle

Each key has a dedicated `freq_gen` with a half-period counter:

```
freq[k]      = round(440 × 2^((k − 48) / 12))        (Hz)
half_period  = round(CLK_FREQ / (2 × freq[k]))        (clock cycles per half-cycle)

Per cycle:     counter += (key_on) ? 1 : 0
At half_period: square_out = ~square_out; counter = 0
Audio output:  audio_out = square_wires[0] | ... | square_wires[87]
```

**Note frequency table**: `electronic_keyboard` instantiates 88 `freq_gen` blocks via a `generate` loop. Each instance receives a `localparam` `NOTE_FREQ_HZ` (integer Hz, rounded from the 12-TET formula). `freq_gen` then derives `HALF_PERIOD` at elaboration time. No runtime lookup, floating-point, or external generation scripts are needed for synthesis.

## Simulation

### Requirements

| Tool | Purpose |
|------|---------|
| **iverilog** (>= 11) | SystemVerilog testbench simulation |
| **Verilator** (>= 5.0) | Fast C++-wrapped simulation + lint |
| **GTKWave** | VCD waveform viewer |

### Run Simulation

```bash
cd sim

# iverilog (recommended, runs SV testbench directly, default 1 MHz for faster sim)
make sim

# Verilator (C++ testbench wrapper, same default simulation clock)
make sim-verilator

# Optional: use hardware-like 50 MHz clock
make sim SIM_CLK_FREQ=50000000
make sim-verilator SIM_CLK_FREQ=50000000

# Lint only
make lint

# View waveform
make sim-vcd

# Clean build artifacts
make clean
```

### iverilog Example Output

```
=== Electronic Keyboard Testbench Start ===
CLK_FREQ = 1000000 Hz

PASS: Output should be zero after reset
PASS: A4 (440 Hz) (key 48): 440.141 Hz (expected 440.000 Hz, error +0.03%)
PASS: C4 (261.6 Hz) (key 39): 261.575 Hz (expected 261.626 Hz, error -0.02%)
PASS: C8 (4186 Hz) (key 87): 4166.667 Hz (expected 4186.009 Hz, error -0.46%)
PASS: A0 (27.5 Hz) (key 0): 27.500 Hz (expected 27.500 Hz, error +0.00%)
PASS: Chord output waveform changes correctly
PASS: All keys pressed audio_out changes

=== PASS: All tests passed ===
```

### CI

GitHub Actions automatically verifies every push and pull request using Verilator and iverilog on Ubuntu (see `.github/workflows/verify-and-synth.yml`).

## ASIC Flow (LibreLane / sky130)

The design has been taken through the full LibreLane RTL-to-GDS flow on the sky130 HD standard-cell library (`sky130_fd_sc_hd`).

### Design Readiness Checklist

| Item | Status |
|------|--------|
| Single clock domain | ✓ |
| No gated clocks | ✓ |
| No tri-state logic | ✓ |
| No internal RAM / ROM | ✓ |
| No internal oscillator | ✓ |
| Asynchronous reset input | ✓ |
| SDC constraints file | `syn/electronic_keyboard.sdc` |
| LibreLane configuration | `syn/librelane/config.json`, `syn/librelane/config.tcl` |

### Run LibreLane

Requires [LibreLane](https://github.com/librelane/librelane) with the sky130 PDK installed (e.g. via [ciel](https://github.com/fossi-foundation/ciel)).

```bash
cd syn/librelane
librelane config.json
```

Flow outputs are written to `syn/librelane/runs/`. Final GDS, LEF, DEF, and signoff reports are under each run's `final/` directory.

### Signoff Results (sky130, 50 MHz)

Representative results from a successful full flow run:

| Metric | Value |
|--------|-------|
| PDK / stdcell | sky130_fd_sc_hd |
| Clock period | 20 ns (50 MHz) |
| Die size | 615 × 626 µm |
| Core utilization | 60.4 % |
| Sequential cells (DFF) | 3,696 |
| Logic stdcells | 22,147 |
| Setup / hold violations | 0 / 0 |
| Magic DRC errors | 0 |
| KLayout DRC errors | 0 |
| LVS errors | 0 |
| XOR differences | 0 |

### RTL Resource Estimate

| Resource | Count | Description |
|----------|-------|-------------|
| Flip-flops (DFF) | ~3,700 | 88 × (21-bit counter + 1 output reg + debounce counter + 1 output reg) |
| 2:1 MUX | ~88 | Key enable selection per `freq_gen` |
| Comparators | 88 × 21-bit | Half-period compare per `freq_gen` |
| OR tree | 88:1 × 1-bit | Square-wave OR mixing |

### Tape-out Considerations

1. **Clock tree**: Single clock domain at 50 MHz (20 ns period). Post-route setup slack is positive across PVT corners.
2. **Power**: 88 counters switching simultaneously may cause significant dynamic power. The existing `key_on` gating already disables counters when a key is released.
3. **Area**: ~615 × 626 µm die on sky130 HD after place-and-route. IO count is 91 signal pins plus power/ground.
4. **DFT**: Consider adding scan chains before tape-out. This design is pure synchronous logic, making DFT insertion relatively simple.
5. **IO**: `keys[87:0]` = 88 inputs + 1 clock + 1 reset + 1 audio = 91 IO. If IO count is limited, consider external serial keyboard matrix scanning (add a scan controller in RTL).
6. **POR**: Use an external or on-chip POR (power-on reset) circuit to drive `rst_n`.
7. **Pad frame**: This repository contains the digital core only. Pad cells and level shifters must be added for chip-level tape-out.

## Project Structure

```
├── rtl/
│   ├── electronic_keyboard.sv       # Top-level module (debounce + 88×freq_gen)
│   ├── debounce.sv                  # Key debounce (counter-based, 10 ms default)
│   └── freq_gen.sv                  # Square-wave frequency generator
├── tb/
│   └── electronic_keyboard_tb.sv    # Self-checking testbench (SystemVerilog)
├── sim/
│   ├── Makefile                     # Simulation Makefile (iverilog / Verilator)
│   └── verilator_tb.cpp             # Verilator C++ testbench wrapper
├── syn/
│   ├── electronic_keyboard.sdc      # Timing constraints
│   └── librelane/
│       ├── config.json              # LibreLane minimal configuration
│       └── config.tcl               # LibreLane extended configuration
├── scripts/
│   └── calc_freq.py                 # Optional: validate 12-TET vs half-period frequencies
├── .github/workflows/
│   └── verify-and-synth.yml         # CI simulation and LibreLane synthesis
├── .gitignore
├── AGENTS.md
├── LICENSE                          # Apache 2.0
└── README.md
```

## License

Apache License 2.0 — see [LICENSE](LICENSE).
