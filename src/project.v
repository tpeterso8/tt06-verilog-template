\m5_TLV_version 1d --inlineGen --noDirectiveComments --noline --clkAlways --bestsv --debugSigsYosys: tl-x.org
\m5
   use(m5-1.0)
   
   
   // ########################################################
   // #                                                      #
   // #  Empty template for Tiny Tapeout Makerchip Projects  #
   // #                                                      #
   // ########################################################
   
   // ========
   // Settings
   // ========
   
   //-------------------------------------------------------
   // Build Target Configuration
   //
   // To build within Makerchip for the FPGA or ASIC:
   //   o Use first line of file: \m5_TLV_version 1d --inlineGen --noDirectiveComments --noline --clkAlways --bestsv --debugSigsYosys: tl-x.org
   //   o set(MAKERCHIP, 0)  // (below)
   //   o For ASIC, set my_design (below) to match the configuration of your repositoy:
   //       - tt_um_fpga_hdl_demo for tt_fpga_hdl_demo repo
   //       - tt_um_example for tt06_verilog_template repo
   //   o var(target, FPGA)  // or ASIC (below)
   set(MAKERCHIP, 0)   /// 1 for simulating in Makerchip.
   var(my_design, tt_um_template)   /// The name of your top-level TT module, to match your info.yml.
   var(target, FPGA)  /// FPGA or ASIC
   //-------------------------------------------------------
   
   var(debounce_inputs, 0)         /// 1: Provide synchronization and debouncing on all input signals.
                                   /// 0: Don't provide synchronization and debouncing.
                                   /// m5_neq(m5_MAKERCHIP, 1): Debounce unless in Makerchip.
   
   // ======================
   // Computed From Settings
   // ======================
   
   // If debouncing, a user's module is within a wrapper, so it has a different name.
   var(user_module_name, m5_if(m5_debounce_inputs, my_design, m5_my_design))
   var(debounce_cnt, m5_if_eq(m5_MAKERCHIP, 1, 8'h03, 8'hff))

\SV
   // Include Tiny Tapeout Lab.
   m4_include_lib(['https:/']['/raw.githubusercontent.com/os-fpga/Virtual-FPGA-Lab/35e36bd144fddd75495d4cbc01c4fc50ac5bde6f/tlv_lib/tiny_tapeout_lib.tlv'])

