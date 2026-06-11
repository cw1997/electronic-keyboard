// ============================================================================
// Frequency Generator
//
// Description: Generates a square-wave tone at NOTE_FREQ_HZ using a 32-bit
//   phase accumulator.  When key_on is asserted the accumulator steps by
//   freq_word = round(NOTE_FREQ_HZ * 2^32 / CLK_FREQ) every clock cycle;
//   the MSB of the accumulator is the square-wave output.  When key_on is
//   de-asserted the accumulator is held at zero so the output stays low.
//
// Ports:
//   clk        - master clock input
//   rst_n      - asynchronous reset (active low)
//   key_on     - 1 = produce tone, 0 = output low
//   square_out - square-wave tone (MSB of phase accumulator)
// ============================================================================

module freq_gen #(
    parameter CLK_FREQ    = 50_000_000,  // System clock frequency (Hz)
    parameter NOTE_FREQ_HZ = 440          // Desired note frequency (Hz)
) (
    input  logic clk,        // Master clock input
    input  logic rst_n,      // Asynchronous reset, active low
    input  logic key_on,     // Key press enable (1 = produce tone)
    output logic square_out  // Square wave output (MSB of phase accumulator)
);

    // freq_word = round(NOTE_FREQ_HZ * 2^32 / CLK_FREQ)
    localparam logic [31:0] FREQ_WORD =
        32'((64'(NOTE_FREQ_HZ) * 64'd4294967296 + 64'(CLK_FREQ / 2)) / 64'(CLK_FREQ));

    logic [31:0] phase_acc;  // Phase accumulator

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= '0;
        end else if (key_on) begin
            phase_acc <= phase_acc + FREQ_WORD;
        end else begin
            phase_acc <= '0;
        end
    end

    assign square_out = phase_acc[31];

endmodule
