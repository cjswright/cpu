/*
 * testbench.sv - Testbench for WRAMP microprocessor
 *
 * Copyright 2015 by Dean Armstrong <dean.armstrong@virscient.com>
 *
 * This is the SystemVerilog testbench framework for the WRAMP microprocessor
 * we'll be designing and implementing in this assignment.
 * It instantiates the DUT (which must have module name wramp)
 * and will set it executing a simple application. You should extend/modify
 * this testbench as you need to, in order to convince yourself that your
 * processor is meeting the requirements set out in the assignment.
 */
module testbench;
  reg         rst_async, clk;
  wire [19:0] mem_address;
  wire [31:0] mem_read_value, mem_write_value;
  wire        mem_write_enable;
  integer     n;
  
  
  // Instantiate the device under test
  wramp dut (
    .rst_async        (rst_async),
    .clk              (clk),
    .mem_address      (mem_address),
    .mem_read_value   (mem_read_value),
    .mem_write_enable (mem_write_enable),
    .mem_write_value  (mem_write_value)
    );

  // Generate a clock
  initial begin
    clk = 0;
    forever #5 begin
      clk = ~clk;
      if (clk == 0)
        $display("---");
    end
  end

  // Model some memory. We're not going to implement the full 20 bits of
  // address space - instead we'll do 64 Kwords here.
  parameter MEM_SIZE = 65536;
  reg [31:0] memory[0:MEM_SIZE-1];

  // Implement asynchronous read from memory
  assign mem_read_value = memory[mem_address];

  // Handle writes to memory
  always @(posedge clk) begin
    //$display("MEM %d %d %d %d", mem_address, mem_read_value, mem_write_value, mem_write_enable);
    if (mem_write_enable) begin

      // This is a secret handshake - if the processor writes
      // the value 0x0000dead to 0xfffff then we finish immediately
      if (mem_address === 20'hfffff &&
          mem_write_value === 32'hdead) begin
        $display("Processor wrote 0xdead to 0xfffff - finishing simulation");
        $finish;
        $dumpflush;
      end

      memory[mem_address] <= mem_write_value;
      $display("memory[0x%05x] <= 0x%08x", mem_address, mem_write_value);
    end
  end

  // Main test procedure
  initial begin
    // Capture signals for waveform view
    $dumpfile("dump.vcd");
    $dumpvars(0, dut);

    // Clear our memory
    for (n = 0; n < MEM_SIZE; n = n + 1)
      memory[n] = 0;

    //
    // Setup a wee program for our processor to execute
    //

    // We're going to loop over input data that we'll
    // load into memory from address 10. Initialise a
    // couple of registers - one to point at the data,
    // and one to use as an accumulator
    memory[0]  = 32'h1100000a; // addi $1, $0, 10
    memory[1]  = 32'h020b0000; // and $2, $0, $0

    // Loop over our input data
    memory[2]  = 32'h83100000; // lw $3, 0($1)
    memory[3]  = 32'h02200003; // add $2, $2, $3
    memory[4]  = 32'h11100001; // addi $1, $1, 1
    memory[5]  = 32'h14120012; // subi $4, $1, 18
    memory[6]  = 32'hb04ffffb; // bnez $4, -5

    // Store our result to address 0x000ff
    memory[7]  = 32'h920000ff; // sw $2, 0xff($0)

    // Write 0xdead to address 0xfffff - the magic handshake with
    // the testbench (implemented above in the memory write stuff)
    // that will end the simulation.
    memory[8]  = 32'h1f0ddead; // ori $15, $0, 0xdead
    memory[9]  = 32'h9f0fffff; // sw $15, 0xfffff($0)

    //
    // Provide some input data which our program above will operate on
    //
    memory[10] = 32'h10000000;
    memory[11] = 32'h02000000;
    memory[12] = 32'h00300000;
    memory[13] = 32'h00040000;
    memory[14] = 32'h00005000;
    memory[15] = 32'h00000600;
    memory[16] = 32'h00000070;
    memory[17] = 32'h00000008;

    //
    // Now get on with it: Reset the microprocessor
    //
    rst_async = 1;
    @(posedge clk);
    @(posedge clk);
    rst_async = 0;
    
    // Wait for a while so our simulation can run. If the processor
    // is somewhat working then we should finish as it writes 0xdead
    // to 0xfffff, but this is a safety net for development.
    #100000;
    $display("Simulation timed out - is your processor working correctly?");
    $finish;
    $dumpflush;
  end
endmodule
