/*
 * register_bank.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

module register_bank(
  input rst_async, clk,
  input [3:0] read_a_index,
  input [3:0] read_b_index,
  input [3:0] read_c_index,
  input [3:0] write_index,
  input write_en,
  input [31:0] write,
  output [31:0] read_a,
  output [31:0] read_b,
  output [31:0] read_c
);
  
  reg [31:0] registers[15:0];
  
  assign read_a = registers[read_a_index];
  assign read_b = registers[read_b_index];
  assign read_c = registers[read_c_index];
  
  always_ff @(posedge clk or posedge rst_async) begin
    $display("REGS r1=%d r2=%d r3=%d r4=%d r5=%d",
             registers[1], registers[2], registers[3], registers[4], registers[5]);
    if (rst_async)
      for (int i = 0; i < $size(registers); i++)
        registers[i] <= 0;
    else
      if (write_en && write_index != 0)
        registers[write_index] <= write;
  end
  
endmodule
