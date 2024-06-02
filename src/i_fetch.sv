/*
 * i_fetch.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

`include "types.sv"

module i_fetch(input             rst_async, clk,

               output reg [31:0] instruction,

               input             fetch_en,
               output [19:0]     mem_address,
               input [31:0]      mem_read_value,

               input             load_en,
               input             load_offset,
               input [19:0]      load_address);
   
   reg [19:0]                    counter;
   
   assign mem_address = counter;
   
   reg [4:0]                     nop_counter;

   logic                         stall;


   assign stall = !(instruction[31:28] inside
                    {`OPC_ARITH, `OPC_AR_IM, `OPC_TEST, `OPC_TS_IM,
                     `OPC_LOAD, `OPC_STORE, `OPC_NOOP})
     | nop_counter > 0;

   always_ff @(posedge clk or posedge rst_async) begin
      if (rst_async) begin
         instruction <= 'hf000_0000;
         counter <= 0;
         nop_counter <= 0;
      end else begin
         if (load_en)
           if (load_offset) begin
              counter <= counter + load_address;
           end else begin
              counter <= load_address;
           end
         
         if (fetch_en) begin
            if (stall) begin
               if (nop_counter == 4) begin
                  instruction <= mem_read_value;
                  if (!load_en)
                    counter <= counter + 1;
                  nop_counter <= 0;
               end else begin
                  instruction <= 'hf000_0000;
                  if (!load_en)
                    counter <= counter;
                  nop_counter <= nop_counter + 1;
               end
            end else begin
               counter <= counter + 1;
               instruction <= mem_read_value;
            end
         end else begin
            instruction <= 'hf000_0000;
            if (!load_en)
              counter <= counter;
         end
      end
      $display("I_FETCH(%d) counter=%d fetch_en=%d load_en=%d stall=%d nop=%d",
               rst_async, counter, fetch_en, load_en, stall, nop_counter);
   end
   
endmodule
