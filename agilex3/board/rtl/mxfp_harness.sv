// =============================================================================================
// mxfp_harness.sv -- JTAG-driven test harness for the paper's tensor-mode MXFP dot product
// (upstream/fpga-mxfp/characterization/ai_tensor_block/rtl/mxfp_dot.sv) on the Arrow AXC3000
// (Agilex 3 A3CY100BM16AE7S).
//
// Everything here runs in the DUT clock domain. The Avalon-MM slave is driven by a Platform
// Designer JTAG-to-Avalon master through a clock-crossing bridge, so the host (System Console)
// sees a flat 32-bit word register map:
//
//   word 0x000  ID        RO  0x4D580001
//   word 0x001  CTRL      WO  bit0 START, bit1 DUT_RESET (pulse)
//   word 0x002  STATUS    RO  bit0 BUSY, bit1 DONE, bit2 ERR_OVERRUN
//   word 0x003  NVEC      RW  number of activation vectors to stream, 1..64
//   word 0x004  FORMAT    RO  {16'd0, E[7:0], M[7:0]}
//   word 0x005  CYCLES    RO  DUT clock cycles from START to the last valid_out
//   word 0x006  FREE_LO   RO  free-running DUT-clock counter (for on-chip frequency measurement)
//   word 0x007  FREE_HI   RO
//   word 0x100..0x107  weight vector for DSP column 1 (result col1): words 0..7 of the packed
//                      element vector, element j at bit [j*W +: W] of the 256-bit concatenation
//   word 0x108         shared exponent (E8M0) for column-1 weights
//   word 0x110..0x117  weight vector for DSP column 2 (result col2)
//   word 0x118         shared exponent for column-2 weights
//   word 0x200 + 16*i + {0..7}  activation vector i (same packing), i = 0..63
//   word 0x200 + 16*i + 8       shared exponent for activation i
//   word 0x600 + 2*i + 0        result i, column 1 (fp32 bits)
//   word 0x600 + 2*i + 1        result i, column 2 (fp32 bits)
//
// Sequence on START (mirrors the paper's testbench mxfp_dot_tb.sv):
//   cycle 0: load_en=1, data = column-2 weights      (DSP data-feed preload, bank "two")
//   cycle 1: load_en=0, data = column-1 weights      (second preload cycle)
//   cycles 2..N+1: valid_in=1, data = activation i   (one vector per cycle)
//   results appear on valid_out 11 cycles later and are written to the result RAM in order.
// =============================================================================================
`default_nettype none

module mxfp_harness #(
  parameter int E = 2,
  parameter int M = 1,
  parameter int PIPE = 1,
  parameter int DOT_LEN = 32,
  parameter int MAX_VEC = 64
) (
  input  wire        clk,
  input  wire        rst_n,

  // Avalon-MM slave, 32-bit words, word addressing (11 bits), waitrequest never asserted,
  // read latency 1 signalled with readdatavalid.
  input  wire [10:0] av_address,
  input  wire        av_read,
  input  wire        av_write,
  input  wire [31:0] av_writedata,
  output logic [31:0] av_readdata,
  output logic        av_readdatavalid,
  output wire         av_waitrequest,

  output logic        busy,
  output logic        done
);

  localparam int W = M + E + 1;              // element width
  localparam int VW = 256;                   // packed vector width (8 words)
  localparam int IDXW = $clog2(MAX_VEC);

  assign av_waitrequest = 1'b0;

  // ------------------------------------------------------------------ storage
  logic [VW-1:0] w_col1, w_col2;
  logic [7:0]    e_col1, e_col2;
  // activation RAM: 8 word-columns x MAX_VEC, read all 8 at once for one vector per cycle
  logic [31:0] act_mem [0:7][0:MAX_VEC-1];
  logic [7:0]  act_exp [0:MAX_VEC-1];
  // result RAM
  logic [31:0] res_c1 [0:MAX_VEC-1];
  logic [31:0] res_c2 [0:MAX_VEC-1];

  logic [IDXW:0] nvec;          // 1..64
  logic [31:0]   cycles;
  logic [63:0]   free_cnt;
  logic          err_overrun;
  logic          start_q, dut_rst_req;

  // ------------------------------------------------------------------ Avalon write
  always_ff @(posedge clk) begin
    start_q     <= 1'b0;
    dut_rst_req <= 1'b0;
    if (!rst_n) begin
      nvec <= 'd1;
      w_col1 <= '0; w_col2 <= '0; e_col1 <= 8'd127; e_col2 <= 8'd127;
    end else if (av_write) begin
      case (av_address[10:8])
        3'h0: begin
          case (av_address[7:0])
            8'h01: begin start_q <= av_writedata[0]; dut_rst_req <= av_writedata[1]; end
            8'h03: nvec <= av_writedata[IDXW:0];
            default: ;
          endcase
        end
        3'h1: begin // weights
          if (av_address[7:4] == 4'h0) begin
            if (av_address[3]) e_col1 <= av_writedata[7:0];
            else w_col1[av_address[2:0]*32 +: 32] <= av_writedata;
          end else if (av_address[7:4] == 4'h1) begin
            if (av_address[3]) e_col2 <= av_writedata[7:0];
            else w_col2[av_address[2:0]*32 +: 32] <= av_writedata;
          end
        end
        default: ;
      endcase
    end
  end

  // activation RAM write (separate always block so Quartus infers RAM cleanly)
  wire        act_wr   = av_write && (av_address[10:9] == 2'b01);   // 0x200..0x3FF
  wire [5:0]  act_slot = av_address[9:4];
  always_ff @(posedge clk) begin
    if (act_wr && !av_address[3]) act_mem[av_address[2:0]][act_slot] <= av_writedata;
    if (act_wr &&  av_address[3] && av_address[2:0] == 3'd0) act_exp[act_slot] <= av_writedata[7:0];
  end

  // ------------------------------------------------------------------ Avalon read
  logic [31:0] rd_mux;
  always_comb begin
    rd_mux = 32'hDEAD_BEEF;
    case (av_address[10:8])
      3'h0: case (av_address[7:0])
        8'h00: rd_mux = 32'h4D58_0001;
        8'h02: rd_mux = {29'd0, err_overrun, done, busy};
        8'h03: rd_mux = {{(31-IDXW){1'b0}}, nvec};
        8'h04: rd_mux = {16'd0, E[7:0], M[7:0]};
        8'h05: rd_mux = cycles;
        8'h06: rd_mux = free_cnt[31:0];
        8'h07: rd_mux = free_cnt[63:32];
        default: rd_mux = 32'h0;
      endcase
      3'h1: begin
        if (av_address[7:4] == 4'h0) rd_mux = av_address[3] ? {24'd0, e_col1} : w_col1[av_address[2:0]*32 +: 32];
        else if (av_address[7:4] == 4'h1) rd_mux = av_address[3] ? {24'd0, e_col2} : w_col2[av_address[2:0]*32 +: 32];
      end
      3'h2, 3'h3: rd_mux = av_address[3] ? {24'd0, act_exp[act_slot]} : act_mem[av_address[2:0]][act_slot];
      3'h6: rd_mux = av_address[0] ? res_c2[av_address[6:1]] : res_c1[av_address[6:1]];
      default: ;
    endcase
  end
  always_ff @(posedge clk) begin
    av_readdatavalid <= av_read;
    av_readdata      <= rd_mux;
    free_cnt         <= rst_n ? free_cnt + 64'd1 : 64'd0;
  end

  // ------------------------------------------------------------------ sequencer
  typedef enum logic [2:0] {S_IDLE, S_RST, S_LOAD2, S_LOAD1, S_STREAM, S_DRAIN, S_DONE} state_t;
  state_t state;

  // stage 0: command generation; stage 1: data mux (RAM output) -> DUT
  logic        s0_load, s0_valid, s0_sel_w2, s0_sel_w1;
  logic [IDXW-1:0] s0_idx;
  logic        s1_load, s1_valid, s1_sel_w2, s1_sel_w1;
  logic [IDXW-1:0] s1_idx;
  logic [IDXW:0]   stream_cnt, out_cnt;
  logic [3:0]      rst_cnt;
  logic            dut_rst;
  logic [VW-1:0]   act_vec_rd;
  logic [7:0]      act_exp_rd;

  always_comb begin
    for (int k = 0; k < 8; k++) act_vec_rd[k*32 +: 32] = act_mem[k][s1_idx];
    act_exp_rd = act_exp[s1_idx];
  end

  // DUT ports
  logic [VW-1:0] dut_vec;
  logic [7:0]    dut_exp;
  logic          dut_load, dut_valid;
  logic [31:0]   dut_out1, dut_out2;
  logic          dut_valid_out;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= S_IDLE; busy <= 1'b0; done <= 1'b0; err_overrun <= 1'b0;
      s0_load <= 1'b0; s0_valid <= 1'b0; s0_sel_w1 <= 1'b0; s0_sel_w2 <= 1'b0; s0_idx <= '0;
      s1_load <= 1'b0; s1_valid <= 1'b0; s1_sel_w1 <= 1'b0; s1_sel_w2 <= 1'b0; s1_idx <= '0;
      stream_cnt <= '0; out_cnt <= '0; cycles <= '0; rst_cnt <= '0; dut_rst <= 1'b1;
      dut_load <= 1'b0; dut_valid <= 1'b0; dut_vec <= '0; dut_exp <= 8'd127;
    end else begin
      // defaults for stage 0
      s0_load <= 1'b0; s0_valid <= 1'b0; s0_sel_w1 <= 1'b0; s0_sel_w2 <= 1'b0;
      // stage 1 <- stage 0
      s1_load <= s0_load; s1_valid <= s0_valid; s1_sel_w1 <= s0_sel_w1; s1_sel_w2 <= s0_sel_w2; s1_idx <= s0_idx;
      // DUT <- stage 1 (data mux)
      dut_load  <= s1_load;
      dut_valid <= s1_valid;
      if (s1_sel_w2)      begin dut_vec <= w_col2;     dut_exp <= e_col2;     end
      else if (s1_sel_w1) begin dut_vec <= w_col1;     dut_exp <= e_col1;     end
      else                begin dut_vec <= act_vec_rd; dut_exp <= act_exp_rd; end

      if (dut_rst_req) dut_rst <= 1'b1;

      case (state)
        S_IDLE: begin
          dut_rst <= dut_rst_req;
          if (start_q) begin
            state <= S_RST; rst_cnt <= 4'd8; dut_rst <= 1'b1;
            busy <= 1'b1; done <= 1'b0; err_overrun <= 1'b0;
            stream_cnt <= '0; out_cnt <= '0; cycles <= '0;
          end
        end
        S_RST: begin
          cycles <= cycles + 1;
          if (rst_cnt == 0) begin dut_rst <= 1'b0; state <= S_LOAD2; end
          else rst_cnt <= rst_cnt - 1;
        end
        S_LOAD2: begin
          cycles <= cycles + 1;
          s0_load <= 1'b1; s0_sel_w2 <= 1'b1;
          state <= S_LOAD1;
        end
        S_LOAD1: begin
          cycles <= cycles + 1;
          s0_load <= 1'b0; s0_sel_w1 <= 1'b1;
          s0_idx <= '0;
          state <= S_STREAM;
        end
        S_STREAM: begin
          cycles <= cycles + 1;
          s0_valid <= 1'b1; s0_idx <= stream_cnt[IDXW-1:0];
          stream_cnt <= stream_cnt + 1;
          if (stream_cnt + 1 >= nvec) state <= S_DRAIN;
        end
        S_DRAIN: begin
          cycles <= cycles + 1;
          if (out_cnt >= nvec) state <= S_DONE;
          if (cycles > 32'd4096) begin err_overrun <= 1'b1; state <= S_DONE; end // timeout guard
        end
        S_DONE: begin
          busy <= 1'b0; done <= 1'b1; state <= S_IDLE;
        end
        default: state <= S_IDLE;
      endcase

      // capture results
      if (dut_valid_out && state != S_IDLE) begin
        if (out_cnt < MAX_VEC) begin
          res_c1[out_cnt[IDXW-1:0]] <= dut_out1;
          res_c2[out_cnt[IDXW-1:0]] <= dut_out2;
        end
        out_cnt <= out_cnt + 1;
      end
    end
  end

  // ------------------------------------------------------------------ DUT
  logic [W-1:0] mx_data_in [0:DOT_LEN-1];
  always_comb for (int j = 0; j < DOT_LEN; j++) mx_data_in[j] = dut_vec[j*W +: W];

  mxfp_dot #(
    .M(M), .E(E), .E_SHARED(8), .FP_BIAS(1), .SH_BIAS(127), .PIPE(PIPE), .DOT_LEN(DOT_LEN)
  ) dut (
    .clk(clk),
    .rst(dut_rst),
    .load_en(dut_load),
    .valid_in(dut_valid),
    .mx_data_in(mx_data_in),
    .shared_exponent(dut_exp),
    .fp32_dot_out_col1(dut_out1),
    .fp32_dot_out_col2(dut_out2),
    .valid_out(dut_valid_out),
    .fp32_flags_col1(),
    .fp32_flags_col2()
  );

endmodule

`default_nettype wire
