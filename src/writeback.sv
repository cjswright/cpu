`include "types.sv"

module writeback(
  input rst_async, clk,
  input types::InstructionDetails details,
  input [31:0] data,
  
  output write_en,
  output [31:0] write,
  output [3:0] write_index,
  
  output write_pc_en,
  output pc_offset,
  output [19:0] pc
);
  
  /* All of the outputs of this module are fed into the register bank
   * which itself will enact the write on the next positive clock edge,
   * so this is all combinational.
   *
   * The FF block is basically just to document what's going on, but the
   * state changes are actually happening in the register bank.
   * 
   * It's kinda weird, but it works!
   */
  
  logic disabled, op_req_writeback;
  
  assign disabled = (rst_async || !details.is_valid);
  assign op_req_writeback = details.op != `OPC_STORE;
  let write_pc = details.op inside {`OPC_JUMP, `OPC_JR, `OPC_JAL, `OPC_JALR, `OPC_BEQZ, `OPC_BNEZ};
  let is_conditional = details.op inside {`OPC_BEQZ, `OPC_BNEZ};

  assign write_index = details.rd;
  assign write_en = !disabled && op_req_writeback && !write_pc;
  assign write = data;
  
  assign write_pc_en = !disabled && op_req_writeback && write_pc && (!is_conditional || data[0]);
  assign pc = is_conditional ? details.offs : data[19:0];
  assign pc_offset = is_conditional;
  
  always_ff @(posedge clk or posedge rst_async) begin
    $display("WRITEBK(%d) v=%d data=%d op=%d rd=%d offs=%d",
             rst_async, details.is_valid, data, details.op, details.rd, details.offs);
  end
  
endmodule
