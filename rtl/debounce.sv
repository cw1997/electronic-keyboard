// ============================================================================
// Debounce
//
// Description: Debounces a single key input using a counter-based approach.
//   When the input differs from the registered output, a counter increments.
//   If the input remains stable for DEBOUNCE_MS milliseconds, the output
//   updates to match the input.  If the input changes before the counter
//   reaches the threshold, the counter resets.
//
// Ports:
//   clk     - master clock input
//   rst_n   - asynchronous reset (active low)
//   key_in  - raw key input (async, 1 = pressed)
//   key_out - debounced key output (1 = pressed)
// ============================================================================

`timescale 1ns / 1ps

module debounce #(
    parameter CLK_FREQ    = 50_000_000,  // System clock frequency (Hz)
    parameter DEBOUNCE_MS = 10            // Debounce time (ms)
) (
    input  logic clk,      // Master clock input
    input  logic rst_n,    // Asynchronous reset, active low
    input  logic key_in,   // Raw key input (async, 1 = pressed)
    output logic key_out   // Debounced key output (1 = pressed)
);

    // Number of clock cycles required for debounce
    localparam int          CNT_MAX   = CLK_FREQ / 1000 * DEBOUNCE_MS;
    localparam int          CNT_BITS  = $clog2(CNT_MAX);
    localparam [CNT_BITS-1:0] CNT_THRESH = CNT_MAX[CNT_BITS-1:0] - 1'b1;

    logic [CNT_BITS-1:0] cnt;  // Debounce counter

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt     <= '0;
            key_out <= '0;
        end else begin
            if (key_in != key_out) begin
                if (cnt == CNT_THRESH) begin
                    key_out <= key_in;
                    cnt     <= '0;
                end else begin
                    cnt <= cnt + 1;
                end
            end else begin
                cnt <= '0;
            end
        end
    end

endmodule
