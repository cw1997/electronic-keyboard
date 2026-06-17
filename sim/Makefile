# ============================================================================
# Electronic Keyboard — Simulation Makefile
#
# Tool support:
#   make sim            — compile and run with iverilog
#   make sim-verilator  — compile and run with Verilator (C++ wrapper)
#   make sim SIM_CLK_FREQ=50000000           — run at 50 MHz (hardware-like)
#   make sim-verilator SIM_CLK_FREQ=50000000 — same for Verilator
#   make lint           — run lint check with Verilator
#   make sim-vcd        — run and open waveform
#   make clean          — clean temporary files
# ============================================================================

IVERILOG     = iverilog
VVP          = vvp
VERILATOR    = verilator
GTKWAVE      = gtkwave

TOP          = electronic_keyboard_tb
TOP_MODULE   = electronic_keyboard
SIM_CLK_FREQ ?= 1000000
# Use a slower default simulation clock to reduce event count and runtime.
# Override with SIM_CLK_FREQ=50000000 when hardware-equivalent clocking is needed.
SRC_DIR      = ../rtl
TB_DIR       = ../tb
BUILD_DIR    = build
OBJ_DIR      = obj_dir

RTL_FILES    = $(wildcard $(SRC_DIR)/*.sv)
TB_FILES     = $(TB_DIR)/electronic_keyboard_tb.sv
VCD_FILE     = $(TOP).vcd
VCD_VERILATOR = electronic_keyboard_verilator.vcd

all: sim

# ------------------------------------------------------------------
# iverilog simulation
# ------------------------------------------------------------------
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

sim: $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -P$(TOP).CLK_FREQ=$(SIM_CLK_FREQ) \
		-o $(BUILD_DIR)/$(TOP).vvp $(RTL_FILES) $(TB_FILES)
	$(VVP) $(BUILD_DIR)/$(TOP).vvp

sim-vcd: sim
	$(GTKWAVE) $(VCD_FILE)

# ------------------------------------------------------------------
# Verilator simulation (C++ testbench wrapper)
# ------------------------------------------------------------------
sim-verilator: $(BUILD_DIR)
	$(VERILATOR) --cc --sv --exe --trace \
		--top $(TOP_MODULE) \
		-GCLK_FREQ=$(SIM_CLK_FREQ) \
		-CFLAGS "-DSIM_CLK_FREQ=$(SIM_CLK_FREQ)" \
		$(RTL_FILES) verilator_tb.cpp \
		-o $(BUILD_DIR)/$(TOP_MODULE)_sim
	make -C $(OBJ_DIR) -f V$(TOP_MODULE).mk
	./$(OBJ_DIR)/$(TOP_MODULE)_sim

# ------------------------------------------------------------------
# Verilator lint (no simulation code generation)
# ------------------------------------------------------------------
lint:
	$(VERILATOR) --lint-only --sv $(RTL_FILES)

# ------------------------------------------------------------------
# Clean
# ------------------------------------------------------------------
clean:
	rm -rf $(BUILD_DIR) $(OBJ_DIR)
	rm -f $(VCD_FILE) $(VCD_VERILATOR)

.PHONY: all sim sim-vcd sim-verilator lint clean
