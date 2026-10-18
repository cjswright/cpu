/*
 * alu.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
*/

`include "types.sv"

module alu (
  input rst_async_i,
  input clk_i,

  /* verilator lint_off UNUSEDSIGNAL */
  types::instruction_details_t details_i,
  /* verilator lint_on UNUSEDSIGNAL */
  input [31:0] opa_i,
  input [31:0] opb_i,

  input is_set_i,
  input [3:0] func_i,

  output [31:0] result_o,
  output fault_o
);

  logic is_u;
  assign is_u = func_i[0];

  /* For set operations, alu_func gets overridden to subtract */
  logic [3:0] alu_func;

  logic [32:0] alu_out, alu_opa_i, alu_opb_i;
  logic alu_err;
  assign alu_opa_i = {1'b0, opa_i};
  assign alu_opb_i = {1'b0, opb_i};
  always_comb begin
    alu_err  = 0;
    alu_func = is_set_i ? `FUNC_SUBS : func_i;
    casez (alu_func)
      `FUNC_ADDZ: alu_out = alu_opa_i + alu_opb_i;
      `FUNC_SUBZ: alu_out = alu_opa_i - alu_opb_i;

      /* Not unsigned/signed */
      `FUNC_SLL: alu_out = alu_opa_i << alu_opb_i;
      `FUNC_AND: alu_out = alu_opa_i & alu_opb_i;
      `FUNC_SRL: alu_out = alu_opa_i >> alu_opb_i;
      `FUNC_OR:  alu_out = alu_opa_i | alu_opb_i;
      `FUNC_SRA: alu_out = alu_opa_i >>> alu_opb_i;
      `FUNC_XOR: alu_out = alu_opa_i ^ alu_opb_i;
      default: begin
        alu_err = 1;
        alu_out = 0;
      end
    endcase
  end

  logic z, n, c;

  logic set_out;
  logic set_err;
  always_comb begin
    set_err = 0;
    set_out = 0;
    z = alu_out == 0;
    n = alu_out[31];
    c = alu_out[32];
    /* Probably only going to work with signed numbers; needs more test */
    case (func_i[3:1])
      `FUNC_SET_LT: set_out = is_u ? c : n;
      `FUNC_SET_GT: set_out = (is_u ? !c : !n) & !z;
      `FUNC_SET_LTE: set_out = (is_u ? c : n) | z;
      `FUNC_SET_GTE: set_out = (is_u ? !c : !n);
      `FUNC_SET_EQ: set_out = z;
      `FUNC_SET_NEQ: set_out = !z;
      default: set_err = 1;
    endcase
  end

  assign result_o = is_set_i ? {31'b0, set_out} : alu_out[31:0];
  assign fault_o  = !details_i.is_valid || (is_set_i ? set_err : alu_err);

  always_ff @(posedge clk_i or posedge rst_async_i) begin
    if (!details_i.is_valid) begin
      $display("ALU    STALL");
    end else begin
      if (is_set_i)
        $display(
          "ALU    SET %x %x u=%d f=%s v=%x ZCN=%d%d%d o=%d",
          opa_i,
          opb_i,
          is_u,
          set_funcs[func_i[3:1]],
          alu_out,
          z,
          c,
          n,
          set_out
        );
      else begin
        $display("ALU    (%08x) result=%x o=%x f=%x i=%x ofs=%x rs=%x rt=%x",
                 details_i.instruction, result_o, details_i.op, details_i.func, details_i.imm,
                 details_i.offs, details_i.rs, details_i.rt);
        $display("ALU    opa=%x opb=%x", opa_i, opb_i);
      end
    end
  end

endmodule
