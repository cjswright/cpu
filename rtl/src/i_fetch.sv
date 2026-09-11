/*
 * i_fetch.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

`include "types.sv"

module i_fetch(input             rst_async, clk,

               output reg [31:0] instruction,

               input             fetch_en,

               output [19:0]     mem_address,
               input [31:0]      mem_read_value,

               /* verilator lint_off UNOPTFLAT */
               input             revert_pc,
               /* verilator lint_on UNOPTFLAT */

               output [3:0]      jump_reg_index,
               input [19:0]      jump_reg);

   /* Need to keep track of old PCs for reverting flow back in case of
    * mis-predicts with jumps */
   reg [19:0]                    prev_counter[0:1];
   reg [19:0]                    counter;

   /* We predict next based on an always-take predictor */
   wire [3:0]                    opcode;

   var [19:0]                    pred_counter;

   assign opcode = instruction[31:28];

   always_comb begin
      /* Four possibilities:
       * 1) Absolute jump
       * 2) Relative jump
       * 3) Jump to register
       * 4) Increment
       */

      jump_reg_index = 0;

      if (revert_pc) begin
         pred_counter = prev_counter[1]+1;
         mem_address = prev_counter[1]+1;
      end else begin
         case (opcode)
           `OPC_JUMP, `OPC_JAL: begin
              /* 1) Absolute jump */
              pred_counter = instruction[19:0];
              mem_address = pred_counter;
           end
           `OPC_BEQZ, `OPC_BNEZ: begin
              /* 2) Relative jump */
              pred_counter = counter + instruction[19:0];
              mem_address = pred_counter;
           end
           `OPC_JR, `OPC_JALR: begin
              /* 3) Jump to register */
              jump_reg_index = instruction[23:20]; /* rs */
              pred_counter = jump_reg;
              mem_address = pred_counter;
           end
           default: begin
              pred_counter = counter;
              mem_address = counter;
           end
         endcase
      end
   end

   var [19:0]                   next_counter;
   always_comb begin
      if (rst_async) begin
         next_counter = 0;
      end else begin
         if (fetch_en)
           next_counter = pred_counter + 1;
         else
           next_counter = pred_counter;
      end
   end

   always_ff @(posedge clk or posedge rst_async) begin
      if (rst_async) begin
         counter <= 0;
         instruction <= 'hf000_0000;
      end else begin
         if (fetch_en) begin
            instruction <= mem_read_value;
         end else begin
            instruction <= 'hf000_0000;
         end
      end

      prev_counter[1] <= prev_counter[0];
      prev_counter[0] <= counter;
      counter <= next_counter;

      $display("I_FETCH(%d) p_c=%d n_c=%d c=%d f_en=%d r_pc=%d prev_pc=%d",
               rst_async, pred_counter, next_counter, counter, fetch_en, revert_pc, prev_counter[1]);
   end

endmodule
