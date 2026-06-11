// ============================================================================
// Electronic Keyboard Testbench — Self-checking simulation platform
//
// Tests:
//   1. Reset output goes to zero
//   2. Single-key frequency accuracy (A4=440Hz, C4=261.6Hz, C8=4186Hz)
//   3. Chord superposition (C4+E4+G4 C major triad)
//   4. Output zero when no key is pressed
//   5. All-keys-pressed boundary test
//
// Frequency measurement: measure one period of the output square wave,
// convert to frequency and compare with the expected value.
// Tolerance: +/-5%
// ============================================================================

`timescale 1ns / 1ps

module electronic_keyboard_tb;

    // ========================================================================
    // Parameters
    // ========================================================================
    parameter CLK_FREQ = 50_000_000;  // 50 MHz
    parameter CLK_NS   = 20;           // 20 ns period
    parameter DEBOUNCE_SETTLE_NS = 11_000_000;  // Wait longer than the 10 ms debounce filter
    parameter EDGE_TIMEOUT_CYCLES = CLK_FREQ / 10;  // 100 ms edge timeout for the lowest notes

    // ========================================================================
    // Signals
    // ========================================================================
    logic        clk;
    logic        rst_n;
    logic [87:0] keys;
    logic        audio_out;

    // Previous-cycle audio_out for edge detection (1-bit)
    logic        audio_out_d;
    integer      fail_count;

    // ========================================================================
    // DUT instantiation
    // ========================================================================
    electronic_keyboard #(
        .CLK_FREQ(CLK_FREQ)
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .keys     (keys),
        .audio_out(audio_out)
    );

    // ========================================================================
    // Clock generation
    // ========================================================================
    initial begin
        clk = 0;
        forever #(CLK_NS / 2) clk = ~clk;
    end

    // Always record the previous value of audio_out
    always_ff @(posedge clk) begin
        audio_out_d <= audio_out;
    end

    // ========================================================================
    // Main test sequence
    // ========================================================================
    initial begin
        $dumpfile("electronic_keyboard_tb.vcd");
        $dumpvars(0, electronic_keyboard_tb);

        $display("=== Electronic Keyboard Testbench Start ===");
        $display("CLK_FREQ = %0d Hz", CLK_FREQ);
        $display("");
        fail_count = 0;

        // 1) Reset test
        do_reset();
        check_audio_zero("Output should be zero after reset");

        // 2) Single key tests
        test_single_note(48, 440.000,   "A4 (440 Hz)");
        test_single_note(39, 261.626,   "C4 (261.6 Hz)");
        test_single_note(87, 4186.009,  "C8 (4186 Hz)");
        test_single_note(0,  27.500,    "A0 (27.5 Hz)");

        // 3) Chord test: C4 + E4 + G4 = C major triad
        test_chord();

        // 4) No key pressed
        check_audio_zero("Output should be zero after releasing all keys");

        // 5) All keys pressed
        test_all_keys();

        $display("");
        if (fail_count == 0) begin
            $display("=== PASS: All tests passed ===");
        end else begin
            $fatal(1, "=== FAIL: %0d test(s) failed ===", fail_count);
        end
        #500;
        $finish;
    end

    // ========================================================================
    // Reset
    // ========================================================================
    task do_reset();
        rst_n = 0;
        keys  = '0;
        #60;
        rst_n = 1;
        #100;
    endtask

    // ========================================================================
    // Check audio_out is zero
    // ========================================================================
    task check_audio_zero(string msg);
        #40;
        if (audio_out !== '0) begin
            fail_count++;
            $error("FAIL: %s (audio_out = %0d)", msg, audio_out);
        end else begin
            $display("PASS: %s", msg);
        end
    endtask

    // ========================================================================
    // Wait for debounce state to settle after changing raw key inputs
    // ========================================================================
    task wait_debounce_settle();
        #(DEBOUNCE_SETTLE_NS);
    endtask

    // ========================================================================
    // Wait until audio_out reaches a requested level, with a bounded timeout
    // ========================================================================
    task wait_audio_level(
        input  logic   expected_level,
        input  string  desc,
        output logic   found
    );
        integer cycle_idx;

        found = 1'b0;
        for (cycle_idx = 0; cycle_idx < EDGE_TIMEOUT_CYCLES && !found; cycle_idx++) begin
            @(posedge clk);
            #1;
            if (audio_out === expected_level) begin
                found = 1'b1;
            end
        end

        if (!found) begin
            fail_count++;
            $error("FAIL: Timeout waiting for audio_out=%0d during %s", expected_level, desc);
        end
    endtask

    // ========================================================================
    // Single-key frequency test
    //
    // Measure time between two consecutive rising edges (0->non-zero)
    // to obtain the square-wave period, then convert to frequency.
    // ========================================================================
    task test_single_note(
        input  integer key_idx,
        input  real    expected_freq,
        input  string  desc
    );
        integer t_rise1, t_rise2;
        real    period_ns;
        real    measured_freq;
        logic   found;

        // Press only one key
        keys = '0;
        wait_debounce_settle();
        keys[key_idx] = 1;
        wait_debounce_settle();

        // Measure between full rising edges after the debounced key is active.
        wait_audio_level(1'b0, desc, found);
        if (found) begin
            wait_audio_level(1'b1, desc, found);
        end
        if (found) begin
            t_rise1 = $time;

            wait_audio_level(1'b0, desc, found);
        end
        if (found) begin
            wait_audio_level(1'b1, desc, found);
        end
        if (found) begin
            t_rise2 = $time;

            period_ns     = real'(t_rise2 - t_rise1);
            measured_freq = 1_000_000_000.0 / period_ns;  // period_ns -> freq_Hz

            check_freq(key_idx, expected_freq, measured_freq, desc);
        end

        keys[key_idx] = 0;
        wait_debounce_settle();
        check_audio_zero("Output should be zero after single-key release");
    endtask

    // ========================================================================
    // Frequency check (+/-5% tolerance)
    // ========================================================================
    task check_freq(
        input integer key_idx,
        input real    expected,
        input real    measured,
        input string  desc
    );
        real err_ratio;

        err_ratio = (measured - expected) / expected;

        if (err_ratio < -0.05 || err_ratio > 0.05) begin
            fail_count++;
            $error("FAIL: %s (key %0d): expected %0.3f Hz, measured %0.3f Hz (error %0.2f%%)",
                   desc, key_idx, expected, measured, err_ratio * 100.0);
        end else begin
            $display("PASS: %s (key %0d): %0.3f Hz (expected %0.3f Hz, error %+0.2f%%)",
                     desc, key_idx, measured, expected, err_ratio * 100.0);
        end
    endtask

    // ========================================================================
    // Chord test
    // ========================================================================
    task test_chord();
        logic found;

        $display("--- Chord test (C4+E4+G4 C major triad) ---");
        keys = '0;
        wait_debounce_settle();

        // Press C4(39), E4(43), G4(46) simultaneously
        keys[39] = 1;
        keys[43] = 1;
        keys[46] = 1;
        wait_debounce_settle();
        wait_audio_level(1'b1, "chord press", found);

        // Verify output is non-zero
        if (found) begin
            $display("PASS: audio_out = %0d (non-zero) when chord is pressed", audio_out);
        end
        wait_audio_level(1'b0, "chord waveform low phase", found);
        wait_audio_level(1'b1, "chord waveform high phase", found);
        if (found) begin
            $display("PASS: Chord output waveform changes correctly");
        end

        // Release
        keys = '0;
        wait_debounce_settle();
        check_audio_zero("Output should be zero after chord release");
    endtask

    // ========================================================================
    // All-keys test
    // ========================================================================
    task test_all_keys();
        logic found;

        $display("--- All-keys test ---");
        keys = '0;
        wait_debounce_settle();

        // Press all 88 keys
        keys = {88{1'b1}};
        wait_debounce_settle();
        wait_audio_level(1'b1, "all-keys press", found);

        // Verify output is non-zero
        if (found) begin
            $display("PASS: audio_out is non-zero when all keys are pressed");
        end

        keys = '0;
        wait_debounce_settle();
        check_audio_zero("Output should be zero after releasing all keys");
    endtask

endmodule
