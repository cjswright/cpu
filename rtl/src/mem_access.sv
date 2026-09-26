/*
 * mem_access.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

`include "types.sv"


module mem_access (
    input                                  rst_async,
    clk,
    input types::InstructionDetails        details,
    input                           [31:0] data,

    input  [31:0] mem_read_value,
    output [31:0] mem_write_value,
    output [19:0] mem_address,
    output        mem_read_en,
    output        mem_write_en,

    input  [31:0] rd,
    output [ 3:0] rd_index,

    output types::InstructionDetails        out_details,
    output wire                      [31:0] result
);

  let disabled = rst_async || !details.is_valid;
  let result_from_mem = (details.is_valid && details.op == `OPC_LOAD);

  assign mem_address = data[19:0];

  assign mem_write_en = !disabled && details.op == `OPC_STORE;
  assign mem_read_en = !disabled && details.op == `OPC_LOAD;
  assign mem_write_value = rd;
  assign rd_index = details.rd;

  reg [31:0] next_data;

  assign result = result_from_mem ? mem_read_value : next_data;

  always_ff @(posedge clk or posedge rst_async) begin
    $display("MEMACC (%d) v=%d data=%x op=%x offs=%x rd=%d %x, store=%d load=%d", rst_async,
             details.is_valid, data, details.op, details.offs, details.rd, rd, mem_write_en,
             mem_read_en);

    // TODO: Assumes the mem access occurred in one cycle - need to link these properly
    out_details <= details;
    next_data   <= data;
  end

endmodule
