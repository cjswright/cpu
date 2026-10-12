/*
 * i_fetch.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

`include "types.sv"

module i_fetch (
  input rst_async_i,
  input clk_i,

  // For driving instruction bus
  output wire        fetch_en_o,
  output wire [19:0] fetch_address_o,
  // response from instruction bus
  input              valid_i,
  input       [19:0] address_i,
  input       [31:0] data_i,
  input              stalled_i,
  input              decoder_jump_en_i,
  input       [19:0] decoder_jump_dest_i,
  input              alu_branch_en_i,
  input       [19:0] alu_branch_dest_i,
  output             valid_o,
  output reg  [31:0] instruction_o,
  output      [19:0] address_o,

  output        branch_predict_req_o,
  output [19:0] branch_predict_req_addr_o,
  input         branch_predict_rsp_ok_i,
  input  [19:0] branch_predict_rsp_addr_i,
  output        branch_predicted_o,
  output [19:0] branch_dest_o
);

  logic [19:0] counter_q;
  logic [19:0] counter_d;

  reg          held_q;
  always_ff @(posedge clk_i or posedge rst_async_i)
    if (rst_async_i) held_q <= 0;
    else held_q <= valid_o && stalled_i;

  assign valid_o = held_q || valid_i;
  assign instruction_o = data_i;

  assign branch_predict_req_o = fetch_en_o;
  assign branch_predict_req_addr_o = fetch_address_o;

  assign counter_d = rst_async_i ? 0 : stalled_i ? fetch_address_o : fetch_address_o + 1;

  assign fetch_address_o =
           alu_branch_en_i ? alu_branch_dest_i
             : decoder_jump_en_i ? decoder_jump_dest_i
               : branch_predict_rsp_ok_i ? branch_predict_rsp_addr_i
                 : counter_q;
  assign fetch_en_o = !stalled_i;

  assign address_o = address_i;

  assign branch_predicted_o = branch_predict_rsp_ok_i;
  assign branch_dest_o = branch_predict_rsp_addr_i;

  always_ff @(posedge clk_i or posedge rst_async_i) begin
    if (rst_async_i) counter_q <= 0;
    else counter_q <= counter_d;

    $display("I_FETCH(%d) fetch=%d n_c=%d VSHF=%d%d%d%d", rst_async_i, fetch_address_o, counter_d,
             valid_i, stalled_i, held_q, fetch_en_o);
  end

endmodule
