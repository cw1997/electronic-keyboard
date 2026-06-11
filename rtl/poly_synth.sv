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

`timescale 1ns / 1ps

module poly_synth #(
    parameter CLK_FREQ = 50000000  // System clock frequency (Hz)
) (
    input  logic        clk,         // Master clock input
    input  logic        rst_n,       // Asynchronous reset, active low
    input  logic [87:0] keys,        // Debounced key inputs (1 = pressed)
    output logic        audio_out    // 1-bit audio output to passive buzzer
);

    // ============================================================
    // 1. Square wave outputs
    // ============================================================
    logic [87:0] square_wires;

    genvar i;
    generate
        for (i = 0; i < 88; i = i + 1) begin : GEN_FREQ

            // ========================================================
            // NOTE FREQUENCY TABLE — 88 keys A0–C8
            // freq(k) = round(440 * 2^((k - 48) / 12))
            // ========================================================
            localparam integer NOTE_FREQ_HZ =
                (i == 0)  ? 28 :
                (i == 1)  ? 29 :
                (i == 2)  ? 31 :
                (i == 3)  ? 33 :
                (i == 4)  ? 35 :
                (i == 5)  ? 37 :
                (i == 6)  ? 39 :
                (i == 7)  ? 41 :
                (i == 8)  ? 44 :
                (i == 9)  ? 46 :
                (i == 10) ? 49 :
                (i == 11) ? 52 :
                (i == 12) ? 55 :
                (i == 13) ? 58 :
                (i == 14) ? 62 :
                (i == 15) ? 65 :
                (i == 16) ? 69 :
                (i == 17) ? 73 :
                (i == 18) ? 78 :
                (i == 19) ? 82 :
                (i == 20) ? 87 :
                (i == 21) ? 92 :
                (i == 22) ? 98 :
                (i == 23) ? 104 :
                (i == 24) ? 110 :
                (i == 25) ? 117 :
                (i == 26) ? 123 :
                (i == 27) ? 131 :
                (i == 28) ? 139 :
                (i == 29) ? 147 :
                (i == 30) ? 156 :
                (i == 31) ? 165 :
                (i == 32) ? 175 :
                (i == 33) ? 185 :
                (i == 34) ? 196 :
                (i == 35) ? 208 :
                (i == 36) ? 220 :
                (i == 37) ? 233 :
                (i == 38) ? 247 :
                (i == 39) ? 262 :
                (i == 40) ? 277 :
                (i == 41) ? 294 :
                (i == 42) ? 311 :
                (i == 43) ? 330 :
                (i == 44) ? 349 :
                (i == 45) ? 370 :
                (i == 46) ? 392 :
                (i == 47) ? 415 :
                (i == 48) ? 440 :
                (i == 49) ? 466 :
                (i == 50) ? 494 :
                (i == 51) ? 523 :
                (i == 52) ? 554 :
                (i == 53) ? 587 :
                (i == 54) ? 622 :
                (i == 55) ? 659 :
                (i == 56) ? 698 :
                (i == 57) ? 740 :
                (i == 58) ? 784 :
                (i == 59) ? 831 :
                (i == 60) ? 880 :
                (i == 61) ? 932 :
                (i == 62) ? 988 :
                (i == 63) ? 1047 :
                (i == 64) ? 1109 :
                (i == 65) ? 1175 :
                (i == 66) ? 1245 :
                (i == 67) ? 1319 :
                (i == 68) ? 1397 :
                (i == 69) ? 1480 :
                (i == 70) ? 1568 :
                (i == 71) ? 1661 :
                (i == 72) ? 1760 :
                (i == 73) ? 1865 :
                (i == 74) ? 1976 :
                (i == 75) ? 2093 :
                (i == 76) ? 2217 :
                (i == 77) ? 2349 :
                (i == 78) ? 2489 :
                (i == 79) ? 2637 :
                (i == 80) ? 2794 :
                (i == 81) ? 2960 :
                (i == 82) ? 3136 :
                (i == 83) ? 3322 :
                (i == 84) ? 3520 :
                (i == 85) ? 3729 :
                (i == 86) ? 3951 :
                (i == 87) ? 4186 :
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
