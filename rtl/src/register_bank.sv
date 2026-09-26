/*
 * register_bank.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

module register_bank (
  input rst_async_i,
  input clk_i,

  input  [ 3:0] read_a_index_i,
  input  [ 3:0] read_b_index_i,
  input  [ 3:0] read_c_index_i,
  input  [ 3:0] write_index_i,
  input         write_en_i,
  input  [31:0] write_i,
  output [31:0] read_a_o,
  output [31:0] read_b_o,
  output [31:0] read_c_o,

  input  [ 3:0] debug_index_i,
  output [31:0] debug_o
);

  reg  [31:0] registers                                  [16];

  wire        wr_live = write_en_i && write_index_i != 0;

  assign read_a_o =
           (wr_live && write_index_i == read_a_index_i) ? write_i : registers[read_a_index_i];
  assign read_b_o =
           (wr_live && write_index_i == read_b_index_i) ? write_i : registers[read_b_index_i];
  assign read_c_o =
           (wr_live && write_index_i == read_c_index_i) ? write_i : registers[read_c_index_i];

  assign debug_o = registers[debug_index_i];

  always_ff @(posedge clk_i or posedge rst_async_i) begin
    $display("REGS r1=%x r2=%x r3=%x r4=%x r5=%x r15=%x", registers[1], registers[2], registers[3],
             registers[4], registers[5], registers[15]);
    if (rst_async_i) for (int i = 0; i < $size(registers); i++) registers[i] <= 0;
    else if (write_en_i && write_index_i != 0) registers[write_index_i] <= write_i;
  end
endmodule
