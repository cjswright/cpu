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

   parameter                SIZE = 65536;

   reg [31:0]               mem[0 : SIZE-1];

   assign mem_read_value = mem[mem_address[15:0]];
   reg [31:0]               clk_counter;


   initial begin
      clk = 0;
      clk_counter = 0;
      forever #5 begin
         clk = ~clk;
         clk_counter ++;

         if (clk == 0)
           $display("---");
      end
   end // initial begin

   final
     $display("CLKS %d", clk_counter);

   wramp _wramp(.clk(clk),
                .rst_async(rst_async),
                .mem_address(mem_address),
                .mem_read_value(mem_read_value),
                .mem_write_en(mem_write_en),
                .mem_write_value(mem_write_value));

   always_ff @(posedge clk) begin
      if (mem_write_en) begin
         mem[mem_address[15:0]] <= mem_write_value;
         $display("mem[%x] = %x", mem_address, mem_write_value);

         if (mem_address == 20'hfffff && mem_write_value == 32'hdead) begin
            $display("Program completed successfully");
            $finish;
            $dumpflush;
         end
      end
   end

   initial begin

      $dumpfile("waveform.vcd");
      $dumpvars(0, _wramp);


      /* Test program taken from uni assignment */
      mem[0]  = 32'h1100000a; // addi $1, $0, 10
      mem[1]  = 32'h020b0000; // and $2, $0, $0

      // Loop over our input data
      mem[2]  = 32'h83100000; // lw $3, 0($1)
      mem[3]  = 32'h02200003; // add $2, $2, $3
      mem[4]  = 32'h11100001; // addi $1, $1, 1
      mem[5]  = 32'h14120012; // subi $4, $1, 18
      mem[6]  = 32'hb04ffffb; // bnez $4, -5

      // Store our result to address 0x000ff
      mem[7]  = 32'h920000ff; // sw $2, 0xff($0)

      // Write 0xdead to address 0xfffff - the magic handshake with
      // the testbench (implemented above in the memory write stuff)
      // that will end the simulation.
      mem[8]  = 32'h1f0ddead; // ori $15, $0, 0xdead
      mem[9]  = 32'h9f0fffff; // sw $15, 0xfffff($0)

      //
      // Provide some input data which our program above will operate on
      //
      mem[10] = 32'h10000000;
      mem[11] = 32'h02000000;
      mem[12] = 32'h00300000;
      mem[13] = 32'h00040000;
      mem[14] = 32'h00005000;
      mem[15] = 32'h00000600;
      mem[16] = 32'h00000070;
      mem[17] = 32'h00000008;

      rst_async = 1;
      @(posedge clk);
      @(posedge clk);
      rst_async = 0;

      #10000;
      $display("Timed out");
      $finish;
   end

endmodule
