/*
 * branch_predictor.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

module branch_predictor (
  input rst_async_i,
  input clk_i,

  /* Branch predictor lookups */
  input predict_req_active_i,
  input [19:0] predict_req_addr_i,
  output predict_response_o,
  output [19:0] predict_response_addr_o,

  /* Branch predictor updates */
  input predict_update_i,
  input [19:0] predict_update_addr_i,
  input [19:0] predict_update_dest_i
);

  typedef struct packed {
    logic [19:0] tag;
    logic [19:0] destination;
    logic valid;
  } predict_entry_t;

  predict_entry_t predict_table[16];

  wire [3:0] r_idx = predict_req_addr_i[3:0];
  wire predict_entry_t r_entry = predict_table[r_idx];

  wire r_ok = r_entry.valid && r_entry.tag == predict_req_addr_i;

  logic predict_response_q;
  logic [19:0] predict_response_addr_q;

  assign predict_response_o = predict_response_q;
  assign predict_response_addr_o = predict_response_addr_q;

  always_ff @(posedge clk_i or posedge rst_async_i) begin
    if (rst_async_i) begin
      predict_response_q <= 0;
      predict_response_addr_q <= 20'h0;
    end else if (predict_req_active_i) begin
      predict_response_q <= r_ok;
      predict_response_addr_q <= r_entry.destination;
    end

    $display("PREDICT active=%d addr=%d found=%d dest=%d", predict_req_active_i,
             predict_req_addr_i, r_ok, r_entry.destination);
  end

  wire [3:0] w_idx = predict_update_addr_i[3:0];
  predict_entry_t w_entry;
  assign w_entry = '{
      valid: 1'b1,
      tag: predict_update_addr_i,
      destination: predict_update_dest_i
    };

  always_ff @(posedge clk_i or posedge rst_async_i) begin
    if (rst_async_i)
      for (int i = 0; i < $size(predict_table); i++) predict_table[i] <= '{default: '0};
    else if (predict_update_i) predict_table[w_idx] <= w_entry;
  end

endmodule
