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

  output branch_active_o,
  output [19:0] branch_address_o,
  output [19:0] branch_destination_o,

  output                              [31:0] result_o,
  output types::instruction_details_t        details_o
);

  types::instruction_details_t details_q;
  assign details_o = details_q;

  logic [31:0] result_q;
  logic [31:0] result_d;
  assign result_o = result_q;

  assign read_a_index_o = details_i.rs;
  assign read_b_index_o = details_i.rt;

  logic is_u = details_i.func[0];

  logic [31:0] opa;
  logic [31:0] opb;

  types::instruction_details_t details_d;

  logic branch_cond_met, branch_should_take, predicted_and_wrong, not_predicted_and_taken;
  logic [19:0] next_i_not_taken;

  assign branch_cond_met = (details_i.conditional_req_state && opa != '0) ||
                           (!details_i.conditional_req_state && opa == 0);
  assign branch_should_take = details_i.is_conditional_branch && branch_cond_met;
  assign next_i_not_taken = details_i.address + 1;

  assign branch_destination_o = branch_should_take ? details_i.branch_target : next_i_not_taken;
  assign branch_address_o = details_i.address;

  assign predicted_and_wrong = details_i.branch_predicted
             && branch_destination_o != details_i.branch_dest;
  assign not_predicted_and_taken = !details_i.branch_predicted && branch_should_take;
  assign branch_active_o = details_i.is_valid && (predicted_and_wrong || not_predicted_and_taken);

  logic [31:0] imm_value;
  always_comb begin
    if (is_u) imm_value = {16'b0, details_i.imm};
    else imm_value = {{16{details_i.imm[15]}}, details_i.imm};
  end

  always_comb begin
    if (details_i.rs_hazard == types::ALU_REG_PREV) opa = result_q;
    else opa = read_a_i;

    if (details_i.is_alu_imm) opb = imm_value;
    else if (details_i.rt_hazard == types::ALU_REG_PREV) opb = result_q;
    else opb = read_b_i;
  end

  logic [31:0] offs_out;
  assign offs_out = opa + {11'b0, details_i.offs};

  /* For set operations, alu_func gets overridden to subtract */
  logic [3:0] alu_func;
  assign alu_func = details_i.is_alu_set ? `FUNC_SUB : details_i.func;

  logic [32:0] alu_out, alu_opa, alu_opb;
  logic alu_err;
  assign alu_opa = {1'b0, opa};
  assign alu_opb = {1'b0, opb};
  always_comb begin
    alu_out = 0;
    alu_err = 0;
    casez (alu_func)
      `FUNC_ADD: alu_out = alu_opa + alu_opb;
      `FUNC_SUB: alu_out = alu_opa - alu_opb;

      /* Not unsigned/signed */
      `FUNC_SLL: alu_out = alu_opa << alu_opb;
      `FUNC_AND: alu_out = alu_opa & alu_opb;
      `FUNC_SRL: alu_out = alu_opa >> alu_opb;
      `FUNC_OR:  alu_out = alu_opa | alu_opb;
      `FUNC_SRA: alu_out = alu_opa >>> alu_opb;
      `FUNC_XOR: alu_out = alu_opa ^ alu_opb;
      default:   alu_err = 1;
    endcase
  end

  logic z, n, c;

  logic set_out;
  logic set_err;
  always_comb begin
    z = alu_out == 0;
    n = alu_out[31];
    c = alu_out[32];
    /* Probably only going to work with signed numbers; needs more test */
    case (details_i.func[3:1])
      `FUNC_SET_LT: set_out = is_u ? c : n;
      `FUNC_SET_GT: set_out = (is_u ? !c : !n) & !z;
      `FUNC_SET_LTE: set_out = (is_u ? c : n) | z;
      `FUNC_SET_GTE: set_out = (is_u ? !c : !n);
      `FUNC_SET_EQ: set_out = z;
      `FUNC_SET_NEQ: set_out = !z;
      default: set_err = 1;
    endcase
  end

  always_comb begin
    details_d = details_i;
    if (details_i.is_alu_lhi) begin
      result_d = {details_i.imm, 16'b0};
    end else if (details_i.is_alu_set) begin
      result_d = {31'b0, set_out};
      details_d.is_valid = !set_err;
    end else if (details_i.is_alu_offs) begin
      result_d = offs_out;
    end else begin
      result_d = alu_out[31:0];
      details_d.is_valid = !alu_err;
    end
  end

  always_ff @(posedge clk_i or posedge rst_async_i) begin
    if (!details_i.is_valid) begin
      $display("ALU    STALL");
    end else begin
      if (details_i.rs_hazard != types::ALU_REG_NORMAL ||
          details_i.rt_hazard != types::ALU_REG_NORMAL)
        $display("ALU    HAZARD rsh=%d rth=%d", details_i.rs_hazard, details_i.rt_hazard);

      if (details_i.is_alu) begin
        $display("ALU    (%08x) result=%x o=%x f=%x i=%x ofs=%x rs=%x rt=%x",
                 details_i.instruction, result_d, details_i.op, details_i.func, imm_value,
                 details_i.offs, details_i.rs, details_i.rt);
        $display("ALU    read_a=%x read_b=%x opa=%x opb=%x", read_a_i, read_b_i, opa, opb);
      end

      if (details_i.is_alu_offs) $display("ALU    OFFS v=%x", offs_out);

      if (details_i.is_conditional_branch)
        $display(
          "ALU    BRANCH MSWNA=%d%d%d%d%d",
          branch_cond_met,
          branch_should_take,
          predicted_and_wrong,
          not_predicted_and_taken,
          branch_active_o
        );

      if (details_i.is_alu_set)
        $display(
          "ALU    SET %x %x u=%d f=%s v=%x IZCN=%d%d%d%d o=%d",
          alu_opa,
          alu_opb,
          is_u,
          set_funcs[details_i.func[3:1]],
          alu_out,
          details_i.is_alu_imm,
          z,
          c,
          n,
          set_out
        );
    end

    details_q <= details_d;
    result_q  <= result_d;
  end

endmodule
