# AGENTS.md — Project Rules

## Comment Language

- All comments in source code **MUST** be written in English only.
- No Chinese or other non-English languages are allowed in comments, documentation strings, or commit messages within the codebase.
- This applies to all file types: SystemVerilog (.sv), C/C++ (.cpp/.c), Python (.py), Tcl (.tcl), Makefile, YAML (.yml), Markdown (.md), and any other source files.

## SystemVerilog / FPGA / ASIC Design Rules

### General

- Use `logic` type instead of `reg`/`wire` for all signals in SystemVerilog.
- Use `always_ff`, `always_comb`, and `always_latch` instead of generic `always`.
- Use `_n` suffix for active-low signals (e.g., `rst_n`).
- Keep the design single-clock-domain unless explicitly required otherwise.
- Do **not** use gated clocks; use clock enables instead.
- Do **not** use tri-state logic inside the module; use dedicated I/O cells for pad-level tri-state.
- Do **not** instantiate internal oscillators, RAMs, or ROMs unless part of the specification.
- All module/interface ports **MUST** have an end-of-line comment (//) explaining the port purpose in English.
  Parameters with non-obvious meaning also require an end-of-line comment.

### Parameters & Generics

- Use `parameter` or `localparam` for all configurable constants; avoid magic numbers.
- Use `genvar` and `generate` blocks for replicated structures.
- Compute lookup tables at elaboration time using functions (synthesizable) rather than external scripts.

### Reset

- Use asynchronous reset, active low (if applicable).
- Do **not** add reset synchronizers unless the design requires synchronous reset.
- Reset should only initialize control/state; avoid resetting datapath elements unless necessary.

### Synthesis & Constraints

- Provide SDC timing constraints for all clock domains.
- Use `set_false_path` for asynchronous reset signals.
- Specify input/output delays and clock uncertainty in SDC.
- Ensure all RTL passes lint checking (e.g., Verilator `--lint-only`).

### Testbenches

- Use self-checking testbenches with PASS/FAIL reporting.
- Measure output frequency by counting periods rather than relying on time-based assertions.
- Test at least: reset, single key, chord, all keys, boundary conditions.
- Use `$error()` for failures in SystemVerilog testbenches.

### Simulation

- Support both iverilog (direct SV testbench) and Verilator (C++ wrapper) flows.
- Makefile targets: `sim`, `sim-verilator`, `lint`, `clean`.
- Ensure all tests pass before committing.

### ASIC Flow (OpenLane)

- Place OpenLane config and SDC under `syn/openlane/` and `syn/`.
- Use `config.tcl` for OpenLane parameters, `config.json` for minimal overrides.
- Verify the design with: synthesis, floorplan, placement, CTS, routing, DRC, LVS, XOR.
- Aim for zero DRC violations at tape-out.

### FPGA Flow (Future)

- Use synchronous reset when targeting Altera/AMD FPGA primitives if recommended by the vendor.
- Consider block RAM for lookup tables if the key count grows.
- Add pin constraints (`.xdc` / `.qsf`) for the target board.

### Scripts

- Python scripts in `scripts/` should be standalone and self-documenting (`-h`/`--help`).
- Use `argparse` or `sys.argv` for command-line parameters.
- Use English-only comments and docstrings.
