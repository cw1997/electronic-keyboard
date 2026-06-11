// ============================================================================
// Electronic Keyboard — Top Level
//
// Description: 88-key fully polyphonic electronic keyboard.
//   - Debounces all 88 key inputs
//   - Feeds debounced keys to the polyphonic synthesizer
//   - Outputs 8-bit digital audio (square-wave sum)
//
// Architecture:
//   keys[87:0] → 88×debounce → poly_synth → audio_out[7:0]
//
// Frequency formula:
//   freq[k] = round(440 * 2^((k - 48) / 12)),  k in [0, 87]
//
// Ports:
//   clk          - master clock input
//   rst_n        - asynchronous reset (active low)
//   keys[87:0]   - 88 key inputs (async, 1 = pressed)
//   audio_out[7:0] - 8-bit audio output (square-wave sum, range 0~88)
//
// ASIC flow (OpenLane):
//   - Single clock domain, no gated clocks
//   - Asynchronous reset, no reset synchronizer needed
//   - No tri-state, no internal RAM, no internal oscillator
//   - SDC constraints file required for synthesis
// ============================================================================

module electronic_keyboard #(
    parameter CLK_FREQ = 50_000_000  // System clock frequency (Hz)
) (
    input  logic        clk,         // Master clock input
    input  logic        rst_n,       // Asynchronous reset, active low
    input  logic [87:0] keys,        // 88 key inputs (async, 1 = pressed)
    output logic [7:0]  audio_out    // 8-bit audio output to speaker (square-wave sum)
);

    // Debounced key outputs
    logic [87:0] keys_debounced;  // Debounced key signals (1 = pressed)

    // ========================================================================
    // Debounce bank — 88 instances, one per key
    // ========================================================================
    generate
        for (genvar i = 0; i < 88; i++) begin : gen_debounce
            debounce #(
                .CLK_FREQ(CLK_FREQ)
            ) u_debounce (
                .clk(clk),
                .rst_n(rst_n),
                .key_in(keys[i]),
                .key_out(keys_debounced[i])
            );
        end
    endgenerate

    // ========================================================================
    // Polyphonic synthesizer — instantiates 88 frequency generators and sums
    // ========================================================================
    poly_synth #(
        .CLK_FREQ(CLK_FREQ)
    ) u_poly_synth (
        .clk(clk),
        .rst_n(rst_n),
        .keys(keys_debounced),
        .audio_out(audio_out)
    );

endmodule
