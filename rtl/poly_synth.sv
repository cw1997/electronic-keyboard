// ============================================================================
// Polyphonic Synthesizer — OR Mixing for Passive Buzzer
//
// Description: 88-key fully polyphonic square-wave synthesizer.
//   Computes note frequencies at elaboration time, instantiates a freq_gen
//   per key, and ORs all square-wave outputs into
//   a 1-bit audio signal for a passive buzzer.
//
// Frequency formula:
//   freq[k] = round(440 * 2^((k - 48) / 12)),  k in [0, 87]
//
// Ports:
//   clk       - master clock input
//   rst_n     - asynchronous reset (active low)
//   keys[87:0] - 88 debounced key inputs (1 = pressed)
//   audio_out - 1-bit audio output (OR of all square waves, for passive buzzer)
// ============================================================================

module poly_synth #(
    parameter CLK_FREQ = 50000000  // System clock frequency (Hz)
) (
    input  wire        clk,         // Master clock input
    input  wire        rst_n,       // Asynchronous reset, active low
    input  wire [87:0] keys,        // Debounced key inputs (1 = pressed)
    output wire        audio_out    // 1-bit audio output to passive buzzer
);

    // ============================================================
    // 1. Square wave outputs
    // ============================================================
    wire [87:0] square_wires;

    genvar i;
    generate
        for (i = 0; i < 88; i = i + 1) begin : GEN_FREQ

            // ========================================================
            // NOTE FREQUENCY TABLE (fully static, Yosys-safe)
            // ========================================================
            localparam integer NOTE_FREQ_HZ =
                (i == 0)  ? 131 :
                (i == 1)  ? 139 :
                (i == 2)  ? 147 :
                (i == 3)  ? 156 :
                (i == 4)  ? 165 :
                (i == 5)  ? 175 :
                (i == 6)  ? 185 :
                (i == 7)  ? 196 :
                (i == 8)  ? 208 :
                (i == 9)  ? 220 :
                (i == 10) ? 233 :
                (i == 11) ? 247 :
                (i == 12) ? 262 :
                (i == 13) ? 277 :
                (i == 14) ? 294 :
                (i == 15) ? 311 :
                (i == 16) ? 330 :
                (i == 17) ? 349 :
                (i == 18) ? 370 :
                (i == 19) ? 392 :
                (i == 20) ? 415 :
                (i == 21) ? 440 :
                (i == 22) ? 466 :
                (i == 23) ? 494 :
                (i == 24) ? 523 :
                (i == 25) ? 554 :
                (i == 26) ? 587 :
                (i == 27) ? 622 :
                (i == 28) ? 659 :
                (i == 29) ? 698 :
                (i == 30) ? 740 :
                (i == 31) ? 784 :
                (i == 32) ? 831 :
                (i == 33) ? 880 :
                (i == 34) ? 932 :
                (i == 35) ? 988 :
                (i == 36) ? 1047 :
                (i == 37) ? 1109 :
                (i == 38) ? 1175 :
                (i == 39) ? 1245 :
                (i == 40) ? 1319 :
                (i == 41) ? 1397 :
                (i == 42) ? 1480 :
                (i == 43) ? 1568 :
                (i == 44) ? 1661 :
                (i == 45) ? 1760 :
                (i == 46) ? 1865 :
                (i == 47) ? 1976 :
                (i == 48) ? 2093 :
                (i == 49) ? 2217 :
                (i == 50) ? 2349 :
                (i == 51) ? 2489 :
                (i == 52) ? 2637 :
                (i == 53) ? 2794 :
                (i == 54) ? 2960 :
                (i == 55) ? 3136 :
                (i == 56) ? 3322 :
                (i == 57) ? 3520 :
                (i == 58) ? 3729 :
                (i == 59) ? 3951 :
                (i == 60) ? 4186 :
                (i == 61) ? 4435 :
                (i == 62) ? 4699 :
                (i == 63) ? 4978 :
                (i == 64) ? 5274 :
                (i == 65) ? 5588 :
                (i == 66) ? 5920 :
                (i == 67) ? 6272 :
                (i == 68) ? 6645 :
                (i == 69) ? 7040 :
                (i == 70) ? 7459 :
                (i == 71) ? 7902 :
                (i == 72) ? 8372 :
                (i == 73) ? 8870 :
                (i == 74) ? 9397 :
                (i == 75) ? 9956 :
                (i == 76) ? 10548 :
                (i == 77) ? 11175 :
                (i == 78) ? 11840 :
                (i == 79) ? 12544 :
                (i == 80) ? 13290 :
                (i == 81) ? 14080 :
                (i == 82) ? 14917 :
                (i == 83) ? 15804 :
                (i == 84) ? 16744 :
                (i == 85) ? 17740 :
                (i == 86) ? 18795 :
                (i == 87) ? 19912 :
                440;

            // ========================================================
            // freq_gen instance
            // ========================================================
            freq_gen #(
                .CLK_FREQ(CLK_FREQ),
                .NOTE_FREQ_HZ(NOTE_FREQ_HZ)
            ) u_freq_gen (
                .clk(clk),
                .rst_n(rst_n),
                .key_on(keys[i]),
                .square_out(square_wires[i])
            );

        end
    endgenerate

    // ============================================================
    // OR MIXING (passive buzzer output)
    // ============================================================
    assign audio_out = |square_wires;

endmodule
