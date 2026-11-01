// fxp_dot.sv -- spec AGX5-MXQ-001 variant V1: tensor FIXED-POINT mode, exact signed operands,
// four DSP blocks per two dot-32 outputs, int32 cascade, and ONE fp32 rescale per 32-element group
// done in the fabric (mxq_scale_apply). Compare with mxfp_dot/bfp_dot (V0: tensor floating-point
// mode, FP32 cascade and shared-exponent handling inside the DSP).
//
// Interface matches bfp_dot: raw int8 lanes + one E8M0 shared exponent per vector. The weight
// exponents are captured during the 2-cycle data-feed preload (column 2 on the second load_en
// cycle, column 1 on the following cycle) and held; the activation exponent travels with the data.
// result_col = S_col * 2^(Xw_col - 127 + Xa - 127) rounded once to fp32.
//
// Latency: data to int32 sum through the 4-block cascade is the same 11 cycles as the FP mode
// (5 per block input-to-output, 2 per cascade hop, blocks staggered by 2), then 2 cycles for
// the fabric scale (3 stages), so valid_out is 13 cycles after valid_in. Verified on silicon via the trace.
`default_nettype none
module fxp_dot #(
  parameter int PIPE = 1,
  parameter int DOT_LEN = 32,
  parameter int FXP_LAT = 10   // measured on silicon: one cycle less than the FP cascade (no fp32 add stage)
) (
  input  wire        clk,
  input  wire        rst,
  input  wire        load_en,
  input  wire        valid_in,
  input  wire [7:0]  int8_in [0:DOT_LEN-1],
  input  wire [7:0]  shared_exponent,
  input  wire        raw_out,          // debug: output the raw int32 sums instead of fp32
  output wire [31:0] fp32_dot_out_col1,
  output wire [31:0] fp32_dot_out_col2,
  output wire        valid_out,
  output wire [3:0]  fp32_flags_col1,
  output wire [3:0]  fp32_flags_col2
);
  logic signed [7:0] d  [0:DOT_LEN-1];
  logic signed [7:0] dq [0:DOT_LEN-1];
  logic [7:0] e_in;
  logic ld;
  logic load_ff [1:3];
  logic [31:0] casc1 [0:2], casc2 [0:2];
  logic [31:0] s1, s2;

  generate
    for (genvar j = 0; j < DOT_LEN; j++) begin : g_in
      pipeline #(.W(8), .STAGES(PIPE)) P (.clk(clk), .rst(rst), .pipe_in(int8_in[j]), .pipe_out(d[j]));
    end
    for (genvar j = 10; j < 20; j++) begin : g_s1
      pipeline #(.W(8), .STAGES(2)) P (.clk(clk), .rst(rst), .pipe_in(d[j]), .pipe_out(dq[j]));
    end
    for (genvar j = 20; j < 30; j++) begin : g_s2
      pipeline #(.W(8), .STAGES(4)) P (.clk(clk), .rst(rst), .pipe_in(d[j]), .pipe_out(dq[j]));
    end
    for (genvar j = 30; j < 32; j++) begin : g_s3
      pipeline #(.W(8), .STAGES(6)) P (.clk(clk), .rst(rst), .pipe_in(d[j]), .pipe_out(dq[j]));
    end
  endgenerate
  pipeline #(.W(8), .STAGES(PIPE)) PE (.clk(clk), .rst(rst), .pipe_in(shared_exponent), .pipe_out(e_in));
  pipeline #(.W(1), .STAGES(PIPE)) PL (.clk(clk), .rst(rst), .pipe_in(load_en), .pipe_out(ld));
  pipeline #(.W(1), .STAGES(2)) L1 (.clk(clk), .rst(rst), .pipe_in(ld), .pipe_out(load_ff[1]));
  pipeline #(.W(1), .STAGES(4)) L2 (.clk(clk), .rst(rst), .pipe_in(ld), .pipe_out(load_ff[2]));
  pipeline #(.W(1), .STAGES(6)) L3 (.clk(clk), .rst(rst), .pipe_in(ld), .pipe_out(load_ff[3]));

  // ---- weight exponent capture: 2-cycle preload. ld high two cycles: the data in the 2nd high
  // cycle is column 2, the data in the first low cycle is column 1.
  logic ld_d;
  logic [7:0] ew_col1, ew_col2;
  always_ff @(posedge clk) begin
    ld_d <= ld;
    if (ld && ld_d)   ew_col2 <= e_in;   // second consecutive load cycle
    if (!ld && ld_d)  ew_col1 <= e_in;   // first cycle after load_en falls
  end

  // ---- 4-block tensor fixed-point cascade (data_feed_in preload like the paper's design)
  fxp_aitb_blk #(.CHAIN_MODE("zero_tensor_chain_output"), .ZERO_EN(1)) dot0 (
    .clk(clk), .rst(rst), .load_en(ld), .data_in(d[0:9]),
    .cascade_in_col_1(32'd0), .cascade_in_col_2(32'd0),
    .cascade_out_col_1(casc1[0]), .cascade_out_col_2(casc2[0]), .res_col_1(), .res_col_2());
  fxp_aitb_blk dot1 (
    .clk(clk), .rst(rst), .load_en(load_ff[1]), .data_in(dq[10:19]),
    .cascade_in_col_1(casc1[0]), .cascade_in_col_2(casc2[0]),
    .cascade_out_col_1(casc1[1]), .cascade_out_col_2(casc2[1]), .res_col_1(), .res_col_2());
  fxp_aitb_blk dot2 (
    .clk(clk), .rst(rst), .load_en(load_ff[2]), .data_in(dq[20:29]),
    .cascade_in_col_1(casc1[1]), .cascade_in_col_2(casc2[1]),
    .cascade_out_col_1(casc1[2]), .cascade_out_col_2(casc2[2]), .res_col_1(), .res_col_2());
  logic signed [7:0] last10 [0:9];
  always_comb begin
    last10[0] = dq[30]; last10[1] = dq[31];
    for (int k = 2; k < 10; k++) last10[k] = '0;
  end
  fxp_aitb_blk dot3 (
    .clk(clk), .rst(rst), .load_en(load_ff[3]), .data_in(last10),
    .cascade_in_col_1(casc1[2]), .cascade_in_col_2(casc2[2]),
    .cascade_out_col_1(), .cascade_out_col_2(), .res_col_1(s1), .res_col_2(s2));

  // ---- activation exponent and valid aligned with the int32 sums (FXP_LAT cycles after d/e_in)
  logic [7:0] ea_al;  logic v_al;
  pipeline #(.W(8), .STAGES(FXP_LAT)) PEA (.clk(clk), .rst(rst), .pipe_in(e_in), .pipe_out(ea_al));
  pipeline #(.W(1), .STAGES(FXP_LAT)) PV  (.clk(clk), .rst(rst), .pipe_in(valid_in), .pipe_out(v_al));

  // ---- one fp32 rescale per group: e = Xw + Xa - 254 (f = 0 for integer operands)
  wire signed [9:0] e1 = $signed({2'b0, ew_col1}) + $signed({2'b0, ea_al}) - 10'sd254;
  wire signed [9:0] e2 = $signed({2'b0, ew_col2}) + $signed({2'b0, ea_al}) - 10'sd254;
  logic ovf1, unf1, ovf2, unf2, vo1, vo2;
  mxq_scale_apply SA1 (.clk(clk), .valid_in(v_al), .s(s1), .e(e1), .fp32(fp1), .valid_out(vo1), .ovf(ovf1), .unf(unf1));
  mxq_scale_apply SA2 (.clk(clk), .valid_in(v_al), .s(s2), .e(e2), .fp32(fp2), .valid_out(vo2), .ovf(ovf2), .unf(unf2));
  logic [31:0] s1_d, s2_d; logic v_d;
  logic [31:0] fp1, fp2;
  pipeline #(.W(32), .STAGES(3)) PS1 (.clk(clk), .rst(rst), .pipe_in(s1), .pipe_out(s1_d));
  pipeline #(.W(32), .STAGES(3)) PS2 (.clk(clk), .rst(rst), .pipe_in(s2), .pipe_out(s2_d));
  pipeline #(.W(1),  .STAGES(3)) PVD (.clk(clk), .rst(rst), .pipe_in(v_al), .pipe_out(v_d));
  assign fp32_dot_out_col1 = raw_out ? s1_d : fp1;
  assign fp32_dot_out_col2 = raw_out ? s2_d : fp2;
  assign valid_out = raw_out ? v_d : vo1;
  assign fp32_flags_col1 = {2'b0, unf1, ovf1};
  assign fp32_flags_col2 = {2'b0, unf2, ovf2};
endmodule

// One Agilex tensor DSP block in fixed-point tensor mode with int32 cascade, data-feed preload.
// Port and parameter usage follows the authors' fxp_aitb.sv and fp_aitb.sv (tennm_dsp_prime).
module fxp_aitb_blk #(
  parameter string CHAIN_MODE = "tensor_chain_output",
  parameter bit ZERO_EN = 0
) (
  input  wire        clk,
  input  wire        rst,
  input  wire        load_en,
  input  wire signed [7:0] data_in [0:9],
  input  wire [31:0] cascade_in_col_1,
  input  wire [31:0] cascade_in_col_2,
  output wire [31:0] cascade_out_col_1,
  output wire [31:0] cascade_out_col_2,
  output wire [31:0] res_col_1,
  output wire [31:0] res_col_2
);
  logic [95:0] din;
  always_comb begin
    for (int i = 0; i < 10; i++) din[i*8 +: 8] = data_in[i];
    din[95:80] = 16'd0;
  end
  wire [36:0] result_l;
  wire [26:0] result_h;
  assign res_col_1 = result_l[31:0];
  assign res_col_2 = {result_h[26:0], result_l[36:32]};

  tennm_dsp_prime tennm_dsp_prime_component (
    .clk(clk), .ena(1'b1),
    .acc_en(1'b0), .zero_en(ZERO_EN),
    .load_bb_one(load_en), .load_bb_two(1'b0), .load_buf_sel(1'b0),
    .clr({rst, rst}),
    .data_in(din),
    .cascade_data_in({cascade_in_col_2, cascade_in_col_1}),
    .cascade_data_out({cascade_out_col_2, cascade_out_col_1}),
    .result_l(result_l),
    .result_h(result_h));
  defparam
    tennm_dsp_prime_component.dsp_mode = "tensor_fxp",
    tennm_dsp_prime_component.dsp_side_feed_ctrl = "data_feed_in",
    tennm_dsp_prime_component.dsp_chain_tensor = CHAIN_MODE,
    tennm_dsp_prime_component.dsp_fp32_sub_en = "float_sub_disabled";
endmodule
`default_nettype wire
