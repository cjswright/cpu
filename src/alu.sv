/*
 * alu.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
*/

`include "types.sv"

module alu (input         rst_async, clk,

            input             types::InstructionDetails details,

            output [3:0]      read_a_index,
            output [3:0]      read_b_index,
            input [31:0]      read_a,
            input [31:0]      read_b,

            input [31:0]      mem,

            output reg [31:0] out,
            output            is_set,
            output            types::InstructionDetails out_details
            );
   
   assign read_a_index = details.rs;
   assign read_b_index = details.rt;
   assign is_set = next_out[0];

   let is_imm = details.op[0];

   logic [31:0]                 opa;
   logic [31:0]                 opb;
   reg [31:0]                   out2;
   reg [31:0]                   mem2;

   logic [31:0]                 next_out;
   types::InstructionDetails next_out_details;

   always_comb begin
      next_out_details = details;

      if (details.rs_hazard == types::ALU_REG_PREV)
        opa = out;
      else if (details.rs_hazard == types::ALU_REG_PREV2)
        opa = out2;
      else if (details.rs_hazard == types::ALU_REG_MEM)
        opa = mem;
      else if (details.rs_hazard == types::ALU_REG_MEM2)
        opa = mem2;
      else
        opa = read_a;

      if (is_imm)
        opb = { 16'b0, details.imm };
      else
        if (details.rt_hazard == types::ALU_REG_PREV)
          opb = out;
        else if (details.rt_hazard == types::ALU_REG_PREV2)
          opb = out2;
        else if (details.rt_hazard == types::ALU_REG_MEM)
          opb = mem;
        else if (details.rt_hazard == types::ALU_REG_MEM2)
          opb = mem2;
        else
          opb = read_b;

      if (details.op inside {`OPC_ARITH, `OPC_AR_IM}) begin
         // For reference, but it only matters for mult and divide
         //logic is_unsigned = details.func[0];
         casez (details.func)
           `FUNC_ADD: next_out = opa + opb;
           `FUNC_SUB: next_out = opa - opb;

           /* Not unsigned/signed */
           `FUNC_SLL: next_out = opa << opb;
           `FUNC_AND: next_out = opa & opb;
           `FUNC_SRL: next_out = opa >> opb;
           `FUNC_OR : next_out = opa | opb;
           `FUNC_SRA: next_out = opa >>> opb;
           `FUNC_XOR: next_out = opa ^ opb;
           default: next_out_details.is_valid = 0;
         endcase
      end else if (details.op inside {`OPC_TEST, `OPC_TS_IM}) begin
         casez (details.func)
           default: next_out_details.is_valid = 0;
         endcase
      end else if (details.op inside {`OPC_LOAD, `OPC_STORE, `OPC_JUMP}) begin
         next_out = opa + {11'b0, details.offs};
      end else if (details.op == `OPC_BNEZ) begin
         next_out = 0;
         next_out[0] = opa != 0;
      end else if (details.op == `OPC_BEQZ) begin
         next_out = 0;
         next_out[0] = opa == 0;
      end else begin
         next_out_details.is_valid = 0;
      end
   end

   always_ff @(posedge clk or posedge rst_async) begin
      $display("ALU    (%d) v=%d o=%x f=%x i=%x rs=%x rt=%x", rst_async, details.is_valid, details.op, details.func, details.imm, details.rs, details.rt);
      $display("ALU    read_a=%x read_b=%x opa=%x opb=%x", read_a, read_b, opa, opb);

      out_details <= next_out_details;
      out <= next_out;
      out2 <= out;
      mem2 <= mem;
   end
   
endmodule
