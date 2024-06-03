/*
 * writeback.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

`include "types.sv"

module writeback(input         rst_async, clk,
                 input         types::InstructionDetails details,
                 input [31:0]  data,

                 output        write_en,
                 output [31:0] write,
                 output [3:0]  write_index
                 );

   /* All of the outputs of this module are fed into the register bank
    * which itself will enact the write on the next positive clock edge,
    * so this is all combinational.
    *
    * The FF block is basically just to document what's going on, but the
    * state changes are actually happening in the register bank.
    *
    * It's kinda weird, but it works!
    */

   logic                       disabled, op_req_writeback;

   assign disabled = (rst_async || !details.is_valid);
   assign op_req_writeback = details.op != `OPC_STORE;
   let write_pc = details.op inside {`OPC_JUMP, `OPC_JR, `OPC_JAL, `OPC_JALR, `OPC_BEQZ, `OPC_BNEZ};
   let is_conditional = details.op inside {`OPC_BEQZ, `OPC_BNEZ};

   assign write_index = details.rd;
   assign write_en = !disabled && op_req_writeback && !write_pc;
   assign write = data;

   always_ff @(posedge clk or posedge rst_async) begin
      $display("WRITEBK(%d) v=%d data=%x op=%x rd=%x offs=%x",
               rst_async, details.is_valid, data, details.op, details.rd, details.offs);
   end

endmodule
