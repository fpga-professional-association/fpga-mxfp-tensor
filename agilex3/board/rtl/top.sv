// top.sv -- AXC3000 (Agilex 3 A3CY100BM16AE7S) wrapper: Platform Designer shell (PLL, JTAG-to-
// Avalon master, clock-crossing bridge) + mxfp_harness running the paper's tensor-mode MXFP
// dot product. Pins: CLK_25M (A7, 1.2 V), LEDs active low, UART unused (kept for the board qsf).
`default_nettype none
module top #(
  parameter int E = 2,
  parameter int M = 1,
  parameter int PIPE = 1
) (
  input  wire CLK_25M,
  input  wire UART_RX,
  output wire UART_TX,
  output wire LED1_N,   // heartbeat on the DUT clock
  output wire GLED_N,   // PLL locked
  output wire RLED_N,   // harness busy
  output wire BLED_N    // last run done
);
  wire clk_sys, clk_dut, pll_locked, rst_dut_n;
  wire        av_waitrequest, av_readdatavalid, av_write, av_read;
  wire [31:0] av_readdata, av_writedata;
  wire [12:0] av_address;
  wire        busy, done;

  mx_shell u0 (
    .dut_av_waitrequest   (av_waitrequest),
    .dut_av_readdata      (av_readdata),
    .dut_av_readdatavalid (av_readdatavalid),
    .dut_av_burstcount    (),
    .dut_av_writedata     (av_writedata),
    .dut_av_address       (av_address),
    .dut_av_write         (av_write),
    .dut_av_read          (av_read),
    .dut_av_byteenable    (),
    .dut_av_debugaccess   (),
    .clk_dut_clk          (clk_dut),
    .clk_sys_clk          (clk_sys),
    .pll_refclk_clk       (CLK_25M),
    .pll_locked_export    (pll_locked),
    .rst_dut_in_reset_n   (pll_locked),
    .rst_dut_out_reset_n  (rst_dut_n),
    .rst_sys_in_reset_n   (pll_locked)
  );

  mxfp_harness #(.E(E), .M(M), .PIPE(PIPE)) harness (
    .clk              (clk_dut),
    .rst_n            (rst_dut_n),
    .av_address       (av_address[12:2]),
    .av_read          (av_read),
    .av_write         (av_write),
    .av_writedata     (av_writedata),
    .av_readdata      (av_readdata),
    .av_readdatavalid (av_readdatavalid),
    .av_waitrequest   (av_waitrequest),
    .busy             (busy),
    .done             (done)
  );

  logic [26:0] hb;
  always_ff @(posedge clk_dut) hb <= hb + 27'd1;

  assign LED1_N  = ~hb[26];
  assign GLED_N  = ~pll_locked;
  assign RLED_N  = ~busy;
  assign BLED_N  = ~done;
  assign UART_TX = 1'b1;
  wire unused = UART_RX;
endmodule
`default_nettype wire
