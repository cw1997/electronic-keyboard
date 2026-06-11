// ============================================================================
// Frequency Generator
//
// Description: Generates a square-wave tone at NOTE_FREQ_HZ using a simple
//   half-period counter.  When key_on is asserted the counter increments every
//   clock cycle; when it reaches HALF_PERIOD - 1, square_out toggles and the
//   counter resets to zero.  HALF_PERIOD = round(CLK_FREQ / (2 * NOTE_FREQ_HZ))
//   is the number of clock cycles in one half of a square-wave period.
//   When key_on is de-asserted the counter and output are held at zero.
//
// Ports:
//   clk        - master clock input
//   rst_n      - asynchronous reset (active low)
//   key_on     - 1 = produce tone, 0 = output low
//   square_out - square-wave tone output
// ============================================================================

module freq_gen #(
    parameter CLK_FREQ     = 50_000_000,  // System clock frequency (Hz)
    parameter NOTE_FREQ_HZ = 440           // Desired note frequency (Hz)
) (
    input  logic clk,        // Master clock input
    input  logic rst_n,      // Asynchronous reset, active low
    input  logic key_on,     // Key press enable (1 = produce tone)
    output logic square_out  // Square wave output
);

    // Half-period in clock cycles (rounded); 21 bits covers all 88 notes at 50 MHz
    localparam int          HALF_PERIOD      = (CLK_FREQ + NOTE_FREQ_HZ) / (2 * NOTE_FREQ_HZ);
    localparam logic [20:0] HALF_PERIOD_LAST = 21'(HALF_PERIOD - 1);

    logic [20:0] counter;  // Half-period counter
    logic        square_out_reg;  // Registered square-wave output

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter        <= '0;
            square_out_reg <= 1'b0;
        end else if (key_on) begin
            if (counter >= HALF_PERIOD_LAST) begin
                counter        <= '0;
                square_out_reg <= ~square_out_reg;
            end else begin
                counter <= counter + 1'b1;
            end
        end else begin
            counter        <= '0;
            square_out_reg <= 1'b0;
        end
    end

    assign square_out = square_out_reg;

endmodule
