/*
 * wramp.sv - Skeleton top-level module for WRAMP
 *
 * Copyright 2015 by Dean Armstrong <dean.armstrong@virscient.com>
 *
 * This file is provided as a boilerplate for the top-level module that will
 * be developed as part of this assignment. The module developed should have
 * the same module header, but with the implementation fleshed out.
 */

`include "types.sv"


module wramp (
  //
  // Reset/clocking
  //

  // Asynchronous active high reset
  input         rst_async,

  // System clock (sequential logic must be synchronous
  // to rising edge)
  input         clk,

  //
  // Memory interface
  //

  // This port outputs the address for the current memory
  // operation.
  output [19:0] mem_address,

  // This port is used to return the value for a memory read
  input [31:0]  mem_read_value,

  // This output is asserted by the processor to instruct
  // that a memory write occur. This enable signal is active
  // high and should be asserted coincident with the memory
  // write value being valid on data_write_value.
  // Both outputs are synchronous to clk, so the memory write
  // will occur when data_write_enable is 1 on the rising edge
  // of clk
  output       mem_write_enable,
  // This port carries the memory write data. When
  // data_write_enable is 1 this data must be valid. At other
  // times the value driven on this output is not used
  output [31:0] mem_write_value
  );
  
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
    .mem_write_enable(mem_write_enable),
    
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
