`ifndef TYPES_SV
`define TYPES_SV

package types;
  typedef enum { TYPE_R, TYPE_I, TYPE_J } Type;
  typedef enum { REG_NORMAL, REG_RS, REG_RT } RegHazard;

  typedef struct {
    logic [3:0] op;
    logic [3:0] rd;
    logic [3:0] rs;
    logic [3:0] func;
    logic [15:0] imm;
    logic [19:0] offs;
    logic [3:0] rt;
    
    /* Used to make bad instructions have no effect. Should probably fault. */
    logic is_valid;

    /* Rest of this is for hazard avoidance */
    
    /* Used to send the output of this instruction to the rs or rt parameter
     * of the next instruction in the ALU */
    RegHazard reg_hazard;
  } InstructionDetails;
endpackage


`define OPC_ARITH 'b0000
`define OPC_AR_IM 'b0001
`define OPC_TEST  'b0010
`define OPC_TS_IM 'b0011
`define OPC_LOAD  'b1000
`define OPC_STORE 'b1001
`define OPC_JUMP  'b0100
`define OPC_JR    'b0101
`define OPC_JAL   'b0110
`define OPC_JALR  'b0111
`define OPC_BEQZ  'b1010
`define OPC_BNEZ  'b1011

/* Not actually part of the spec, but useful! */
`define OPC_NOOP  'b1111

/* Math has signed and unsigned variants with low bit. 1 indicates unsigned */
`define FUNC_ADD 'b000?
`define FUNC_SUB 'b001?
`define FUNC_MUL 'b010?
`define FUNC_DIV 'b011?
`define FUNC_REM 'b100?

`define FUNC_SLL 'b1010
`define FUNC_AND 'b1011
`define FUNC_SRL 'b1100
`define FUNC_OR  'b1101
`define FUNC_SRA 'b1110
`define FUNC_XOR 'b1111


`endif
