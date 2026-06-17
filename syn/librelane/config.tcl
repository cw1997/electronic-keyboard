# ============================================================================
# OpenLane Configuration — electronic_keyboard
# ============================================================================

# Design name
set ::env(DESIGN_NAME) "electronic_keyboard"

# RTL file paths (relative to OpenLane working directory)
set ::env(VERILOG_FILES) "\
    $::env(DESIGN_DIR)/../../rtl/freq_gen.sv              \
    $::env(DESIGN_DIR)/../../rtl/debounce.sv              \
    $::env(DESIGN_DIR)/../../rtl/electronic_keyboard.sv"

# Clock port and period
set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) "20.0"

# Timing constraints
set ::env(SDC_FILE) "$::env(DESIGN_DIR)/../electronic_keyboard.sdc"

# Chip-level parameters
set ::env(DIE_AREA) "0 0 300 300"
set ::env(FP_SIZING) "absolute"
set ::env(FP_CORE_UTIL) 45
set ::env(FP_ASPECT_RATIO) 1

# Synthesis strategy
set ::env(SYNTH_STRATEGY) "AREA 0"

# Macros / black boxes (no macros in this design)
set ::env(VERILOG_INCLUDE_DIRS) ""

# IO configuration
set ::env(FP_IO_HMETAL) "4"
set ::env(FP_IO_VMETAL) "3"

# Power grid
set ::env(VDD_NETS) "VDD"
set ::env(GND_NETS) "VSS"
set ::env(FP_PDN_VPITCH) 100
set ::env(FP_PDN_HPITCH) 100

# Routing
set ::env(ROUTING_STRATEGY) 0
set ::env(GLB_RT_MAXLAYER) 6

# Result output
set ::env(MAGIC_ZEROIZE_ORIGIN) 0
set ::env(FP_PDN_ENABLE_RAILS) 1

# Signoff
set ::env(RUN_KLAYOUT_XOR) 1
set ::env(RUN_KLAYOUT_DRC) 1
set ::env(RUN_MAGIC_DRC) 1
set ::env(RUN_MAGIC_LVS) 1
