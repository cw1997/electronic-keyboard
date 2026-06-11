# ============================================================================
# Electronic Keyboard — Timing Constraints (Synopsys Design Constraints)
#
# Applicable flow: OpenLane / Yosys + OpenSTA
# ============================================================================

# Master clock definition
# CLK_FREQ = 50 MHz -> period 20 ns
# Note: update this period when CLK_FREQ parameter is changed
create_clock -name clk -period 20.000 [get_ports clk]

# Clock uncertainty (jitter + margin)
set_clock_uncertainty -setup 0.500 [get_clocks clk]
set_clock_uncertainty -hold  0.300 [get_clocks clk]

# Input delay
# keys signal from external keyboard matrix, assume 2 ns external delay
set_input_delay -clock clk -max 4.000 [get_ports keys]
set_input_delay -clock clk -min 1.000 [get_ports keys]

# Output delay
# audio_out connects to passive buzzer
set_output_delay -clock clk -max 4.000 [get_ports audio_out]
set_output_delay -clock clk -min 1.000 [get_ports audio_out]

# Asynchronous reset (false path)
set_false_path -setup -hold [get_ports rst_n]

# Output load
set_load -wire_load 0.05 [get_ports audio_out]
set_load -wire_load 0.05 [get_ports keys]

# Input transition time
set_input_transition -max 0.500 [get_ports keys]
