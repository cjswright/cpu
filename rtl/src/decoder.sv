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

  always_comb begin
    decoded.instruction = instruction_i;
    decoded.address = address_i;
    decoded.branch_predicted = branch_predicted_i;
    decoded.branch_dest = branch_dest_i;

    decoded.op = instruction_i[31:28];
    decoded.rd = instruction_i[27:24];
    decoded.rs = instruction_i[23:20];
    decoded.func = instruction_i[19:16];
    decoded.imm = instruction_i[15:0];
    decoded.offs = instruction_i[19:0];
    decoded.rt = instruction_i[3:0];

    decoded.is_valid = flush_i ? 0 : valid_i;

    decoded.is_alu_lhi = decoded.op == `OPC_TS_IM && decoded.func == `FUNC_LHI;
    decoded.is_alu = decoded.op inside {`OPC_ARITH, `OPC_AR_IM, `OPC_TEST, `OPC_TS_IM, `OPC_LA};
    decoded.is_alu_imm = decoded.op inside {`OPC_AR_IM, `OPC_TS_IM};
    decoded.is_alu_set = decoded.op inside {`OPC_TEST, `OPC_TS_IM} && !decoded.is_alu_lhi;
    decoded.is_alu_offs = decoded.op inside {`OPC_LOAD, `OPC_STORE, `OPC_JUMP, `OPC_LA};

    decoded.is_mem_store = decoded.op == `OPC_STORE;
    decoded.is_mem_load = decoded.op == `OPC_LOAD;
    decoded.is_mem = decoded.is_mem_load || decoded.is_mem_store;
    decoded.modifies_reg_rd = decoded.is_mem_load || decoded.is_alu;
    decoded.is_conditional_branch = decoded.op inside {`OPC_BEQZ, `OPC_BNEZ};
    decoded.conditional_req_state = decoded.op == `OPC_BNEZ;
    decoded.is_jump = decoded.op inside {`OPC_JUMP, `OPC_JR, `OPC_JAL, `OPC_JALR};
    decoded.is_direct_jump = decoded.op inside {`OPC_JUMP, `OPC_JAL};
    decoded.is_jump_link = decoded.op inside {`OPC_JAL, `OPC_JALR};
    decoded.is_jump_register = decoded.op inside {`OPC_JR, `OPC_JALR};

    decoded.branch_target = decoded.address + decoded.offs + 1;

    if (details_q.is_valid
      && details_q.modifies_reg_rd && details_q.rd != 0 && decoded.rs == details_q.rd)
      decoded.rs_hazard = types::ALU_REG_PREV;
    else decoded.rs_hazard = types::ALU_REG_NORMAL;

    if (details_q.is_valid
      && details_q.modifies_reg_rd && details_q.rd != 0 && decoded.rt == details_q.rd)
      decoded.rt_hazard = types::ALU_REG_PREV;
    else decoded.rt_hazard = types::ALU_REG_NORMAL;
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

    $display("DECODER(%08x) a=%x v=%d op=%x rd=%x rs=%x f=%x imm=%x offs=%x rt=%x %d %d, %d",
             instruction_i, address_i, details_d.is_valid, details_d.op, details_d.rd,
             details_d.rs, details_d.func, details_d.imm, details_d.offs, details_d.rt,
             details_d.rs_hazard, details_d.rt_hazard, stall_o);

    $display("HAZARD stall_o=%d", stall_o);
  end

  final $display("Instructions executed %d", valid_instr_count_q);

endmodule
