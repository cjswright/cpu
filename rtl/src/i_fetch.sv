/*
 * i_fetch.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

`include "types.sv"

module i_fetch (
  input rst_async,
  clk,

  input stalled,

  output wire        out_fetch_en,
  output reg  [31:0] out_instruction,
  output      [19:0] out_address,
  output             valid,

  output wire [19:0] req_mem_address,

  input        fetch_valid,
  input [19:0] fetch_address,
  input [31:0] fetch_value
);

  reg   [19:0] counter;
  logic [19:0] next_counter;

  reg          held;
  always_ff @(posedge clk or posedge rst_async)
    if (rst_async) held <= 0;
    else held <= valid && stalled;

  assign valid = held || fetch_valid;
  assign out_instruction = fetch_value;

  assign next_counter = rst_async ? 0 : stalled ? counter : counter + 1;

  assign req_mem_address = counter;
  assign out_fetch_en = !stalled;

  assign out_address = fetch_address;

  always_ff @(posedge clk or posedge rst_async) begin
    if (rst_async) counter <= 0;
    else counter <= next_counter;

    $display("I_FETCH(%d) n_c=%d c=%d VSHF=%d%d%d%d", rst_async, next_counter, counter, valid,
             stalled, held, fetch_valid);
  end

endmodule
