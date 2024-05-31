/*
 * decoder.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

`include "types.sv"

module decoder (
  input rst_async, clk,
  input [31:0] instruction,
  
  output types::InstructionDetails details
);
  
  always_ff @(posedge clk or posedge rst_async) begin
    details.op <= instruction[31:28];
    details.rd <= instruction[27:24];
    details.rs <= instruction[23:20];
    details.func <= instruction[19:16];
    details.imm <= instruction[15:0];
    details.offs <= instruction[19:0];
    details.rt <= instruction[3:0];
    details.is_valid <= 1;

    $display("DECODER(%d) %x v=%d op=%d rd=%d rs=%d f=%d imm=%d offs=%d rt=%d",
             rst_async, instruction, details.is_valid, details.op, details.rd, details.rs, details.func, details.imm, details.offs, details.rt);
  end

endmodule
