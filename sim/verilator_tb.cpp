// ============================================================================
// Electronic Keyboard — Verilator C++ Testbench
//
// Usage:
//   verilator --cc --sv --exe --trace --top electronic_keyboard \
//     ../rtl/electronic_keyboard.sv verilator_tb.cpp
//   make -C obj_dir -f Velectronic_keyboard.mk
//   ./obj_dir/Velectronic_keyboard
// ============================================================================

#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Velectronic_keyboard.h"

#include <cstdio>
#include <cmath>

vluint64_t main_time = 0;
const vluint64_t CLK_PERIOD = 20;    // 50 MHz -> 20 ns
const vluint64_t SIM_NS = 5000000;    // 5 ms total simulation time

double sc_time_stamp() { return main_time; }

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    Velectronic_keyboard* dut = new Velectronic_keyboard;
    VerilatedVcdC* trace = new VerilatedVcdC;
    dut->trace(trace, 99);
    trace->open("electronic_keyboard_verilator.vcd");

    int passed = 0, failed = 0;

    // ========================================================================
    // Helper functions
    // ========================================================================
    auto eval = [&]() { dut->eval(); };

    auto tick = [&]() {
        dut->clk = 0; eval(); trace->dump(main_time); main_time += CLK_PERIOD / 2;
        dut->clk = 1; eval(); trace->dump(main_time); main_time += CLK_PERIOD / 2;
    };

    auto wait_ns = [&](vluint64_t ns) {
        vluint64_t end = main_time + ns;
        while (main_time < end) tick();
    };

    auto wait_cycles = [&](int n) {
        for (int i = 0; i < n; i++) tick();
    };

    auto check_freq = [&](int key_idx, double expected_hz, const char* desc) {
        // Wait for output to settle and measure time between two rising edges
        int timeout = 100000;
        while (dut->audio_out == 0 && timeout-- > 0) wait_cycles(1);
        if (timeout <= 0) { printf("  FAIL: %s - no output\n", desc); failed++; return; }

        vluint64_t t1 = main_time;
        while (dut->audio_out != 0) wait_cycles(1);
        while (dut->audio_out == 0) wait_cycles(1);
        vluint64_t t2 = main_time;

        double period_ns = double(t2 - t1);
        double measured_hz = 1000.0 / period_ns;
        double err_pct = (measured_hz - expected_hz) / expected_hz * 100.0;

        if (fabs(err_pct) < 5.0) {
            printf("  PASS: %s - %.3f Hz (expected %.3f Hz, error %+.2f%%)\n",
                   desc, measured_hz, expected_hz, err_pct);
            passed++;
        } else {
            printf("  FAIL: %s - %.3f Hz (expected %.3f Hz, error %+.2f%%)\n",
                   desc, measured_hz, expected_hz, err_pct);
            failed++;
        }
    };

    // ========================================================================
    // Test sequence
    // ========================================================================
    printf("=== Electronic Keyboard Verilator Test ===\n\n");

    // 1) Reset
    dut->rst_n = 0;
    dut->keys = 0;
    wait_ns(100);
    dut->rst_n = 1;
    wait_ns(100);

    if (dut->audio_out == 0) {
        printf("  PASS: Output zero after reset\n"); passed++;
    } else {
        printf("  FAIL: Output should be zero after reset\n"); failed++;
    }

    // 2) Single key A4 (key 48, 440 Hz)
    printf("\n--- Single key test ---\n");
    dut->keys = 0;
    wait_ns(200);
    dut->keys = 1ull << 48;
    wait_ns(500);
    check_freq(48, 440.0, "A4 (440 Hz)");
    dut->keys = 0;

    // 3) Single key C4 (key 36, 261.6 Hz)
    dut->keys = 1ull << 36;
    wait_ns(500);
    check_freq(36, 261.626, "C4 (261.6 Hz)");
    dut->keys = 0;

    // 4) Chord C4+E4+G4
    printf("\n--- Chord test ---\n");
    dut->keys = (1ull << 36) | (1ull << 40) | (1ull << 43);
    wait_ns(1000);
    if (dut->audio_out != 0) {
        printf("  PASS: Chord output non-zero (audio_out=%d)\n", dut->audio_out);
        passed++;
    } else {
        printf("  FAIL: Chord output should not be zero\n");
        failed++;
    }
    dut->keys = 0;

    // 5) All keys test
    printf("\n--- All keys test ---\n");
    dut->keys = ~0ull;   // Lower 64 bits
    for (int i = 64; i < 88; i++) dut->keys |= (1ull << i);  // Upper 24 bits
    wait_ns(500);
    if (dut->audio_out != 0) {
        printf("  PASS: All-keys output non-zero\n");
        passed++;
    } else {
        printf("  FAIL: All-keys output should not be zero\n");
        failed++;
    }
    dut->keys = 0;
    wait_ns(200);
    if (dut->audio_out == 0) {
        printf("  PASS: Output zero after releasing all keys\n");
        passed++;
    } else {
        printf("  FAIL: Output should be zero after releasing all keys\n");
        failed++;
    }

    // ========================================================================
    // Results
    // ========================================================================
    printf("\n=== Results: %d passed, %d failed ===\n", passed, failed);

    trace->close();
    delete dut;

    return (failed > 0) ? 1 : 0;
}