// +++++++INSERT CODE++++++++++++++INSERT CODE++++++++++++++INSERT CODE++++++++++++++INSERT CODE++++++++++++++INSERT CODE++++++++++++++INSERT CODE+++++++
// +++++++INSERT CODE++++++++++++++INSERT CODE++++++++++++++INSERT CODE++++++++++++++INSERT CODE++++++++++++++INSERT CODE++++++++++++++INSERT CODE+++++++
\TLV my_design()
   |time
      @0
         $reset = *reset;
         $btn[3:0] = *ui_in[3:0];
         
         // divides clock for better switching on dual seven-segment
         $clk_disp = >>20$clk_disp ? 1'b0 : >>20$clk_disp + 1'b1;
         
         $cnt[20:0] =
            $reset || ((>>1$start == 0) && $start) ? 0 :
            >>1$time_clk ? 0 :
            (1 + >>1$cnt);
         //time_clk counts the num of cycles equal to 0.1s
         $time_clk = ($cnt == 21'b111101000010010000000);
         // 100 in binary 1100100
         $sec_cnt[3:0] =
            $reset || ((>>1$start == 0) && $start) ? 0 :
            (>>1$sec_cnt == 4'd10) ? 4'd0 :
            >>1$time_clk ? (1 + >>1$sec_cnt):
            >>1$sec_cnt;
         
         // begins the countdown display
         $start =
            $reset || ($btn == 4'd2) ? 0 :
            >>1$start ? 1 :
            $btn == 4'd1 ? 1 :
            0;
         //game is paused when user clicks button 2
         $p1_sub =
            $reset || ($btn == 4'd2) ? 0 :
            $start && (($btn == 4'd4) || ($btn == 4'd12)) ? 1 :
            >>1$p1_sub;
         //game is paused when user clicks button 3 (2 player)
         $p2_sub =
            $reset || ($btn == 4'd2) ? 0 :
            $start && (($btn == 4'd8) || ($btn == 4'd12)) ? 1 :
            >>1$p2_sub;
         //random counter to select goal time
         $rand_cnt[2:0] =
            $reset ? 3'd0 :
            $start ? >>1$rand_cnt :
            !$start && (>>1$start == 0) ? >>1$rand_cnt :
            (>>1$rand_cnt == 3'd4) ? 3'd0 :
            (3'd1 + >>1$rand_cnt);
         
         //random goal value, 5.0-9.0 by 1.0 each step
         $rand_goal[7:0] =
            $reset ? {4'd5,4'd0} :
            ($rand_cnt == 3'd0) ? {4'd6,4'd0} :
            ($rand_cnt == 3'd1) ? {4'd8,4'd0} :
            ($rand_cnt == 3'd2) ? {4'd9,4'd0} :
            ($rand_cnt == 3'd3) ? {4'd5,4'd0} :
            ($rand_cnt == 3'd4) ? {4'd7,4'd0} :
            {4'd9,4'd0};
         
         //left disp?
         $ones[3:0] =
            $reset ? 4'd0 :
            ($btn == 4'd0) && !$start ? $rand_goal[3:0] :
            (>>1$start == 0) && $start ? 4'd0 :
            (>>1$ones == 4'd9) && (>>1$tens == 4'd9) ? 4'd9 :
            >>1$time_clk && (>>1$ones != 4'd9) && $start ? (>>1$ones + 4'd1) :
            >>1$time_clk && (>>1$ones == 4'd9) && $start ? 4'd0 :
            >>1$ones;
         //right disp?
         $tens[3:0] =
            $reset ? 4'd0 :
            ($btn == 4'd0) && !$start ? $rand_goal[7:4] :
            (>>1$start == 0) && $start ? 4'd0 :
            (>>1$ones == 4'd9) && (>>1$tens == 4'd9) ? 4'd9 :
            ($sec_cnt == 4'd10) && (>>1$tens != 4'd9) && $start ? (>>1$tens + 4'd1) :
            ($sec_cnt == 4'd10) && (>>1$tens == 4'd9) && $start ? 4'd0 :
            >>1$tens;
         //after X time disp hides so player can asnwer
         $hide =
            $reset || ($btn == 4'd2) || ($p1_sub && $p2_sub) ? 0 :
            (>>1$ones == 4'd0) && (>>1$tens == 4'd3) ? 1 :
            >>1$hide ? 1 :
            0;
         //These variables store the answers for p1 and p2
         $p1_ans[7:0] =
            $reset || ($btn == 4'd2) ? 8'd0 :
            >>1$p1_sub ? >>1$p1_ans :
            (($btn == 4'd4) || ($btn == 4'd12)) && $start ? {>>1$tens[3:0],>>1$ones[3:0]} :
            >>1$p1_ans;
         $p2_ans[7:0] =
            $reset || ($btn == 4'd2) ? 8'd0 :
            >>1$p2_sub ? >>1$p2_ans :
            (($btn == 4'd8) || ($btn == 4'd12)) && $start ? {>>1$tens[3:0],>>1$ones[3:0]} :
            >>1$p2_ans;
         //determines a players score, calculates how far off a player was
         $p1_score[7:0] =
            $reset || ($btn == 4'd2) ? 8'd0 :
            >>1$p1_sub ? >>1$p1_score :
            $p1_sub && ($p1_ans[7:4]>=$rand_goal[7:4]) ? {$p1_ans[7:4]-$rand_goal[7:4],$p1_ans[3:0]} :
            $p1_sub && ($p1_ans[7:4]<=$rand_goal[7:4]) && ($p1_ans[3:0] == 4'd0) ? {$rand_goal[7:4]-$p1_ans[7:4],$p1_ans[3:0]} :
            $p1_sub && ($p1_ans[7:4]<=$rand_goal[7:4]) ? {$rand_goal[7:4]-$p1_ans[7:4]-4'd1,4'd10-$p1_ans[3:0]} :
            >>1$p1_score;
         $p2_score[7:0] =
            $reset || ($btn == 4'd2) ? 8'd0 :
            >>1$p2_sub ? >>1$p2_score :
            $p2_sub && ($p2_ans[7:4]>=$rand_goal[7:4]) ? {$p2_ans[7:4]-$rand_goal[7:4],$p2_ans[3:0]} :
            $p2_sub && ($p2_ans[7:4]<=$rand_goal[7:4]) && ($p2_ans[3:0] == 4'd0) ? {$rand_goal[7:4]-$p2_ans[7:4],$p2_ans[3:0]} :
            $p2_sub && ($p2_ans[7:4]<=$rand_goal[7:4]) ? {$rand_goal[7:4]-$p2_ans[7:4]-4'd1,4'd10-$p2_ans[3:0]} :
            >>1$p2_score;
         //determines the winner of the game, 0 is a tie, 1 is player 1, 2 is player 2
         $winner[1:0] =
            $reset || ($btn == 4'd2) ? 2'd3 :
            >>5$p1_sub && >>5$p2_sub ? >>1$winner :
            $p1_sub && $p2_sub && $p1_score[7:4]>$p2_score[7:4] ? 2'd2 :
            $p1_sub && $p2_sub && $p1_score[7:4]<$p2_score[7:4] ? 2'd1 :
            $p1_sub && $p2_sub && $p1_score[3:0]>$p2_score[3:0] ? 2'd2 :
            $p1_sub && $p2_sub && $p1_score[3:0]<$p2_score[3:0] ? 2'd1 :
            $p1_sub && $p2_sub && $p1_score[7:0]==$p2_score[7:0] ? 2'd0 :
            2'd3;
         
         $digit[3:0] =
            $clk_disp && $p1_sub && $p2_sub && ($btn == 4'd5) ? $p1_ans[7:4] :
            $p1_sub && $p2_sub && ($btn == 4'd5) ? $p1_ans[3:0] :
            $clk_disp && $p1_sub && $p2_sub && ($btn == 4'd9) ? $p2_ans[7:4] :
            $p1_sub && $p2_sub && ($btn == 4'd9) ? $p2_ans[3:0] :
            $clk_disp && >>2$p1_sub && >>2$p2_sub && ($winner == 2'd0) ? 4'd0 :
            $clk_disp && >>2$p1_sub && >>2$p2_sub && ($winner == 2'd1) ? 4'd1 :
            $clk_disp && >>2$p1_sub && >>2$p2_sub && ($winner == 2'd2) ? 4'd2 :
            $clk_disp && >>2$p1_sub && >>2$p2_sub && ($winner == 2'd3) ? 4'd3 :
            $p1_sub && $p2_sub ? 4'd11 :
            $clk_disp ? $tens :
            $ones;
         
         //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
         // decodes either tens or ones place to the seven-segments
         *uo_out[7:0] = {$clk_disp,
            ($hide) ? 7'b1000000 :
            ($digit == 4'd0) ? 7'b0111111 :
            ($digit == 4'd1) ? 7'b0000110 :
            ($digit == 4'd2) ? 7'b1011011 :
            ($digit == 4'd3) ? 7'b1001111 :
            ($digit == 4'd4) ? 7'b1100110 :
            ($digit == 4'd5) ? 7'b1101101 :
            ($digit == 4'd6) ? 7'b1111101 :
            ($digit == 4'd7) ? 7'b0000111 :
            ($digit == 4'd8) ? 7'b1111111 :
            ($digit == 4'd9) ? 7'b1101111 :
            ($digit == 4'd10) ? 7'b1110011 :
            ($digit == 4'd11) ? 7'b1001001 :
                             7'b0000000};
         


   // Connect Tiny Tapeout outputs. Note that uio_ outputs are not available in the Tiny-Tapeout-3-based FPGA boards.
   m5_if_neq(m5_target, FPGA, ['*uio_out = 8'b0;'])
   m5_if_neq(m5_target, FPGA, ['*uio_oe = 8'b0;'])

// +++++++INSERT CODE++++++++++++++INSERT CODE++++++++++++++INSERT CODE++++++++++++++INSERT CODE++++++++++++++INSERT CODE++++++++++++++INSERT CODE+++++++
// +++++++INSERT CODE++++++++++++++INSERT CODE++++++++++++++INSERT CODE++++++++++++++INSERT CODE++++++++++++++INSERT CODE++++++++++++++INSERT CODE+++++++

\SV

// ================================================
// A simple Makerchip Verilog test bench driving random stimulus.
// Modify the module contents to your needs.
// ================================================

module top(input logic clk, input logic reset, input logic [31:0] cyc_cnt, output logic passed, output logic failed);
   // Tiny tapeout I/O signals.
   logic [7:0] ui_in, uo_out;
   m5_if_neq(m5_target, FPGA, ['logic [7:0]uio_in,  uio_out, uio_oe;'])
   logic [31:0] r;  // a random value
   always @(posedge clk) r <= m5_if(m5_MAKERCHIP, ['$urandom()'], ['0']);
   assign ui_in = r[7:0];
   m5_if_neq(m5_target, FPGA, ['assign uio_in = 8'b0;'])
   logic ena = 1'b0;
   logic rst_n = ! reset;
   
   /*
   // Or, to provide specific inputs at specific times (as for lab C-TB) ...
   // BE SURE TO COMMENT THE ASSIGNMENT OF INPUTS ABOVE.
   // BE SURE TO DRIVE THESE ON THE B-PHASE OF THE CLOCK (ODD STEPS).
   // Driving on the rising clock edge creates a race with the clock that has unpredictable simulation behavior.
   initial begin
      #1  // Drive inputs on the B-phase.
         ui_in = 8'h0;
      #10 // Step 5 cycles, past reset.
         ui_in = 8'hFF;
      // ...etc.
   end
   */

   // Instantiate the Tiny Tapeout module.
   m5_user_module_name tt(.*);
   
   assign passed = top.cyc_cnt > 60;
   assign failed = 1'b0;
endmodule


// Provide a wrapper module to debounce input signals if requested.
m5_if(m5_debounce_inputs, ['m5_tt_top(m5_my_design)'])
\SV



// =======================
// The Tiny Tapeout module
// =======================

module m5_user_module_name (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    m5_if_eq(m5_target, FPGA, ['/']['*'])   // The FPGA is based on TinyTapeout 3 which has no bidirectional I/Os (vs. TT6 for the ASIC).
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    m5_if_eq(m5_target, FPGA, ['*']['/'])
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
   wire reset = ! rst_n;
   
\TLV
   /* verilator lint_off UNOPTFLAT */
   // Connect Tiny Tapeout I/Os to Virtual FPGA Lab.
   m5+tt_connections()
   
   // Instantiate the Virtual FPGA Lab.
   m5+board(/top, /fpga, 7, $, , my_design)
   // Label the switch inputs [0..7] (1..8 on the physical switch panel) (top-to-bottom).
   m5+tt_input_labels_viz(['"UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED"'])

\SV
endmodule
