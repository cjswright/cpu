/*
 * writeback.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

`include "types.sv"

module writeback (
  input rst_async_i,
  input clk_i,

  input types::instruction_details_t        details_i,
  input                              [31:0] data_i,

  output        write_en_o,
  output [31:0] write_o,
  output [ 3:0] write_index_o
);

  /* All of the outputs of this module are fed into the register bank
   * which itself will enact the write on the next positive clock edge,
   * so this is all combinational.
   *
   * The FF block is basically just to document what's going on, but the
   * state changes are actually happening in the register bank.
   *
   * It's kinda weird, but it works!
   */

  logic disabled, op_req_writeback;

  assign disabled = (rst_async_i || !details_i.is_valid);
  assign op_req_writeback = details_i.modifies_reg_rd;

  assign write_index_o = details_i.rd;
  assign write_en_o = !disabled && op_req_writeback;
  assign write_o = data_i;

  always_ff @(posedge clk_i or posedge rst_async_i) begin
    $display("WRITEBK(%08x) v=%d data=%x write_en=%x rd=%x", details_i.instruction,
             details_i.is_valid, data_i, write_en_o, details_i.rd);
  end

endmodule
