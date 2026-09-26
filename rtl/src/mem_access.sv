/*
 * mem_access.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

`include "types.sv"


module mem_access (
  input rst_async_i,
  input clk_i,

  input types::instruction_details_t        details_i,
  input                              [31:0] data_i,

  input  [31:0] mem_read_value_i,
  output [31:0] mem_write_value_o,
  output [19:0] mem_address_o,
  output        mem_read_en_o,
  output        mem_write_en_o,

  input  [31:0] rd_i,
  output [ 3:0] rd_index_o,

  output types::instruction_details_t        details_o,
  output wire                         [31:0] result_o
);

  let disabled = rst_async_i || !details_i.is_valid;

  assign mem_address_o = data_i[19:0];

  assign mem_write_en_o = !disabled && details_i.is_mem_store;
  assign mem_read_en_o = !disabled && details_i.is_mem_load;
  assign mem_write_value_o = rd_i;
  assign rd_index_o = details_i.rd;

  logic                        [31:0] data_q;
  types::instruction_details_t        details_q;

  assign result_o  = details_q.is_mem_load ? mem_read_value_i : data_q;
  assign details_o = details_q;

  always_ff @(posedge clk_i or posedge rst_async_i) begin
    $display("MEMACC (%08x) v=%d data=%x op=%x offs=%x rd=%d %x, store=%d load=%d",
             details_i.instruction, details_i.is_valid, data_i, details_i.op, details_i.offs,
             details_i.rd, rd_i, mem_write_en_o, mem_read_en_o);

    // TODO: Assumes the mem access occurred in one cycle - need to link these properly
    details_q <= details_i;
    data_q <= data_i;
  end

endmodule
