/*
 * wramp.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

`include "types.sv"

module wramp (
    input clk,
    input rst_async,

    output        ifetch_req_en,
    output [19:0] ifetch_req_address,

    input        ifetch_is_valid,
    input [19:0] ifetch_address,
    input [31:0] ifetch_data,

    output var [19:0] mem_address,
    output            mem_read_en,

    input [31:0] mem_fetch_value,
    /* verilator lint_off UNUSED */
    input        mem_fetch_valid,
    /* verilator lint_on UNUSED */

    output        mem_write_en,
    output [31:0] mem_write_value,

    input  [ 3:0] debug_reg_index,
    output [31:0] debug_reg
);

  wire                      [31:0] instruction;
  wire                      [19:0] i_address;

  types::InstructionDetails        details;

  wire                      [ 3:0] read_a_index;
  wire                      [ 3:0] read_b_index;
  wire                      [ 3:0] read_c_index;
  wire                      [ 3:0] write_index;
  wire                             write_en;
  wire                      [31:0] write;
  wire                      [31:0] read_a;
  wire                      [31:0] read_b;
  wire                      [31:0] read_c;

  wire                             alu_is_set;

  register_bank _register_bank (
      .rst_async(rst_async),
      .clk(clk),
      .read_a_index(read_a_index),
      .read_b_index(read_b_index),
      .read_c_index(read_c_index),
      .write_index(write_index),
      .write_en(write_en),
      .write(write),
      .read_a(read_a),
      .read_b(read_b),
      .read_c(read_c),

      .debug_index(debug_reg_index),
      .debug(debug_reg)
  );

  types::InstructionDetails alu_details;

  wire ifetch_valid;
  wire ifetch_stalled;

  i_fetch _i_fetch (
      .rst_async(rst_async),
      .clk(clk),
      .stalled(ifetch_stalled),
      .out_fetch_en(ifetch_req_en),
      .out_instruction(instruction),
      .out_address(i_address),
      .valid(ifetch_valid),
      .req_mem_address(ifetch_req_address),
      .fetch_valid(ifetch_is_valid),
      .fetch_address(ifetch_address),
      .fetch_value(ifetch_data)
  );

  wire decoder_req_skip;

  assign ifetch_stalled = decoder_req_skip;

  decoder _decoder (
      .rst_async(rst_async),
      .clk(clk),
      .instruction(instruction),
      .address(i_address),
      .instruction_valid(ifetch_valid),
      .flush(!alu_is_set && details.op inside {`OPC_BEQZ, `OPC_BNEZ}),
      .details(details),
      .fetch_skip(decoder_req_skip)
  );

  wire [31:0] alu_out;

  alu _alu (
      .rst_async(rst_async),
      .clk(clk),
      .details(details),
      .read_a_index(read_a_index),
      .read_b_index(read_b_index),
      .read_a(read_a),
      .read_b(read_b),

      .mem(mem_fetch_value),

      .out(alu_out),
      .is_set(alu_is_set),
      .out_details(alu_details)
  );

  reg [31:0] mem_access_result;
  types::InstructionDetails mem_access_details;

  mem_access _mem_access (
      .rst_async(rst_async),
      .clk(clk),
      .details(alu_details),
      .data(alu_out),

      .mem_read_value(mem_fetch_value),
      .mem_write_value(mem_write_value),
      .mem_address(mem_address),
      .mem_read_en(mem_read_en),
      .mem_write_en(mem_write_en),

      .rd(read_c),
      .rd_index(read_c_index),

      .out_details(mem_access_details),
      .result(mem_access_result)
  );

  writeback _writeback (
      .rst_async(rst_async),
      .clk(clk),
      .details(mem_access_details),
      .data(mem_access_result),
      .write_en(write_en),
      .write(write),
      .write_index(write_index)
  );


endmodule
