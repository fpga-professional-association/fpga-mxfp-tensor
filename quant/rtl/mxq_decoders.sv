// mxq_decoders.sv -- vendor-independent combinational modules from spec AGX5-MXQ-001 section 6.1.
//
//   mxq_e2m1_to_s5        4-bit E2M1 code -> signed 5-bit q = 2 * value  (all 16 codes; -0 -> 0)
//   mxq_int4_to_s8        signed 4-bit two's complement -> signed 8-bit (sign extension); -8 flagged
//   mxq_bfp_scale_decode  signed 5-bit BFP exponent or E8M0 scale -> signed 9-bit exponent; 0xFF trapped
//   mxq_qdot10_ref        soft golden: two 10-lane signed int8 dot products (exact integers)
//   mxq_scale_apply       signed int32 sum x 2^(e) -> IEEE fp32 (RNE), one scale per 32-element group
//
// None of these instantiate vendor DSP primitives. mxq_qdot10_ref is a reference, not a tensor-mode proof.
`default_nettype none

module mxq_e2m1_to_s5 (
  input  wire  [3:0] code,     // {S, E1, E0, M}
  output logic signed [4:0] q  // 2 * value in {0, +-1, +-2, +-3, +-4, +-6, +-8, +-12}
);
  logic [3:0] mag;
  always_comb begin
    case (code[2:0])
      3'd0: mag = 4'd0;  3'd1: mag = 4'd1;  3'd2: mag = 4'd2;  3'd3: mag = 4'd3;
      3'd4: mag = 4'd4;  3'd5: mag = 4'd6;  3'd6: mag = 4'd8;  default: mag = 4'd12;
    endcase
    q = code[3] ? -$signed({1'b0, mag}) : $signed({1'b0, mag});   // negative zero decodes to 0
  end
endmodule

module mxq_int4_to_s8 (
  input  wire  [3:0] code,          // two's complement
  output logic signed [7:0] q,
  output logic              invalid // code 0x8 (-8) is outside the symmetric [-7, 7] profile
);
  assign q = $signed({{4{code[3]}}, code});
  assign invalid = (code == 4'h8);
endmodule

module mxq_bfp_scale_decode (
  input  wire        is_mx,        // 1: E8M0 scale byte, 0: signed 5-bit BFP exponent in [4:0]
  input  wire  [7:0] scale_in,
  output logic signed [8:0] e,     // exponent such that value = q * 2^e
  output logic              trap   // reserved E8M0 0xFF
);
  always_comb begin
    if (is_mx) begin
      e    = $signed({1'b0, scale_in}) - 9'sd127;
      trap = (scale_in == 8'hFF);
    end else begin
      e    = $signed({{4{scale_in[4]}}, scale_in[4:0]});
      trap = 1'b0;
    end
  end
endmodule

module mxq_qdot10_ref (
  input  wire clk,
  input  wire signed [7:0] a   [0:9],   // shared activation lanes
  input  wire signed [7:0] w1  [0:9],   // column 1 weights
  input  wire signed [7:0] w2  [0:9],   // column 2 weights
  output logic signed [31:0] s1,
  output logic signed [31:0] s2
);
  logic signed [31:0] t1, t2;
  always_comb begin
    t1 = 0; t2 = 0;
    for (int i = 0; i < 10; i++) begin
      t1 = t1 + a[i] * w1[i];
      t2 = t2 + a[i] * w2[i];
    end
  end
  always_ff @(posedge clk) begin
    s1 <= t1; s2 <= t2;
  end
endmodule

// Exact conversion of a signed 32-bit integer times 2^e to IEEE fp32 with round-to-nearest-even.
// For one 32-element group |S| < 2^20 so the conversion is exact; the rounding path is still
// implemented so multi-group fabric accumulation (spec V2) can reuse it. Latency 2 cycles.
module mxq_scale_apply (
  input  wire                clk,
  input  wire                valid_in,
  input  wire signed [31:0]  s,
  input  wire signed [9:0]   e,         // combined exponent e_w + e_a - f_w - f_a
  output logic [31:0]        fp32,
  output logic               valid_out,
  output logic               ovf,       // exponent overflow -> saturated to +-inf
  output logic               unf        // result flushed to zero (subnormal range)
);
  // stage 1: sign/magnitude and leading-zero count
  logic        sgn_q;  logic [31:0] mag_q;  logic signed [9:0] e_q;  logic v_q;  logic [5:0] lz_q;
  function automatic [5:0] clz32(input [31:0] x);
    logic found;
    clz32 = 6'd32; found = 1'b0;
    for (int i = 31; i >= 0; i--) begin
      if (x[i] && !found) begin clz32 = 6'(31 - i); found = 1'b1; end
    end
  endfunction
  always_ff @(posedge clk) begin
    v_q   <= valid_in;
    sgn_q <= s[31];
    mag_q <= s[31] ? -s : s;
    e_q   <= e;
    lz_q  <= clz32(s[31] ? -s : s);
  end
  // stage 2: normalize (MSB to bit 31); stage 3: round to 24 bits RNE and assemble
  logic        sgn_n; logic [31:0] norm_n; logic signed [10:0] be0_n; logic v_n; logic zero_n;
  always_ff @(posedge clk) begin
    v_n    <= v_q;
    sgn_n  <= sgn_q;
    zero_n <= (mag_q == 0);
    norm_n <= mag_q << lz_q;
    be0_n  <= 11'sd127 + 11'sd31 - $signed({5'd0, lz_q}) + e_q;
  end
  logic [24:0] m25, m25r; logic [7:0] rest; logic round_up; logic signed [10:0] be;
  always_comb begin
    m25      = {1'b0, norm_n[31:8]};
    rest     = norm_n[7:0];
    round_up = rest[7] & (|rest[6:0] | m25[0]);
    m25r     = m25 + {24'd0, round_up};
    be       = be0_n + (m25r[24] ? 11'sd1 : 11'sd0);
    if (m25r[24]) m25r = m25r >> 1;
  end
  always_ff @(posedge clk) begin
    valid_out <= v_n;
    if (zero_n) begin fp32 <= {sgn_n, 31'd0}; ovf <= 0; unf <= 0; end
    else if (be >= 11'sd255) begin fp32 <= {sgn_n, 8'hFF, 23'd0}; ovf <= 1; unf <= 0; end
    else if (be <= 11'sd0) begin fp32 <= {sgn_n, 31'd0}; ovf <= 0; unf <= 1; end
    else begin fp32 <= {sgn_n, be[7:0], m25r[22:0]}; ovf <= 0; unf <= 0; end
  end
endmodule

`default_nettype wire
