/*
 * register_bank.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

module register_bank(input rst_async, clk,
                     input [3:0]   read_a_index,
                     input [3:0]   read_b_index,
                     input [3:0]   read_c_index,
                     input [3:0]   jump_index,
                     input [3:0]   write_index,
                     input         write_en,
                     input [31:0]  write,
                     output [31:0] read_a,
                     output [31:0] read_b,
                     output [31:0] read_c,
                     output [19:0] jump,

                     input [3:0]   debug_index,
                     output [31:0] debug
                     );

   reg [31:0]                      registers[15:0];

   assign read_a = registers[read_a_index];
   assign read_b = registers[read_b_index];
   assign read_c = registers[read_c_index];
   assign jump = registers[jump_index][19:0];

   assign debug = registers[debug_index];

   always_ff @(posedge clk or posedge rst_async) begin
      $display("REGS r1=%x r2=%x r3=%x r4=%x r5=%x r15=%x",
               registers[1], registers[2], registers[3], registers[4], registers[5], registers[15]);
      if (rst_async)
        for (int i = 0; i < $size(registers); i++)
          registers[i] <= 0;
      else
        if (write_en && write_index != 0)
          registers[write_index] <= write;
   end
endmodule
