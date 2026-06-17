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

#ifndef SIM_CLK_FREQ
#define SIM_CLK_FREQ 50000000ULL
#endif

vluint64_t main_time = 0;
const vluint64_t CLK_FREQ_HZ = SIM_CLK_FREQ;
const vluint64_t CLK_PERIOD_NS = (CLK_FREQ_HZ > 0) ? (1'000'000'000ULL / CLK_FREQ_HZ) : 20ULL;
const vluint64_t CLK_HALF_PERIOD_NS = (CLK_PERIOD_NS > 1) ? (CLK_PERIOD_NS / 2) : 1;
const vluint64_t DEBOUNCE_SETTLE_NS = 11'000'000;  // Wait longer than the 10 ms debounce filter
const int EDGE_TIMEOUT_CYCLES = static_cast<int>((CLK_FREQ_HZ >= 10) ? (CLK_FREQ_HZ / 10) : 1);  // 100 ms

double sc_time_stamp() { return main_time; }

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    Velectronic_keyboard* dut = new Velectronic_keyboard;
    VerilatedVcdC* trace = new VerilatedVcdC;
    dut->trace(trace, 99);
    trace->open("electronic_keyboard_verilator.vcd");

    int passed = 0, failed = 0;

    auto eval = [&]() { dut->eval(); };

    auto tick = [&]() {
        dut->clk = 0; eval(); trace->dump(main_time); main_time += CLK_HALF_PERIOD_NS;
        dut->clk = 1; eval(); trace->dump(main_time); main_time += CLK_HALF_PERIOD_NS;
    };

    auto wait_ns = [&](vluint64_t ns) {
        vluint64_t end = main_time + ns;
        while (main_time < end) tick();
    };

    auto wait_cycles = [&](int n) {
        for (int i = 0; i < n; i++) tick();
    };

    auto wait_debounce_settle = [&]() {
        wait_ns(DEBOUNCE_SETTLE_NS);
    };

    auto wait_audio_level = [&](int expected_level, const char* desc) -> bool {
        for (int i = 0; i < EDGE_TIMEOUT_CYCLES; i++) {
            tick();
            if (dut->audio_out == expected_level) return true;
        }
        printf("  FAIL: Timeout waiting for audio_out=%d during %s\n", expected_level, desc);
        return false;
    };

    auto check_freq = [&](int key_idx, double expected_hz, const char* desc) {
        (void)key_idx;

        if (!wait_audio_level(0, desc)) { failed++; return; }
        if (!wait_audio_level(1, desc)) { failed++; return; }
        vluint64_t t1 = main_time;

        if (!wait_audio_level(0, desc)) { failed++; return; }
        if (!wait_audio_level(1, desc)) { failed++; return; }
        vluint64_t t2 = main_time;

        double period_ns = static_cast<double>(t2 - t1);
        double measured_hz = 1'000'000'000.0 / period_ns;
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

    printf("=== Electronic Keyboard Verilator Test ===\n\n");
    printf("CLK_FREQ = %llu Hz\n\n", static_cast<unsigned long long>(CLK_FREQ_HZ));

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
    wait_debounce_settle();
    dut->keys = 1ull << 48;
    wait_debounce_settle();
    check_freq(48, 440.0, "A4 (440 Hz)");
    dut->keys = 0;
    wait_debounce_settle();

    // 3) Single key C4 (key 39, 261.6 Hz)
    dut->keys = 1ull << 39;
    wait_debounce_settle();
    check_freq(39, 261.626, "C4 (261.6 Hz)");
    dut->keys = 0;
    wait_debounce_settle();

    // 4) Chord C4+E4+G4
    printf("\n--- Chord test ---\n");
    dut->keys = (1ull << 39) | (1ull << 43) | (1ull << 46);
    wait_debounce_settle();
    if (wait_audio_level(1, "chord press")) {
        printf("  PASS: Chord output non-zero (audio_out=%d)\n", dut->audio_out);
        passed++;
    } else {
        failed++;
    }
    dut->keys = 0;
    wait_debounce_settle();

    // 5) All keys test
    printf("\n--- All keys test ---\n");
    dut->keys = ~0ull;
    for (int i = 64; i < 88; i++) dut->keys |= (1ull << i);
    wait_debounce_settle();
    if (wait_audio_level(1, "all-keys press")) {
        printf("  PASS: All-keys output non-zero\n");
        passed++;
    } else {
        failed++;
    }
    dut->keys = 0;
    wait_debounce_settle();
    if (dut->audio_out == 0) {
        printf("  PASS: Output zero after releasing all keys\n");
        passed++;
    } else {
        printf("  FAIL: Output should be zero after releasing all keys\n");
        failed++;
    }

    printf("\n=== Results: %d passed, %d failed ===\n", passed, failed);

    trace->close();
    delete dut;

    return (failed > 0) ? 1 : 0;
}
