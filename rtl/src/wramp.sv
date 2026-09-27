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

  logic ifetch_valid;
  logic ifetch_stalled;

  logic ibranch_predicted;
  logic [19:0] ibranch_dest;

  logic alu_branch_en;
  logic [19:0] alu_branch_destination;

  logic decoder_jump_en;
  logic [19:0] decoder_jump_destination;

  logic predict_req_active;
  logic [19:0] predict_req_addr;
  logic predict_response;
  logic [19:0] predict_response_addr;

  branch_predictor _branch_predictor (
    .rst_async_i(rst_async_i),
    .clk_i(clk_i),
    .predict_req_active_i(predict_req_active),
    .predict_req_addr_i(predict_req_addr),

    .predict_response_o(predict_response),
    .predict_response_addr_o(predict_response_addr)
  );

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

    .alu_branch_en_i  (alu_branch_en),
    .alu_branch_dest_i(alu_branch_destination),

    .valid_o(ifetch_valid),
    .instruction_o(instruction),
    .address_o(i_address),

    .branch_predict_req_o(predict_req_active),
    .branch_predict_req_addr_o(predict_req_addr),
    .branch_predict_rsp_ok_i(predict_response),
    .branch_predict_rsp_addr_i(predict_response_addr),

    .branch_predicted_o(ibranch_predicted),
    .branch_dest_o(ibranch_dest)
  );

  logic decoder_req_skip;

  assign ifetch_stalled = decoder_req_skip;

  decoder _decoder (
    .rst_async_i(rst_async_i),
    .clk_i(clk_i),

    .instruction_i(instruction),
    .address_i(i_address),
    .branch_predicted_i(ibranch_predicted),
    .branch_dest_i(ibranch_dest),
    .valid_i(ifetch_valid),
    .flush_i(alu_branch_en),

    .jump_active_o(decoder_jump_en),
    .jump_destination_o(decoder_jump_destination),

    .jump_reg_index_o(read_jump_index),
    .jump_reg_i(read_jump),

    .details_o(details),
    .stall_o  (decoder_req_skip)
  );

  logic [31:0] alu_out;

  alu _alu (
    .rst_async_i(rst_async_i),
    .clk_i(clk_i),

    .details_i(details),

    .read_a_index_o(read_a_index),
    .read_b_index_o(read_b_index),
    .read_a_i(read_a),
    .read_b_i(read_b),

    .branch_active_o(alu_branch_en),
    .branch_destination_o(alu_branch_destination),

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
