/*
 * alu.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
*/

`include "types.sv"

module alu (
  input rst_async_i,
  input clk_i,

  input types::instruction_details_t details_i,

  output [ 3:0] read_a_index_o,
  output [ 3:0] read_b_index_o,
  input  [31:0] read_a_i,
  input  [31:0] read_b_i,

  output reg                          [31:0] result_o,
  output                                     is_set_o,
  output types::instruction_details_t        details_o
);

  types::instruction_details_t details_q;
  assign details_o = details_q;

  logic [31:0] result_q;
  logic [31:0] result_d;
  assign result_o = result_q;

  assign read_a_index_o = details_i.rs;
  assign read_b_index_o = details_i.rt;
  assign is_set_o = result_d[0];

  logic                               is_imm = details_i.op[0];

  logic                        [31:0] opa;
  logic                        [31:0] opb;

  types::instruction_details_t        details_d;

  always_comb begin
    details_d = details_i;

    if (details_i.rs_hazard == types::ALU_REG_PREV) opa = result_q;
    else opa = read_a_i;

    if (is_imm) opb = {16'b0, details_i.imm};
    else if (details_i.rt_hazard == types::ALU_REG_PREV) opb = result_q;
    else opb = read_b_i;

    if (details_i.op inside {`OPC_ARITH, `OPC_AR_IM}) begin
      // For reference, but it only matters for mult and divide
      //logic is_unsigned = details_i.func[0];
      casez (details_i.func)
        `FUNC_ADD: result_d = opa + opb;
        `FUNC_SUB: result_d = opa - opb;

        /* Not unsigned/signed */
        `FUNC_SLL: result_d = opa << opb;
        `FUNC_AND: result_d = opa & opb;
        `FUNC_SRL: result_d = opa >> opb;
        `FUNC_OR:  result_d = opa | opb;
        `FUNC_SRA: result_d = opa >>> opb;
        `FUNC_XOR: result_d = opa ^ opb;
        default:   details_d.is_valid = 0;
      endcase
    end else if (details_i.op inside {`OPC_TEST, `OPC_TS_IM}) begin
      casez (details_i.func)
        default: details_d.is_valid = 0;
      endcase
    end else if (details_i.op inside {`OPC_LOAD, `OPC_STORE, `OPC_JUMP}) begin
      result_d = opa + {11'b0, details_i.offs};
    end else if (details_i.op == `OPC_BNEZ) begin
      result_d = 0;
      result_d[0] = opa != 0;
    end else if (details_i.op == `OPC_BEQZ) begin
      result_d = 0;
      result_d[0] = opa == 0;
    end else begin
      details_d.is_valid = 0;
    end
  end

  always_ff @(posedge clk_i or posedge rst_async_i) begin
    $display("ALU    (%d) v=%d o=%x f=%x i=%x rs=%x rt=%x", rst_async_i, details_i.is_valid,
             details_i.op, details_i.func, details_i.imm, details_i.rs, details_i.rt);
    $display("ALU    read_a=%x read_b=%x opa=%x opb=%x", read_a_i, read_b_i, opa, opb);

    details_q <= details_d;
    result_q  <= result_d;
  end

endmodule
