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

  typedef struct packed {
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
    logic [31:0] imm;
    logic [19:0] offs;
    logic [3:0]  rt;

    /* Used to make bad instructions have no effect. Should probably fault. */
    logic is_valid;

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
`define FUNC_ADDS 4'b0000
`define FUNC_ADDZ 4'b000z
`define FUNC_SUBS 4'b0010
`define FUNC_SUBZ 4'b001z
`define FUNC_MULZ 4'b010z
`define FUNC_DIVZ 4'b011z
`define FUNC_REMZ 4'b100z

`define FUNC_SLL 4'b1010
`define FUNC_AND 4'b1011
`define FUNC_SRL 4'b1100
`define FUNC_OR 4'b1101
`define FUNC_SRA 4'b1110
`define FUNC_XOR 4'b1111

/* Upper 3 bits of func, low bit indicates unsigned */
`define FUNC_SET_LT 3'b000
`define FUNC_SET_GT 3'b001
`define FUNC_SET_LTE 3'b010
`define FUNC_SET_GTE 3'b011
`define FUNC_SET_EQ 3'b100
`define FUNC_SET_NEQ 3'b101

/* LHI piggy-backs as a function on OPC_TS_IM :( */
`define FUNC_LHI 4'b1110

string set_funcs[] = '{"lt", "gt", "lte", "gte", "eq", "ne", "", ""};

`endif
