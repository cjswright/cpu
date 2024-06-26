/*
 * decoder.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

`include "types.sv"

   module decoder (input        rst_async, clk,
                   input [31:0] instruction,
                   input        flush,

                   output       types::InstructionDetails details,
                   output       fetch_skip
                   );

   reg [3:0] last_rd, last_rd2;
   reg [3:0] last_op, last_op2;

   var       op_reg_writeback;
   int       valid_instr_count;

   types::InstructionDetails next_details;

   assign op_reg_writeback = next_details.op inside `OPS_REG_WRITEBACK;

   /* If the previous instruction modifies a register that we are about to jump
    * to, we need to insert a noop so the ALU can calculate the new value of the
    * register. */
   always_comb begin
      if (next_details.op inside { `OPC_JR, `OPC_JALR } &&
          last_op inside `OPS_REG_WRITEBACK && last_rd == next_details.rs)
        fetch_skip = 1;
      else
        fetch_skip = 0;
   end

   always_comb begin
      next_details.op = instruction[31:28];
      next_details.rd = instruction[27:24];
      next_details.rs = instruction[23:20];
      next_details.func = instruction[19:16];
      next_details.imm = instruction[15:0];
      next_details.offs = instruction[19:0];
      next_details.rt = instruction[3:0];
      next_details.is_valid = 1;

      if (flush)
        next_details.is_valid = 0;

      if (last_op inside {`OPC_ARITH, `OPC_AR_IM, `OPC_TEST, `OPC_TS_IM} &&
          last_rd != 0 && next_details.rs == last_rd)
        next_details.rs_hazard = types::ALU_REG_PREV;
      else if (last_op2 inside {`OPC_ARITH, `OPC_AR_IM, `OPC_TEST, `OPC_TS_IM} &&
          last_rd2 != 0 && next_details.rs == last_rd2)
        next_details.rs_hazard = types::ALU_REG_PREV2;
      else if (last_op == `OPC_LOAD && last_rd == next_details.rs)
        next_details.rs_hazard = types::ALU_REG_MEM;
      else if (last_op2 == `OPC_LOAD && last_rd2 == next_details.rs)
        next_details.rt_hazard = types::ALU_REG_MEM2;
      else
        next_details.rs_hazard = types::ALU_REG_NORMAL;

      if (last_op inside {`OPC_ARITH, `OPC_AR_IM, `OPC_TEST, `OPC_TS_IM} &&
          last_rd != 0 && next_details.rt == last_rd)
        next_details.rt_hazard = types::ALU_REG_PREV;
      else if (last_op2 inside {`OPC_ARITH, `OPC_AR_IM, `OPC_TEST, `OPC_TS_IM} &&
          last_rd2 != 0 && next_details.rt == last_rd2)
        next_details.rt_hazard = types::ALU_REG_PREV2;
      else if (last_op == `OPC_LOAD && last_rd == next_details.rt)
        next_details.rt_hazard = types::ALU_REG_MEM;
      else if (last_op2 == `OPC_LOAD && last_rd2 == next_details.rt)
        next_details.rt_hazard = types::ALU_REG_MEM2;
      else
        next_details.rt_hazard = types::ALU_REG_NORMAL;

      if (last_rd == next_details.rd)
        next_details.store_reg_hazard = types::STORE_REG_RD;
      else
        next_details.store_reg_hazard = types::STORE_REG_NORMAL;
   end

   always_ff @(posedge clk or posedge rst_async) begin
      if (rst_async) begin
         valid_instr_count <= 0;
      end

      if (!rst_async && op_reg_writeback) begin
         last_rd <= next_details.rd;
         last_op <= next_details.op;
      end else begin
         last_rd <= 0;
         last_op <= 4'hf;
      end

      last_rd2 <= last_rd;
      last_op2 <= last_op;

      details <= next_details;

      if (next_details.is_valid && !rst_async && next_details.op != `OPC_NOOP)
        valid_instr_count <= valid_instr_count + 1;

      $display("DECODER(%d) %x v=%d op=%x rd=%x rs=%x f=%x imm=%x offs=%x rt=%x %d %d %d",
               rst_async, instruction, next_details.is_valid, next_details.op,
               next_details.rd, next_details.rs, next_details.func, next_details.imm,
               next_details.offs, next_details.rt,
               next_details.rs_hazard,
               next_details.rt_hazard,
               next_details.store_reg_hazard);

      $display("HAZARD last_op=%x last_rd=%d fetch_skip=%d", last_op, last_rd, fetch_skip);
   end

   final
     $display("Instructions executed %d", valid_instr_count);

endmodule
