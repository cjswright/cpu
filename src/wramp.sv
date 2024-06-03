/*
 * wramp.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

`include "types.sv"

module wramp(input clk, input rst_async,

             output var [19:0] mem_address,
             input [31:0]      mem_read_value,
             output            mem_write_en,
             output [31:0]     mem_write_value,
             input [3:0]       debug_reg_index,
             output [31:0]     debug_reg);

   wire [31:0]             instruction;

   types::InstructionDetails details;

   wire [3:0]              read_a_index;
   wire [3:0]              read_b_index;
   wire [3:0]              read_c_index;
   wire [3:0]              jump_reg_index;
   wire [3:0]              write_index;
   wire                    write_en;
   wire [31:0]             write;
   wire [31:0]             read_a;
   wire [31:0]             read_b;
   wire [31:0]             read_c;
   wire [19:0]             jump_reg;

   wire                    alu_is_set;

   register_bank _register_bank (.rst_async(rst_async),
                                 .clk(clk),
                                 .read_a_index(read_a_index),
                                 .read_b_index(read_b_index),
                                 .read_c_index(read_c_index),
                                 .jump_index(jump_reg_index),
                                 .write_index(write_index),
                                 .write_en(write_en),
                                 .write(write),
                                 .read_a(read_a),
                                 .read_b(read_b),
                                 .read_c(read_c),
                                 .jump(jump_reg),

                                 .debug_index(debug_reg_index),
                                 .debug(debug_reg));

   wire                    mem_access_active;
   wire [19:0]             fetch_address;
   wire [19:0]             mem_access_address;

   wire [31:0]             alu_out;
   wire                    decoder_fetch_skip;
   wire [31:0]             mem_access_result;

   types::InstructionDetails alu_details;
   types::InstructionDetails mem_access_details;

   var [31:0]             alu_mem;
   var [31:0]             fetcher_mem;

   always_comb begin
      if (mem_access_active) begin
         mem_address = mem_access_address;
         alu_mem = mem_read_value;
         fetcher_mem = 0;
      end else begin
         mem_address = fetch_address;
         fetcher_mem = mem_read_value;
         alu_mem = 0;
      end
   end

   /* We need to wire up the reg_jump_value based on whether or not the
    * register is modified at some point in the pipeline. We're gauranteed
    * one clock delay in this case already so just need to check ALU and
    * mem access stages.
    */
   var [19:0]              reg_jump_value;
   always_comb begin
      if (alu_details.op inside `OPS_REG_WRITEBACK &&
          alu_details.rd == jump_reg_index)
        reg_jump_value = alu_out[19:0];
      else if (mem_access_details.op inside `OPS_REG_WRITEBACK &&
               mem_access_details.rd == jump_reg_index)
        reg_jump_value = mem_access_result[19:0];
      else
        reg_jump_value = jump_reg;
   end

   i_fetch _i_fetch (.rst_async(rst_async),
                     .clk(clk),
                     .instruction(instruction),
                     .fetch_en(!mem_access_active && !decoder_fetch_skip),
                     .mem_address(fetch_address),
                     .mem_read_value(fetcher_mem),
                     .revert_pc(!alu_is_set && details.op inside { `OPC_BEQZ, `OPC_BNEZ }),
                     .jump_reg_index(jump_reg_index),
                     .jump_reg(reg_jump_value)
                     );
   decoder _decoder (.rst_async(rst_async),
                     .clk(clk),
                     .instruction (instruction),
                     .flush(!alu_is_set && details.op inside { `OPC_BEQZ, `OPC_BNEZ }),
                     .details(details),
                     .fetch_skip(decoder_fetch_skip)
                     );

   alu _alu (.rst_async(rst_async),
             .clk(clk),
             .details(details),
             .read_a_index(read_a_index),
             .read_b_index(read_b_index),
             .read_a(read_a),
             .read_b(read_b),

             .mem(alu_mem),

             .out(alu_out),
             .is_set(alu_is_set),
             .out_details(alu_details));

   mem_access _mem_access (.rst_async(rst_async),
                           .clk(clk),
                           .details(alu_details),
                           .data(alu_out),

                           .mem_read_value(mem_read_value),
                           .mem_write_value(mem_write_value),
                           .mem_address(mem_access_address),
                           .mem_access_active(mem_access_active),
                           .mem_write_enable(mem_write_en),

                           .rd(read_c),
                           .rd_index(read_c_index),

                           .out_details(mem_access_details),
                           .result(mem_access_result)
                           );

   writeback _writeback(.rst_async(rst_async),
                        .clk(clk),
                        .details(mem_access_details),
                        .data(mem_access_result),
                        .write_en(write_en),
                        .write(write),
                        .write_index(write_index));


endmodule
