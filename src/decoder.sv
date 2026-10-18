/*
 * decoder.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

`include "types.sv"

module decoder (
  input rst_async_i,
  input clk_i,

  input [31:0] instruction_i,
  input [19:0] address_i,
  input        branch_predicted_i,
  input [19:0] branch_dest_i,
  input        valid_i,
  input        flush_i,

  output jump_active_o,
  output [19:0] jump_destination_o,

  output types::instruction_details_t details_o,
  output                              stall_o
);

  int                          valid_instr_count_q;

  types::instruction_details_t decoded;
  types::instruction_details_t details_d;
  types::instruction_details_t details_q;

  assign details_o = details_q;
  logic [15:0] imm;
  assign imm = instruction_i[15:0];

  logic [3:0] func, op;
  assign func = instruction_i[19:16];
  assign op   = instruction_i[31:28];

  logic [19:0] offs;
  assign offs = instruction_i[19:0];

  logic is_lhi, is_conditional_branch, is_mem_load, is_mem_store, is_alu, is_jump_link, is_offs;

  always_comb begin
    decoded.instruction = instruction_i;
    decoded.address = address_i;
    decoded.branch_predicted = branch_predicted_i;
    decoded.branch_dest = branch_dest_i;

    decoded.op = op;
    decoded.rs = instruction_i[23:20];
    decoded.offs = offs;
    decoded.rt = instruction_i[3:0];

    decoded.is_valid = flush_i ? 0 : valid_i;

    is_lhi = op == `OPC_TS_IM && func == `FUNC_LHI;
    is_alu = op inside {`OPC_ARITH, `OPC_AR_IM, `OPC_TEST, `OPC_TS_IM, `OPC_LA};
    is_offs = op inside {`OPC_LOAD, `OPC_STORE, `OPC_JUMP, `OPC_LA};

    is_mem_store = op == `OPC_STORE;
    is_mem_load = op == `OPC_LOAD;
    is_conditional_branch = op inside {`OPC_BEQZ, `OPC_BNEZ};
    is_jump_link = op inside {`OPC_JAL, `OPC_JALR};

    decoded.is_alu_lhi = is_lhi;
    decoded.is_alu = is_alu;
    decoded.is_alu_offs = is_offs;

    decoded.is_mem_store = is_mem_store;
    decoded.is_mem_load = is_mem_load;
    decoded.is_conditional_branch = is_conditional_branch;
    decoded.conditional_req_state = op == `OPC_BNEZ;
    decoded.is_jump = op inside {`OPC_JUMP, `OPC_JR, `OPC_JAL, `OPC_JALR};
    decoded.is_direct_jump = op inside {`OPC_JUMP, `OPC_JAL};
    decoded.is_jump_link = is_jump_link;
    decoded.is_jump_register = op inside {`OPC_JR, `OPC_JALR};

    decoded.is_alu_set = (op inside {`OPC_TEST, `OPC_TS_IM} && !is_lhi) || is_conditional_branch;
    decoded.is_mem = is_mem_load || is_mem_store;
    decoded.modifies_reg_rd = is_mem_load || is_alu || is_jump_link;
    decoded.rd = is_jump_link ? 4'd15 : instruction_i[27:24];

    decoded.is_alu_imm = op inside {`OPC_AR_IM, `OPC_TS_IM}
      || is_conditional_branch || is_lhi || is_jump_link || is_offs;

    decoded.imm = is_conditional_branch ? 0 :
                  is_lhi ? { imm, 16'b0 } :
                  is_jump_link ? 1 :
                  is_offs ? { 12'b0, offs} :
                  func[0] ? { 16'b0, imm } :
                  {{16{imm[15]}}, imm};

    decoded.func = is_lhi | is_offs ? `FUNC_ADDS :
                   op == `OPC_BEQZ ? {`FUNC_SET_EQ, 1'b0} :
                   op == `OPC_BNEZ ? {`FUNC_SET_NEQ, 1'b0} :
                   func;

    decoded.branch_target = address_i + offs + 1;
  end  // always_comb

  always_comb begin
    if (details_q.is_valid && (
      /* ... or if we're doing an access from somewhere that we *just* did a load */
      /* into, we also need to wait a cycle... */
      (details_q.is_mem_load && details_q.rd == decoded.rs) ||
      (details_q.is_mem_load && details_q.rd == decoded.rt)
    ))
      stall_o = 1;
    else stall_o = 0;
  end

  logic jump_active;
  logic branch_not_predicted;

  /* If we're branching, but we weren't predicted, then we assume that branches
  /* with a negative offset are taken. */
  assign branch_not_predicted =
           decoded.is_conditional_branch && !branch_predicted_i && decoded.offs[19];

  assign jump_destination_o = branch_not_predicted ? decoded.branch_target : decoded.offs;

  assign jump_active = decoded.is_direct_jump || branch_not_predicted;
  assign jump_active_o = decoded.is_valid && !stall_o && jump_active;

  always_comb begin
    details_d = decoded;
    details_d.is_valid = decoded.is_valid && !stall_o;
    /* If we're on a branch and we weren't predicted, then take the initial
    /* prediction */
    if (branch_not_predicted) begin
      details_d.branch_dest = decoded.branch_target;
      details_d.branch_predicted = 1;
    end
  end

  always_ff @(posedge clk_i or posedge rst_async_i) begin
    if (rst_async_i) begin
      valid_instr_count_q <= 0;
    end

    details_q <= details_d;

    if (details_d.is_valid && !rst_async_i && details_d.op != `OPC_NOOP)
      valid_instr_count_q <= valid_instr_count_q + 1;

    $display("DECODER(%08x) a=%x v=%d op=%x rd=%x rs=%x f=%x imm=%x offs=%x rt=%x %d",
             instruction_i, address_i, details_d.is_valid, details_d.op, details_d.rd,
             details_d.rs, details_d.func, details_d.imm, details_d.offs, details_d.rt, stall_o);

    if (jump_active_o)
      $display("DECODER(%08x) JUMP offs=%x dest=%x", instruction_i, offs, jump_destination_o);

    $display("HAZARD stall_o=%d", stall_o);
  end

  final $display("Instructions executed %d", valid_instr_count_q);

endmodule
