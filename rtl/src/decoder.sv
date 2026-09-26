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
  input        valid_i,
  input        flush_i,

  output types::instruction_details_t details_o,
  output                              stall_o
);

  reg                          [3:0] last_rd_q;
  reg                          [3:0] last_op_q;

  logic                              op_reg_writeback;
  int                                valid_instr_count_q;

  types::instruction_details_t       details_d;
  types::instruction_details_t       details_q;

  assign details_o = details_q;

  assign op_reg_writeback = details_d.op inside {`OPS_REG_WRITEBACK};

  /* If the previous instruction modifies a register that we are about to jump
    * to, we need to insert a noop so the ALU can calculate the new value of the
    * register. */
  always_comb begin
    if (details_d.op inside { `OPC_JR, `OPC_JALR } &&
          last_op_q inside { `OPS_REG_WRITEBACK } && last_rd_q == details_d.rs)
      stall_o = 1;
    else stall_o = 0;
  end

  always_comb begin
    details_d.address = address_i;
    details_d.op = instruction_i[31:28];
    details_d.rd = instruction_i[27:24];
    details_d.rs = instruction_i[23:20];
    details_d.func = instruction_i[19:16];
    details_d.imm = instruction_i[15:0];
    details_d.offs = instruction_i[19:0];
    details_d.rt = instruction_i[3:0];
    details_d.is_valid = valid_i;

    if (flush_i) details_d.is_valid = 0;

    if (last_op_q inside {`OPC_ARITH, `OPC_AR_IM, `OPC_TEST, `OPC_TS_IM} &&
          last_rd_q != 0 && details_d.rs == last_rd_q)
      details_d.rs_hazard = types::ALU_REG_PREV;
    else if (last_op_q == `OPC_LOAD && last_rd_q == details_d.rs)
      details_d.rs_hazard = types::ALU_REG_MEM;
    else details_d.rs_hazard = types::ALU_REG_NORMAL;

    if (last_op_q inside {`OPC_ARITH, `OPC_AR_IM, `OPC_TEST, `OPC_TS_IM} &&
          last_rd_q != 0 && details_d.rt == last_rd_q)
      details_d.rt_hazard = types::ALU_REG_PREV;
    else if (last_op_q == `OPC_LOAD && last_rd_q == details_d.rt)
      details_d.rt_hazard = types::ALU_REG_MEM;
    else details_d.rt_hazard = types::ALU_REG_NORMAL;
  end  // always_comb

  logic [3:0] last_rd_d = details_d.rd;
  logic [3:0] last_op_d = details_d.op;

  always_ff @(posedge clk_i or posedge rst_async_i) begin
    if (rst_async_i) begin
      valid_instr_count_q <= 0;
    end

    if (!rst_async_i && op_reg_writeback) begin
      last_rd_q <= last_rd_d;
      last_op_q <= last_op_d;
    end else begin
      last_rd_q <= 0;
      last_op_q <= 4'hf;
    end

    details_q <= details_d;

    if (details_d.is_valid && !rst_async_i && details_d.op != `OPC_NOOP)
      valid_instr_count_q <= valid_instr_count_q + 1;

    $display("DECODER(%d) %x v=%d op=%x rd=%x rs=%x f=%x imm=%x offs=%x rt=%x %d %d", rst_async_i,
             instruction_i, details_d.is_valid, details_d.op, details_d.rd, details_d.rs,
             details_d.func, details_d.imm, details_d.offs, details_d.rt, details_d.rs_hazard,
             details_d.rt_hazard);

    $display("HAZARD last_op=%x last_rd_q=%d stall_o=%d", last_op_q, last_rd_q, stall_o);
  end

  final $display("Instructions executed %d", valid_instr_count_q);

endmodule
