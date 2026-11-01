// =============================================================================================
// mxfp_harness.sv -- JTAG-driven test harness for the paper's tensor-mode MXFP dot product
// (upstream/fpga-mxfp/characterization/ai_tensor_block/rtl/mxfp_dot.sv) on the Arrow AXC3000
// (Agilex 3 A3CY100BM16AE7S).
//
// Everything here runs in the DUT clock domain. The Avalon-MM slave is driven by a Platform
// Designer JTAG-to-Avalon master through a clock-crossing bridge, so the host (System Console)
// sees a flat 32-bit word register map:
//
//   word 0x000  ID        RO  0x4D580002
//   word 0x001  CTRL      WO  bit0 START, bit1 DUT_RESET (pulse)
//   word 0x002  STATUS    RO  bit0 BUSY, bit1 DONE, bit2 ERR_OVERRUN
//   word 0x003  NVEC      RW  number of activation vectors to stream, 1..64
//   word 0x004  FORMAT    RO  {16'd0, E[7:0], M[7:0]}
//   word 0x005  CYCLES    RO  DUT clock cycles from START to the last valid_out
//   word 0x006  FREE_LO   RO  free-running DUT-clock counter (for on-chip frequency measurement)
//   word 0x007  FREE_HI   RO
//   word 0x008  MODE      RW  protocol knobs (see below)
//   word 0x080..0x097  TRACE_FLAGS: 8 nibbles per word, nibble i&7 of word i>>3 for trace
//                      entry i = {valid_out, dut_valid, dut_load, dut_rst} as seen at the DUT
//   word 0x100..0x107  weight vector for DSP column 1 (result col1): words 0..7 of the packed
//                      element vector, element j at bit [j*W +: W] of the 256-bit concatenation
//   word 0x108         shared exponent (E8M0) for column-1 weights
//   word 0x110..0x117  weight vector for DSP column 2 (result col2)
//   word 0x118         shared exponent for column-2 weights
//   word 0x200 + 16*i + {0..7}  activation vector i (same packing), i = 0..63
//   word 0x200 + 16*i + 8       shared exponent for activation i
//   word 0x600 + 2*i + 0        result i, column 1 (fp32 bits), captured on valid_out
//   word 0x600 + 2*i + 1        result i, column 2 (fp32 bits)
//   word 0x680 + 2*i + {0,1}    TRACE: raw DSP outputs {col1, col2} on every DUT clock for the
//                               first 192 clocks after START (independent of valid_out)
//
// MODE bits (default 0b0011):
//   bit0 TWO_LOAD   : 1 = hold load_en for two cycles (paper testbench pattern: don't-care data,
//                     then column-2 weights, then load_en low with column-1 weights)
//                     0 = one load_en cycle carrying column-2 weights, then column-1 weights
//   bit1 PIPE_ALIGN : 1 = delay load_en/valid_in by PIPE cycles so they reach the DSP together
//                     with the data (mxfp_dot pipelines data but not the controls)
//   bit2 LOADA_ZERO : 1 = drive zeros during the first (don't-care) load cycle, as the TB does
//   bit3 SWAP_COLS  : 1 = present column-1 weights first, column-2 second
//   bit[7:4] RST_CYCLES extra: number of DUT reset cycles before loading = 4 + this field
// =============================================================================================
`default_nettype none

module mxfp_harness #(
  parameter int E = 2,
  parameter int M = 1,
  parameter int PIPE = 1,
  parameter int DUT_KIND = 0,   // 0 = paper's mxfp_dot (MXFP EeMm elements), 1 = bfp_dot (raw int8 lanes, tensor FP mode), 2 = fxp_dot (raw int8 lanes, tensor fixed-point mode + fabric rescale)
  parameter int DOT_LEN = 32,
  parameter int MAX_VEC = 64,
  parameter int TRACE_N = 192
) (
  input  wire        clk,
  input  wire        rst_n,

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

  localparam int W = (DUT_KIND != 0) ? 8 : M + E + 1;
  localparam int VW = 256;
  localparam int IDXW = $clog2(MAX_VEC);
  localparam int TW = $clog2(TRACE_N);

  assign av_waitrequest = 1'b0;

  // ------------------------------------------------------------------ storage
  logic [VW-1:0] w_col1, w_col2;
  logic [7:0]    e_col1, e_col2;
  logic [31:0] act_mem [0:7][0:MAX_VEC-1];
  logic [7:0]  act_exp [0:MAX_VEC-1];
  logic [31:0] res_c1 [0:MAX_VEC-1];
  logic [31:0] res_c2 [0:MAX_VEC-1];
  logic [31:0] trc_c1 [0:TRACE_N-1];
  logic [31:0] trc_c2 [0:TRACE_N-1];
  logic [3:0]  trc_fl [0:TRACE_N-1];

  logic [IDXW:0] nvec;
  logic [31:0]   cycles;
  logic [63:0]   free_cnt;
  logic [9:0]    mode;
  logic          err_overrun;
  logic          start_q, dut_rst_req;

  wire mode_two_load  = mode[0];
  wire mode_pipe_al   = mode[1];
  wire mode_loada_z   = mode[2];
  wire mode_swap      = mode[3];
  wire [3:0] mode_rst = mode[7:4];
  wire mode_raw = mode[8];          // DUT_KIND 2 only: raw int32 sums on the output ports
  wire mode_fxp_ld = mode[9];       // fixed-point preload: banks latch the 1st and 2nd cycles AFTER load_en falls

  // ------------------------------------------------------------------ Avalon write
  always_ff @(posedge clk) begin
    start_q     <= 1'b0;
    dut_rst_req <= 1'b0;
    if (!rst_n) begin
      nvec <= 'd1; mode <= 10'h003;
      w_col1 <= '0; w_col2 <= '0; e_col1 <= 8'd127; e_col2 <= 8'd127;
    end else if (av_write) begin
      case (av_address[10:8])
        3'h0: begin
          case (av_address[7:0])
            8'h01: begin start_q <= av_writedata[0]; dut_rst_req <= av_writedata[1]; end
            8'h03: nvec <= av_writedata[IDXW:0];
            8'h08: mode <= av_writedata[9:0];
            default: ;
          endcase
        end
        3'h1: begin
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

  // activation slots i = 0..63 live at words 0x200 + 16*i, i.e. 0x200..0x5FF
  wire        act_wr   = av_write && (av_address[10:9] == 2'b01 || av_address[10:9] == 2'b10);
  wire [5:0]  act_slot = {av_address[10], av_address[8:4]};
  always_ff @(posedge clk) begin
    if (act_wr && !av_address[3]) act_mem[av_address[2:0]][act_slot] <= av_writedata;
    if (act_wr &&  av_address[3] && av_address[2:0] == 3'd0) act_exp[act_slot] <= av_writedata[7:0];
  end

  // ------------------------------------------------------------------ Avalon read
  logic [31:0] rd_mux;
  wire  [TW-1:0] trc_rd_idx = av_address[TW:1];   // 0x680.. : (addr-0x680)/2; low bits suffice since 0x680 is 2-aligned
  always_comb begin
    rd_mux = 32'hDEAD_BEEF;
    case (av_address[10:8])
      3'h0: begin
        if (av_address[7]) begin // 0x080..0x0FF trace flags
          rd_mux = '0;
          for (int n = 0; n < 8; n++) begin
            int idx; idx = {av_address[6:0], 3'b000} + n;
            if (idx < TRACE_N) rd_mux[n*4 +: 4] = trc_fl[idx];
          end
        end else case (av_address[6:0])
          7'h00: rd_mux = 32'h4D58_0004;
          7'h02: rd_mux = {29'd0, err_overrun, done, busy};
          7'h03: rd_mux = {{(31-IDXW){1'b0}}, nvec};
          7'h04: rd_mux = {8'd0, DUT_KIND[7:0], E[7:0], M[7:0]};
          7'h05: rd_mux = cycles;
          7'h06: rd_mux = free_cnt[31:0];
          7'h07: rd_mux = free_cnt[63:32];
          7'h08: rd_mux = {22'd0, mode};
          default: rd_mux = 32'h0;
        endcase
      end
      3'h1: begin
        if (av_address[7:4] == 4'h0) rd_mux = av_address[3] ? {24'd0, e_col1} : w_col1[av_address[2:0]*32 +: 32];
        else if (av_address[7:4] == 4'h1) rd_mux = av_address[3] ? {24'd0, e_col2} : w_col2[av_address[2:0]*32 +: 32];
      end
      3'h2, 3'h3, 3'h4, 3'h5: rd_mux = av_address[3] ? {24'd0, act_exp[act_slot]} : act_mem[av_address[2:0]][act_slot];
      3'h6: begin
        if (!av_address[7]) rd_mux = av_address[0] ? res_c2[av_address[6:1]] : res_c1[av_address[6:1]];
        else begin // 0x680..0x6FF trace entries 0..63
          rd_mux = av_address[0] ? trc_c2[{1'b0, 1'b0, av_address[6:1]}] : trc_c1[{1'b0, 1'b0, av_address[6:1]}];
        end
      end
      3'h7: begin // 0x700..0x7FF trace entries 64..191
        rd_mux = av_address[0] ? trc_c2[{1'b0, av_address[7:1]} + 64] : trc_c1[{1'b0, av_address[7:1]} + 64];
      end
      default: ;
    endcase
  end
  always_ff @(posedge clk) begin
    av_readdatavalid <= av_read;
    av_readdata      <= rd_mux;
    free_cnt         <= rst_n ? free_cnt + 64'd1 : 64'd0;
  end

  // ------------------------------------------------------------------ sequencer
  typedef enum logic [3:0] {S_IDLE, S_RST, S_LOADA, S_LOAD2, S_LOAD1, S_LOAD1B, S_STREAM, S_DRAIN, S_DONE} state_t;
  state_t state;

  logic        s0_load, s0_valid, s0_sel_w2, s0_sel_w1, s0_zero;
  logic [IDXW-1:0] s0_idx;
  logic        s1_load, s1_valid, s1_sel_w2, s1_sel_w1, s1_zero;
  logic [IDXW-1:0] s1_idx;
  logic [IDXW:0]   stream_cnt, out_cnt;
  logic [4:0]      rst_cnt;
  logic            dut_rst;
  logic [VW-1:0]   act_vec_rd;
  logic [7:0]      act_exp_rd;
  logic [TW:0]     trc_cnt;

  always_comb begin
    for (int k = 0; k < 8; k++) act_vec_rd[k*32 +: 32] = act_mem[k][s1_idx];
    act_exp_rd = act_exp[s1_idx];
  end

  logic [VW-1:0] dut_vec;
  logic [7:0]    dut_exp;
  logic          dut_load, dut_valid;
  logic [31:0]   dut_out1, dut_out2;
  logic          dut_valid_out;
  logic          dut_load_al, dut_valid_al;

  // "first" weights = column 2 (goes with load_en high), "second" = column 1, unless swapped
  wire [VW-1:0] wfirst  = mode_swap ? w_col1 : w_col2;
  wire [7:0]    efirst  = mode_swap ? e_col1 : e_col2;
  wire [VW-1:0] wsecond = mode_swap ? w_col2 : w_col1;
  wire [7:0]    esecond = mode_swap ? e_col2 : e_col1;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= S_IDLE; busy <= 1'b0; done <= 1'b0; err_overrun <= 1'b0;
      s0_load <= 1'b0; s0_valid <= 1'b0; s0_sel_w1 <= 1'b0; s0_sel_w2 <= 1'b0; s0_zero <= 1'b0; s0_idx <= '0;
      s1_load <= 1'b0; s1_valid <= 1'b0; s1_sel_w1 <= 1'b0; s1_sel_w2 <= 1'b0; s1_zero <= 1'b0; s1_idx <= '0;
      stream_cnt <= '0; out_cnt <= '0; cycles <= '0; rst_cnt <= '0; dut_rst <= 1'b1;
      dut_load <= 1'b0; dut_valid <= 1'b0; dut_vec <= '0; dut_exp <= 8'd127; trc_cnt <= '1;
    end else begin
      s0_load <= 1'b0; s0_valid <= 1'b0; s0_sel_w1 <= 1'b0; s0_sel_w2 <= 1'b0; s0_zero <= 1'b0;
      s1_load <= s0_load; s1_valid <= s0_valid; s1_sel_w1 <= s0_sel_w1; s1_sel_w2 <= s0_sel_w2; s1_zero <= s0_zero; s1_idx <= s0_idx;
      dut_load  <= s1_load;
      dut_valid <= s1_valid;
      if (s1_zero)        begin dut_vec <= '0;         dut_exp <= 8'd0;       end
      else if (s1_sel_w2) begin dut_vec <= wfirst;     dut_exp <= efirst;     end
      else if (s1_sel_w1) begin dut_vec <= wsecond;    dut_exp <= esecond;    end
      else                begin dut_vec <= act_vec_rd; dut_exp <= act_exp_rd; end

      if (dut_rst_req) dut_rst <= 1'b1;

      case (state)
        S_IDLE: begin
          dut_rst <= dut_rst_req;
          if (start_q) begin
            state <= S_RST; rst_cnt <= 5'd4 + {1'b0, mode_rst}; dut_rst <= 1'b1;
            busy <= 1'b1; done <= 1'b0; err_overrun <= 1'b0;
            stream_cnt <= '0; out_cnt <= '0; cycles <= '0; trc_cnt <= '0;
          end
        end
        S_RST: begin
          cycles <= cycles + 1;
          if (rst_cnt == 0) begin dut_rst <= 1'b0; state <= mode_two_load ? S_LOADA : S_LOAD2; end
          else rst_cnt <= rst_cnt - 1;
        end
        S_LOADA: begin
          cycles <= cycles + 1;
          s0_load <= 1'b1; s0_sel_w2 <= 1'b1; s0_zero <= mode_loada_z;
          state <= S_LOAD2;
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
          state <= mode_fxp_ld ? S_LOAD1B : S_STREAM;
        end
        S_LOAD1B: begin // fixed-point tensor mode: column-2 weights in the second cycle after load_en falls
          cycles <= cycles + 1;
          s0_load <= 1'b0; s0_sel_w2 <= 1'b1;
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
          if (out_cnt >= nvec && trc_cnt >= TRACE_N) state <= S_DONE;
          if (cycles > 32'd4096) begin err_overrun <= 1'b1; state <= S_DONE; end
        end
        S_DONE: begin
          busy <= 1'b0; done <= 1'b1; state <= S_IDLE;
        end
        default: state <= S_IDLE;
      endcase

      if (dut_valid_out && state != S_IDLE) begin
        if (out_cnt < MAX_VEC) begin
          res_c1[out_cnt[IDXW-1:0]] <= dut_out1;
          res_c2[out_cnt[IDXW-1:0]] <= dut_out2;
        end
        out_cnt <= out_cnt + 1;
      end

      // per-cycle trace of the raw DSP outputs and the control signals as the DUT sees them
      if (trc_cnt < TRACE_N) begin
        trc_c1[trc_cnt[TW-1:0]] <= dut_out1;
        trc_c2[trc_cnt[TW-1:0]] <= dut_out2;
        trc_fl[trc_cnt[TW-1:0]] <= {dut_valid_out, dut_valid_al, dut_load_al, dut_rst};
        trc_cnt <= trc_cnt + 1;
      end
    end
  end

  // ------------------------------------------------------------------ control alignment
  generate if (PIPE == 0) begin : g_nopipe
    assign dut_load_al = dut_load; assign dut_valid_al = dut_valid;
  end else begin : g_pipe
    logic [PIPE-1:0] ld_sr, vl_sr;
    always_ff @(posedge clk) begin
      ld_sr <= {ld_sr, dut_load};
      vl_sr <= {vl_sr, dut_valid};
    end
    assign dut_load_al  = mode_pipe_al ? ld_sr[PIPE-1] : dut_load;
    assign dut_valid_al = mode_pipe_al ? vl_sr[PIPE-1] : dut_valid;
  end endgenerate

  // ------------------------------------------------------------------ DUT
  logic [W-1:0] mx_data_in [0:DOT_LEN-1];
  always_comb for (int j = 0; j < DOT_LEN; j++) mx_data_in[j] = dut_vec[j*W +: W];

  generate if (DUT_KIND == 0) begin : g_mxfp
    mxfp_dot #(
      .M(M), .E(E), .E_SHARED(8), .FP_BIAS(1), .SH_BIAS(127), .PIPE(PIPE), .DOT_LEN(DOT_LEN)
    ) dut (
      .clk(clk), .rst(dut_rst), .load_en(dut_load_al), .valid_in(dut_valid_al),
      .mx_data_in(mx_data_in), .shared_exponent(dut_exp),
      .fp32_dot_out_col1(dut_out1), .fp32_dot_out_col2(dut_out2), .valid_out(dut_valid_out),
      .fp32_flags_col1(), .fp32_flags_col2());
  end else if (DUT_KIND == 2) begin : g_fxp
    fxp_dot #(.PIPE(PIPE), .DOT_LEN(DOT_LEN)) dut (
      .clk(clk), .rst(dut_rst), .load_en(dut_load_al), .valid_in(dut_valid_al),
      .int8_in(mx_data_in), .shared_exponent(dut_exp), .raw_out(mode_raw),
      .fp32_dot_out_col1(dut_out1), .fp32_dot_out_col2(dut_out2), .valid_out(dut_valid_out),
      .fp32_flags_col1(), .fp32_flags_col2());
  end else begin : g_bfp
    bfp_dot #(.PIPE(PIPE), .DOT_LEN(DOT_LEN)) dut (
      .clk(clk), .rst(dut_rst), .load_en(dut_load_al), .valid_in(dut_valid_al),
      .int8_in(mx_data_in), .shared_exponent(dut_exp),
      .fp32_dot_out_col1(dut_out1), .fp32_dot_out_col2(dut_out2), .valid_out(dut_valid_out),
      .fp32_flags_col1(), .fp32_flags_col2());
  end endgenerate

endmodule

`default_nettype wire
