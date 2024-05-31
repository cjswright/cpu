/*
 * wramp.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

`include "types.sv"

module wramp(input clk, input rst_async,

             output [19:0] mem_address,
             input [31:0] mem_read_value,
             output mem_write_en,
             output [31:0] mem_write_value);

  wire [31:0] instruction;
  
  types::InstructionDetails details;
  
  wire [3:0] read_a_index;
  wire [3:0] read_b_index;
  wire [3:0] read_c_index;
  wire [3:0] write_index;
  wire write_en;
  wire [31:0] write;
  wire [31:0] read_a;
  wire [31:0] read_b;
  wire [31:0] read_c;
  
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
    .read_c(read_c));
  
  wire mem_access_active;
  wire [19:0] fetch_address;
  wire [19:0] mem_access_address;
  
  wire load_en;
  wire load_offset;
  wire [19:0] load_address;

  assign mem_address = mem_access_active ? mem_access_address : fetch_address;

  i_fetch _i_fetch (
    .rst_async(rst_async),
    .clk(clk),
    .instruction(instruction),
    .fetch_en(!mem_access_active),
    .mem_address(fetch_address),
    .mem_read_value(mem_read_value),
    .load_en(load_en),
    .load_offset(load_offset),
    .load_address(load_address)
  );
  decoder _decoder (
    .rst_async(rst_async),
    .clk(clk),
    .instruction (instruction),
    .details(details)
  );
  
  wire [31:0] alu_out;
  types::InstructionDetails alu_details;
  
  alu _alu (
    .rst_async(rst_async),
    .clk(clk),
    .details(details),
    .read_a_index(read_a_index),
    .read_b_index(read_b_index),
    .read_a(read_a),
    .read_b(read_b),
  
    .out(alu_out),
    .out_details(alu_details));
  
  types::InstructionDetails mem_access_details;
  wire [31:0] mem_access_result;
  mem_access _mem_access (
    .rst_async(rst_async),
    .clk(clk),
    .details(alu_details),
    .data(alu_out),
    
    .mem_read_value(mem_read_value),
    .mem_write_value(mem_write_value),
    .mem_address(mem_access_address),
    .mem_access_active(mem_access_active),
    .mem_write_enable(mem_write_en),
    
    .rd(read_c),
    .rd_index(read_c_index),

    .out_details(mem_access_details),
    .result(mem_access_result)
  );
  
  writeback _writeback(
    .rst_async(rst_async),
    .clk(clk),
    .details(mem_access_details),
    .data(mem_access_result),
    .write_en(write_en),
    .write(write),
    .write_index(write_index),
    .write_pc_en(load_en),
    .pc_offset(load_offset),
    .pc(load_address));


endmodule
