/*
 * mem_access.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

`include "types.sv"


module mem_access(input             rst_async, clk,
                  input             types::InstructionDetails details,
                  input [31:0]      data,

                  input [31:0]      mem_read_value,
                  output [31:0]     mem_write_value,
                  output [19:0]     mem_address,
                  output            mem_access_active,
                  output            mem_write_enable,

                  input [31:0]      rd,
                  output [3:0]      rd_index,

                  output            types::InstructionDetails out_details,
                  output reg [31:0] result
                  );

   let disabled = rst_async || !details.is_valid;
   let result_from_mem = (details.is_valid && details.op == `OPC_LOAD);

   assign mem_access_active = !disabled && (details.op == `OPC_LOAD || details.op == `OPC_STORE);
   assign mem_address = data[19:0];
   assign mem_write_value = rd;
   assign mem_write_enable = !disabled && details.op == `OPC_STORE;

   assign rd_index = details.rd;

   always_ff @(posedge clk or posedge rst_async) begin
      $display("MEMACC (%d) v=%d data=%d op=%d offs=%d",
               rst_async, details.is_valid, data, details.op, details.offs);

      out_details <= details;
      result <= result_from_mem ? mem_read_value : data;
   end

endmodule
