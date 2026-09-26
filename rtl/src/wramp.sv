/*
 * wramp.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

`include "types.sv"

module wramp (
  input clk_i,
  input rst_async_i,

  output        ifetch_req_en_o,
  output [19:0] ifetch_req_address_o,

  input        ifetch_is_valid_i,
  input [19:0] ifetch_address_i,
  input [31:0] ifetch_data_i,

  output var [19:0] mem_address_o,
  output            mem_read_en_o,

  input [31:0] mem_fetch_value_i,
  /* verilator lint_off UNUSED */
  input        mem_fetch_valid_i,
  /* verilator lint_on UNUSED */

  output        mem_write_en_o,
  output [31:0] mem_write_value_o,

  input  [ 3:0] debug_reg_index_i,
  output [31:0] debug_reg_o
);

  wire                         [31:0] instruction;
  wire                         [19:0] i_address;

  types::instruction_details_t        details;

  wire                         [ 3:0] read_a_index;
  wire                         [ 3:0] read_b_index;
  wire                         [ 3:0] read_c_index;
  wire                         [ 3:0] read_jump_index;
  wire                         [ 3:0] write_index;
  wire                                write_en;
  wire                         [31:0] write;
  wire                         [31:0] read_a;
  wire                         [31:0] read_b;
  wire                         [31:0] read_c;
  wire                         [19:0] read_jump;

  register_bank _register_bank (
    .rst_async_i(rst_async_i),
    .clk_i(clk_i),
    .read_a_index_i(read_a_index),
    .read_b_index_i(read_b_index),
    .read_c_index_i(read_c_index),
    .read_jump_index_i(read_jump_index),
    .write_index_i(write_index),
    .write_en_i(write_en),
    .write_i(write),

    .read_a_o(read_a),
    .read_b_o(read_b),
    .read_c_o(read_c),
    .read_jump_o(read_jump),

    .debug_index_i(debug_reg_index_i),
    .debug_o(debug_reg_o)
  );

  types::instruction_details_t alu_details;

  wire ifetch_valid;
  wire ifetch_stalled;

  wire alu_jump_en;
  wire [19:0] alu_jump_destination;

  wire decoder_jump_en;
  wire [19:0] decoder_jump_destination;

  i_fetch _i_fetch (
    .rst_async_i(rst_async_i),
    .clk_i(clk_i),

    .fetch_en_o(ifetch_req_en_o),
    .fetch_address_o(ifetch_req_address_o),

    .valid_i(ifetch_is_valid_i),
    .address_i(ifetch_address_i),
    .data_i(ifetch_data_i),

    .stalled_i(ifetch_stalled),

    .decoder_jump_en_i  (decoder_jump_en),
    .decoder_jump_dest_i(decoder_jump_destination),

    .alu_jump_en_i  (alu_jump_en),
    .alu_jump_dest_i(alu_jump_destination),

    .valid_o(ifetch_valid),
    .instruction_o(instruction),
    .address_o(i_address)
  );

  wire decoder_req_skip;

  assign ifetch_stalled = decoder_req_skip;

  decoder _decoder (
    .rst_async_i(rst_async_i),
    .clk_i(clk_i),

    .instruction_i(instruction),
    .address_i(i_address),
    .valid_i(ifetch_valid),
    .flush_i(alu_jump_en),

    .jump_active_o(decoder_jump_en),
    .jump_destination_o(decoder_jump_destination),

    .jump_reg_index_o(read_jump_index),
    .jump_reg_i(read_jump),

    .details_o(details),
    .stall_o  (decoder_req_skip)
  );

  wire [31:0] alu_out;

  alu _alu (
    .rst_async_i(rst_async_i),
    .clk_i(clk_i),

    .details_i(details),

    .read_a_index_o(read_a_index),
    .read_b_index_o(read_b_index),
    .read_a_i(read_a),
    .read_b_i(read_b),

    .jump_active_o(alu_jump_en),
    .jump_destination_o(alu_jump_destination),

    .result_o (alu_out),
    .details_o(alu_details)
  );

  reg [31:0] mem_access_result;
  types::instruction_details_t mem_access_details;

  mem_access _mem_access (
    .rst_async_i(rst_async_i),
    .clk_i(clk_i),
    .details_i(alu_details),
    .data_i(alu_out),

    .mem_read_value_i(mem_fetch_value_i),
    .mem_write_value_o(mem_write_value_o),
    .mem_address_o(mem_address_o),
    .mem_read_en_o(mem_read_en_o),
    .mem_write_en_o(mem_write_en_o),

    .rd_i(read_c),
    .rd_index_o(read_c_index),

    .details_o(mem_access_details),
    .result_o (mem_access_result)
  );

  writeback _writeback (
    .rst_async_i(rst_async_i),
    .clk_i(clk_i),
    .details_i(mem_access_details),
    .data_i(mem_access_result),
    .write_en_o(write_en),
    .write_o(write),
    .write_index_o(write_index)
  );


endmodule
