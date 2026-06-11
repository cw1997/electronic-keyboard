// ============================================================================
// Polyphonic Synthesizer — PWM Summing Version
//
// Description: 88-key fully polyphonic square-wave synthesizer.
//   Computes the integer frequency (Hz) for each of the 88 keys at
//   elaboration time, instantiates a freq_gen per key, and sums all
//   square-wave outputs into an 8-bit audio signal (for PWM DAC).
//
// Frequency formula:
//   freq[k] = round(440 * 2^((k - 48) / 12)),  k in [0, 87]
//
// Frequency calculation:
//   Uses Q16.16 fixed-point semitone ratio lookup table.  All 88 note
//   frequencies are computed at elaboration time by calc_note_freq_hz(),
//   without external scripts or pre-generated arrays.
//
// Ports:
//   clk         - master clock input
//   rst_n       - asynchronous reset (active low)
//   keys[87:0]  - 88 debounced key inputs (1 = pressed)
//   audio_out[7:0] - 8-bit audio output (square-wave sum, range 0~88)
// ============================================================================

module poly_synth_pwn #(
    parameter CLK_FREQ = 50_000_000  // System clock frequency (Hz)
) (
    input  logic        clk,         // Master clock input
    input  logic        rst_n,       // Asynchronous reset, active low
    input  logic [87:0] keys,        // Debounced key inputs (1 = pressed)
    output logic [7:0]  audio_out    // 8-bit audio output (square-wave sum)
);

    // 12-TET semitone ratio lookup table (Q16.16 fixed-point)
    //   ratio[s] = round(2^(s/12) * 2^16),  s in [0, 11]
    localparam int SEMITONE_RATIO [12] = '{
        32'd65536,   // 2^( 0/12) = 1.000000
        32'd69420,   // 2^( 1/12) ~ 1.059463
        32'd73534,   // 2^( 2/12) ~ 1.122462
        32'd77909,   // 2^( 3/12) ~ 1.189207
        32'd82571,   // 2^( 4/12) ~ 1.259921
        32'd87453,   // 2^( 5/12) ~ 1.334840
        32'd92635,   // 2^( 6/12) ~ 1.414214
        32'd98142,   // 2^( 7/12) ~ 1.498307
        32'd103963,  // 2^( 8/12) ~ 1.587401
        32'd110148,  // 2^( 9/12) ~ 1.681793
        32'd116669,  // 2^(10/12) ~ 1.781797
        32'd123592   // 2^(11/12) ~ 1.887749
    };

    // Calculates the integer note frequency (Hz) for a given key index.
    // Algorithm:
    //   1. A4 base in Q16.16: base = round(440 * 2^16)
    //   2. Apply semitone:  result = result * ratio[semitone] / 2^16
    //   3. Shift by octave: result = result * 2^octave
    //   4. Round Q16.16 to integer: result = (result + 2^15) / 2^16
    function automatic int calc_note_freq_hz(int key_idx);
        int offset   = key_idx - 48;
        int octave   = offset / 12;
        int semitone = offset % 12;
        bit signed [63:0] result;

        if (semitone < 0) begin
            semitone += 12;
            octave   -= 1;
        end

        // base = round(440 * 2^16) = 28835840
        result = 64'd28835840;

        // result = round(result * ratio[semitone] / 65536)
        result = (result * 64'(SEMITONE_RATIO[semitone]) + 64'(32768)) / 64'(65536);

        // result = result * 2^octave
        if (octave >= 0) begin
            result = result << octave;
        end else begin
            result = result >> (-octave);
        end

        // Round Q16.16 to nearest integer
        result = (result + 64'(32768)) / 64'(65536);

        return int'(result);
    endfunction

    // Note frequency lookup table (integer Hz, generated at elaboration time)
    localparam int NOTE_FREQ_HZ [88] = '{
        calc_note_freq_hz(0),  calc_note_freq_hz(1),  calc_note_freq_hz(2),  calc_note_freq_hz(3),  calc_note_freq_hz(4),  calc_note_freq_hz(5),
        calc_note_freq_hz(6),  calc_note_freq_hz(7),  calc_note_freq_hz(8),  calc_note_freq_hz(9),  calc_note_freq_hz(10), calc_note_freq_hz(11),
        calc_note_freq_hz(12), calc_note_freq_hz(13), calc_note_freq_hz(14), calc_note_freq_hz(15), calc_note_freq_hz(16), calc_note_freq_hz(17),
        calc_note_freq_hz(18), calc_note_freq_hz(19), calc_note_freq_hz(20), calc_note_freq_hz(21), calc_note_freq_hz(22), calc_note_freq_hz(23),
        calc_note_freq_hz(24), calc_note_freq_hz(25), calc_note_freq_hz(26), calc_note_freq_hz(27), calc_note_freq_hz(28), calc_note_freq_hz(29),
        calc_note_freq_hz(30), calc_note_freq_hz(31), calc_note_freq_hz(32), calc_note_freq_hz(33), calc_note_freq_hz(34), calc_note_freq_hz(35),
        calc_note_freq_hz(36), calc_note_freq_hz(37), calc_note_freq_hz(38), calc_note_freq_hz(39), calc_note_freq_hz(40), calc_note_freq_hz(41),
        calc_note_freq_hz(42), calc_note_freq_hz(43), calc_note_freq_hz(44), calc_note_freq_hz(45), calc_note_freq_hz(46), calc_note_freq_hz(47),
        calc_note_freq_hz(48), calc_note_freq_hz(49), calc_note_freq_hz(50), calc_note_freq_hz(51), calc_note_freq_hz(52), calc_note_freq_hz(53),
        calc_note_freq_hz(54), calc_note_freq_hz(55), calc_note_freq_hz(56), calc_note_freq_hz(57), calc_note_freq_hz(58), calc_note_freq_hz(59),
        calc_note_freq_hz(60), calc_note_freq_hz(61), calc_note_freq_hz(62), calc_note_freq_hz(63), calc_note_freq_hz(64), calc_note_freq_hz(65),
        calc_note_freq_hz(66), calc_note_freq_hz(67), calc_note_freq_hz(68), calc_note_freq_hz(69), calc_note_freq_hz(70), calc_note_freq_hz(71),
        calc_note_freq_hz(72), calc_note_freq_hz(73), calc_note_freq_hz(74), calc_note_freq_hz(75), calc_note_freq_hz(76), calc_note_freq_hz(77),
        calc_note_freq_hz(78), calc_note_freq_hz(79), calc_note_freq_hz(80), calc_note_freq_hz(81), calc_note_freq_hz(82), calc_note_freq_hz(83),
        calc_note_freq_hz(84), calc_note_freq_hz(85), calc_note_freq_hz(86), calc_note_freq_hz(87)
    };

    // Square wave outputs from each freq_gen
    logic [87:0] square_wires;  // 88 square wave signals from freq_gen instances

    generate
        for (genvar i = 0; i < 88; i++) begin : gen_freq
            freq_gen #(
                .CLK_FREQ(CLK_FREQ),
                .NOTE_FREQ_HZ(NOTE_FREQ_HZ[i])
            ) u_freq_gen (
                .clk(clk),
                .rst_n(rst_n),
                .key_on(keys[i]),
                .square_out(square_wires[i])
            );
        end
    endgenerate

    // Sum all square-wave outputs into 8-bit audio (for PWM DAC)
    always_comb begin
        audio_out = '0;
        for (int i = 0; i < 88; i++) begin
            audio_out = audio_out + square_wires[i];
        end
    end

endmodule
