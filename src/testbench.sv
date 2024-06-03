/*
 * testbench.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 *
 * Based heavily from testbench of COMP paper from Dean Armstrong.
 */

module testbench;

   reg clk;
   reg rst_async;

   wire [19:0]  mem_address;
   wire         mem_write_en;
   wire [31:0]  mem_read_value;
   wire [31:0]  mem_write_value;

   var [3:0]    debug_reg_index;
   wire [31:0]  debug_reg;

   parameter                SIZE = 65536;

   reg [31:0]               mem[0 : SIZE-1];

   assign mem_read_value = mem[mem_address[15:0]];
   reg [31:0]               clk_counter;


   initial begin
      clk = 0;
      forever #5 begin
         clk = ~clk;

         if (clk == 0)
           $display("---");
      end
   end // initial begin

   always_ff @(posedge clk or posedge rst_async) begin
      if (rst_async)
        clk_counter <= 0;
      else
        clk_counter <= clk_counter + 1;
   end

   final
     $display("CLKS %d", clk_counter);

   wramp _wramp(.clk(clk),
                .rst_async(rst_async),
                .mem_address(mem_address),
                .mem_read_value(mem_read_value),
                .mem_write_en(mem_write_en),
                .mem_write_value(mem_write_value),
                .debug_reg_index(debug_reg_index),
                .debug_reg(debug_reg));

   always_ff @(posedge clk) begin
      if (mem_write_en) begin
         mem[mem_address[15:0]] <= mem_write_value;
         $display("mem[%x] = %x", mem_address, mem_write_value);

         if (mem_address == 20'hfffff && mem_write_value == 32'hdead) begin
            $display("Program completed successfully");
            assert(mem[16'hff] == 32'h12345678);
            $finish;
            $dumpflush;

         end
      end
   end

   initial begin

      $dumpfile("waveform.vcd");
      $dumpvars(0, _wramp);

      /* Test ALU result chaining */
      mem[0]  = 32'h11000001; // addi $1, $0, 1
      mem[1]  = 32'h12000002; // addi $2, $0, 2
      mem[2]  = 32'h13000003; // addi $3, $0, 3

      /* +1 RT */
      mem[3]  = 32'h04100003; // add $4, $1, $3 = 4
      /* +2 RT */
      mem[4]  = 32'h05200003; // add $5, $2, $3 = 5
      /* +1 RS */
      mem[5]  = 32'h06500001; // add $6, $5, $1 = 6
      /* +2 RS */
      mem[6]  = 32'h07500002; // add $7, $5, $2 = 7
      /* +1 RS +2 RT */
      mem[7]  = 32'h08700006; // add $8, $7, $6 = 13
      /* +1 RT +2 RS */
      mem[8]  = 32'h09700008; // add $9, $7, $8 = 20


      mem[9]  = 32'hf0000000;
      mem[10]  = 32'hf0000000;
      mem[11]  = 32'hf0000000;
      mem[12]  = 32'hf0000000;
      mem[13]  = 32'hf0000000;
      mem[14]  = 32'hf0000000;
      rst_async = 1;
      @(posedge clk);
      @(posedge clk);
      rst_async = 0;
      #120;

      $display("Checking ALU chaining hazards");

      debug_reg_index = 1;
      #1;
      assert(debug_reg == 1);
      debug_reg_index = 2;
      #1;
      assert(debug_reg == 2);
      debug_reg_index = 3;
      #1;
      assert(debug_reg == 3);
      debug_reg_index = 4;
      #1;
      assert(debug_reg == 4);
      debug_reg_index = 5;
      #1;
      assert(debug_reg == 5);
      debug_reg_index = 6;
      #1;
      assert(debug_reg == 6);
      debug_reg_index = 7;
      #1;
      assert(debug_reg == 7);
      debug_reg_index = 8;
      #1;
      assert(debug_reg == 13);
      debug_reg_index = 9;
      #1;
      assert(debug_reg == 20);

      $display("ALU chaining hazard OK");

      /* Test hazard: 1) load 2) use */
      mem[0]  = 32'h83000009; // lw $3, 9($0)
      mem[1]  = 32'h02200003; // add $2, $0, $3

      mem[2]  = 32'hf0000000;
      mem[3]  = 32'hf0000000;
      mem[4]  = 32'hf0000000;
      mem[5]  = 32'hf0000000;
      mem[6]  = 32'hf0000000;
      mem[7]  = 32'hf0000000;
      mem[8]  = 32'hf0000000;
      mem[9]  = 32'h00000001;
      rst_async = 1;
      @(posedge clk);
      @(posedge clk);
      rst_async = 0;
      #70;

      $display("Checking load hazard #1");

      debug_reg_index = 2;
      #1;
      assert(debug_reg == 1);

      $display("Load hazard #1 OK");

      /* Test hazard: 1) load 2) noop, 3) use */
      mem[0]  = 32'h83000009; // lw $3, 9($0)
      mem[1]  = 32'hf0000000; // noop
      mem[2]  = 32'h02200003; // add $2, $0, $3

      mem[3]  = 32'hf0000000;
      mem[4]  = 32'hf0000000;
      mem[5]  = 32'hf0000000;
      mem[6]  = 32'hf0000000;
      mem[7]  = 32'hf0000000;
      mem[8]  = 32'hf0000000;
      mem[9]  = 32'h00000001;
      rst_async = 1;
      @(posedge clk);
      @(posedge clk);
      rst_async = 0;
      #70;

      $display("Checking load hazard #2");

      debug_reg_index = 2;
      #1;
      assert(debug_reg == 1);

      $display("Load hazard #2 OK");
      $display("Load hazard #2 OK");
      $display("Load hazard #2 OK");
      $display("Load hazard #2 OK");
      $display("Load hazard #2 OK");
      $display("Load hazard #2 OK");
      $display("Load hazard #2 OK");
      $display("Load hazard #2 OK");
      $display("Load hazard #2 OK");
      $display("Load hazard #2 OK");

      /* Test program taken from uni assignment */
      mem[0]  = 32'h1100000c; // addi $1, $0, 10
      mem[1]  = 32'h020b0000; // and $2, $0, $0

      // Loop over our input data
      mem[2]  = 32'h83100000; // lw $3, 0($1)
      mem[3]  = 32'h02200003; // add $2, $2, $3
      mem[4]  = 32'h11100001; // addi $1, $1, 1
      mem[5]  = 32'h14120014; // subi $4, $1, 20
      mem[6]  = 32'hb04ffffb; // bnez $4, -5

      // Store our result to address 0x000ff
      mem[7]  = 32'h920000ff; // sw $2, 0xff($0)

      // Write 0xdead to address 0xfffff - the magic handshake with
      // the testbench (implemented above in the memory write stuff)
      // that will end the simulation.
      mem[8]  = 32'h1f0ddead; // ori $15, $0, 0xdead
      mem[9]  = 32'h9f0fffff; // sw $15, 0xfffff($0)

      mem[10] = 32'h4000000a; // j 0x10

      //
      // Provide some input data which our program above will operate on
      //
      mem[12] = 32'h10000000;
      mem[13] = 32'h02000000;
      mem[14] = 32'h00300000;
      mem[15] = 32'h00040000;
      mem[16] = 32'h00005000;
      mem[17] = 32'h00000600;
      mem[18] = 32'h00000070;
      mem[19] = 32'h00000008;

      rst_async = 1;
      @(posedge clk);
      @(posedge clk);
      rst_async = 0;

      #1000;
      $display("Timed out");
      $finish;
   end

endmodule
