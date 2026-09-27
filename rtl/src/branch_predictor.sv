/*
 * branch_predictor.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 */

module branch_predictor (
  input rst_async_i,
  input clk_i,

  input predict_req_active_i,
  input [19:0] predict_req_addr_i,

  output predict_response_o,
  output [19:0] predict_response_addr_o
);

  // temp: test code; only works on sum.s
  logic [19:0] predicted_dest;
  logic        predicted;
  logic        run_test_code = 1;
  // sum.s has a conditional branch at PC=6 -> 2 which runs most times
  assign predicted = predict_req_active_i && run_test_code && predict_req_addr_i == 6;
  assign predicted_dest = 20'd2;
  // done

  logic predict_response_q;
  logic [19:0] predict_response_addr_q;

  assign predict_response_o = predict_response_q;
  assign predict_response_addr_o = predict_response_addr_q;

  always_ff @(posedge clk_i or posedge rst_async_i) begin

    predict_response_q <= predicted;
    predict_response_addr_q <= predicted_dest;

    $display("PREDICT active=%d res=%d found=%d dest=%d", predict_req_active_i, predict_req_addr_i,
             predict_response_o, predict_response_addr_o);
  end

endmodule
