// tb_mxq_decoders.sv -- Icarus/Verilator testbench for quant/rtl/mxq_decoders.sv against the Python goldens.
//   iverilog -g2012 -o tb quant/rtl/mxq_decoders.sv quant/tests/tb_mxq_decoders.sv && vvp tb
`timescale 1ns/1ps
module tb_mxq_decoders;
  logic clk = 0; always #1 clk = ~clk;
  int errors = 0, n;
  string dir = "quant/tests/golden_vectors/";

  // ---- e2m1
  logic [3:0] c4; logic signed [4:0] q5;
  mxq_e2m1_to_s5 u_e2m1 (.code(c4), .q(q5));
  // ---- int4
  logic signed [7:0] q8; logic inv;
  mxq_int4_to_s8 u_int4 (.code(c4), .q(q8), .invalid(inv));
  // ---- scale
  logic is_mx; logic [7:0] sc; logic signed [8:0] e9; logic trap;
  mxq_bfp_scale_decode u_sc (.is_mx(is_mx), .scale_in(sc), .e(e9), .trap(trap));
  // ---- qdot10
  logic signed [7:0] a[0:9], w1[0:9], w2[0:9]; logic signed [31:0] s1, s2;
  mxq_qdot10_ref u_dot (.clk(clk), .a(a), .w1(w1), .w2(w2), .s1(s1), .s2(s2));
  // ---- scale apply
  logic sv_in; logic signed [31:0] s_in; logic signed [9:0] e_in; logic [31:0] f32; logic sv_out, ovf, unf;
  mxq_scale_apply u_sa (.clk(clk), .valid_in(sv_in), .s(s_in), .e(e_in), .fp32(f32), .valid_out(sv_out), .ovf(ovf), .unf(unf));

  int fd, r; logic [31:0] v[0:40]; logic [31:0] exp_s1, exp_s2, exp_f32; int exp_ovf, exp_unf, exp_trap, exp_inv;
  initial begin
    // e2m1 (16)
    fd = $fopen({dir, "e2m1.hex"}, "r"); n = 0;
    while ($fscanf(fd, "%h %h", v[0], v[1]) == 2) begin
      c4 = v[0][3:0]; #1;
      if (q5 !== $signed(v[1][4:0])) begin errors++; $display("E2M1 code %h: got %d exp %d", c4, q5, $signed(v[1][4:0])); end
      n++;
    end
    $fclose(fd); $display("e2m1: %0d vectors", n);
    // int4
    fd = $fopen({dir, "int4.hex"}, "r"); n = 0;
    while ($fscanf(fd, "%h %h %d", v[0], v[1], exp_inv) == 3) begin
      c4 = v[0][3:0]; #1;
      if (q8 !== $signed(v[1][7:0]) || inv !== exp_inv[0]) begin errors++; $display("INT4 code %h: got %d/%b exp %d/%0d", c4, q8, inv, $signed(v[1][7:0]), exp_inv); end
      n++;
    end
    $fclose(fd); $display("int4: %0d vectors", n);
    // scale decode
    fd = $fopen({dir, "scale.hex"}, "r"); n = 0;
    while ($fscanf(fd, "%d %h %h %d", v[0], v[1], v[2], exp_trap) == 4) begin
      is_mx = v[0][0]; sc = v[1][7:0]; #1;
      if (e9 !== $signed(v[2][8:0]) || trap !== exp_trap[0]) begin errors++; $display("SCALE mx=%b in=%h: got %d/%b exp %d/%0d", is_mx, sc, e9, trap, $signed(v[2][8:0]), exp_trap); end
      n++;
    end
    $fclose(fd); $display("scale: %0d vectors", n);
    // qdot10 (registered, 1 cycle)
    fd = $fopen({dir, "qdot10.hex"}, "r"); n = 0;
    while ($fscanf(fd, "%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h",
                   v[0],v[1],v[2],v[3],v[4],v[5],v[6],v[7],v[8],v[9],v[10],v[11],v[12],v[13],v[14],v[15],v[16],v[17],v[18],v[19],
                   v[20],v[21],v[22],v[23],v[24],v[25],v[26],v[27],v[28],v[29],exp_s1,exp_s2) == 32) begin
      for (int i = 0; i < 10; i++) begin a[i] = v[i][7:0]; w1[i] = v[10+i][7:0]; w2[i] = v[20+i][7:0]; end
      @(posedge clk); #0.1;
      if (s1 !== $signed(exp_s1) || s2 !== $signed(exp_s2)) begin errors++; if (errors < 10) $display("QDOT10 #%0d: got %0d %0d exp %0d %0d", n, s1, s2, $signed(exp_s1), $signed(exp_s2)); end
      n++;
    end
    $fclose(fd); $display("qdot10: %0d vectors", n);
    // scale apply (2 cycles)
    fd = $fopen({dir, "scale_apply.hex"}, "r"); n = 0; sv_in = 0;
    while ($fscanf(fd, "%h %h %h %d %d", v[0], v[1], exp_f32, exp_ovf, exp_unf) == 5) begin
      s_in = v[0]; e_in = $signed(v[1][9:0]); sv_in = 1;
      @(posedge clk); #0.1; sv_in = 0; @(posedge clk); #0.1;
      if (!sv_out) begin errors++; $display("SCALE_APPLY #%0d: valid_out missing", n); end
      if (f32 !== exp_f32 || ovf !== exp_ovf[0] || unf !== exp_unf[0]) begin errors++; if (errors < 20) $display("SCALE_APPLY #%0d s=%0d e=%0d: got %h ovf%b unf%b exp %h %0d %0d", n, s_in, e_in, f32, ovf, unf, exp_f32, exp_ovf, exp_unf); end
      n++;
    end
    $fclose(fd); $display("scale_apply: %0d vectors", n);
    if (errors == 0) $display("ALL DECODER TESTS PASSED"); else $display("FAILED with %0d errors", errors);
    $finish;
  end
endmodule
