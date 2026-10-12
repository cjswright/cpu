/*
 * types.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

`ifndef TYPES_SV
`define TYPES_SV

package types;
  typedef enum logic [1:0] {
    TYPE_R,
    TYPE_I,
    TYPE_J
  } type_e;
  typedef enum logic [1:0] {
    ALU_REG_NORMAL,
    ALU_REG_PREV
  } alu_reg_hazard_e;

  typedef struct {
    logic [19:0] address;
    logic [31:0] instruction;

    logic branch_predicted;
    logic [19:0] branch_dest;

    logic is_alu;
    logic is_mem;
    logic is_mem_store;
    logic is_mem_load;
    logic modifies_reg_rd;
    logic is_conditional_branch;
    logic conditional_req_state;
    logic is_jump;
    logic is_direct_jump;
    logic is_jump_link;
    logic is_jump_register;

    logic is_alu_lhi;
    logic is_alu_imm;
    logic is_alu_set;
    logic is_alu_offs;

    logic [19:0] branch_target;

    logic [3:0]  op;
    logic [3:0]  rd;
    logic [3:0]  rs;
    logic [3:0]  func;
    logic [15:0] imm;
    logic [19:0] offs;
    logic [3:0]  rt;

    /* Used to make bad instructions have no effect. Should probably fault. */
    logic is_valid;

    /* Rest of this is for hazard avoidance */

    /* Used to send the output of this instruction to the rs or rt parameter
       * of the next instruction in the ALU */
    alu_reg_hazard_e rs_hazard;
    alu_reg_hazard_e rt_hazard;
  } instruction_details_t;
endpackage


`define OPC_ARITH 'b0000
`define OPC_AR_IM 'b0001
`define OPC_TEST 'b0010
`define OPC_TS_IM 'b0011
`define OPC_LOAD 'b1000
`define OPC_STORE 'b1001
`define OPC_JUMP 'b0100
`define OPC_JR 'b0101
`define OPC_JAL 'b0110
`define OPC_JALR 'b0111
`define OPC_BEQZ 'b1010
`define OPC_BNEZ 'b1011
`define OPC_LA 'b1100

/* Not actually part of the spec, but useful! */
`define OPC_NOOP 'b1111

/* Math has signed and unsigned variants with low bit. 1 indicates unsigned */
`define FUNC_ADD 'b000?
`define FUNC_SUB 'b001?
`define FUNC_MUL 'b010?
`define FUNC_DIV 'b011?
`define FUNC_REM 'b100?

`define FUNC_SLL 'b1010
`define FUNC_AND 'b1011
`define FUNC_SRL 'b1100
`define FUNC_OR 'b1101
`define FUNC_SRA 'b1110
`define FUNC_XOR 'b1111

/* Upper 3 bits of func, low bit indicates unsigned */
`define FUNC_SET_LT 'b000
`define FUNC_SET_GT 'b001
`define FUNC_SET_LTE 'b010
`define FUNC_SET_GTE 'b011
`define FUNC_SET_EQ 'b100
`define FUNC_SET_NEQ 'b101

/* LHI piggy-backs as a function on OPC_TS_IM :( */
`define FUNC_LHI 'b1110

string set_funcs[] = '{"lt", "gt", "lte", "gte", "eq", "ne", "", ""};

`endif
