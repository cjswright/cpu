/*
 * testbench.sv
 *
 * Copyright 2024 Christian Wright <cjswright00@gmail.com>
 *
 * Based heavily from testbench of COMP paper from Dean Armstrong.
 */

`include "testlib.sv"

module testbench;

   import testlib::*;

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

   /* Address the program writes to to hand control back to the testbench,
    * and the value that means it succeeded. */
   localparam [19:0] DoneAddress = 20'hfffff;
   localparam [31:0] DoneValue = 32'hdead;

   localparam int MaxChecks = 256;

   string     srec_path;
   string     expect_path;
   string     vcd_path;
   int        timeout_clks = 2000;

   int        num_checks = 0;
   bit        check_is_reg[MaxChecks];
   int        check_index[MaxChecks];
   bit [31:0] check_value[MaxChecks];

   int        errors = 0;
   bit        done;
   bit        aborted;
   bit        timed_out;

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
      else begin
         clk_counter <= clk_counter + 1;
         if (clk_counter >= timeout_clks)
           timed_out <= 1;
      end
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
         $display("mem[%05x] = %08x", mem_address, mem_write_value);

         if (mem_address == DoneAddress) begin
            if (mem_write_value == DoneValue)
              done <= 1;
            else begin
               $display("FAIL program reported failure %08x", mem_write_value);
               aborted <= 1;
            end
         end
      end
   end

   /* Default expect file path for a program: foo.srec -> foo.expect */
   function automatic string expect_path_for(string srec);
      int n;

      n = srec.len();
      if (n > 5 && srec.substr(n - 5, n - 1) == ".srec")
        return {srec.substr(0, n - 6), ".expect"};
      return {srec, ".expect"};
   endfunction

   /* Loads a Motorola S-record file into mem. Addresses are word addresses,
    * as emitted by wlink. Aborts the simulation on a malformed file. */
   task automatic load_srec(string path);
      int       fd;
      string    line;
      int       pos;
      int       lineno;
      longint   rectype;
      longint   count;
      longint   addr;
      longint   b;
      int       addr_bytes;
      int       data_bytes;
      int       nwords;
      bit [15:0] word_addr;
      bit [7:0] sum;
      bit [7:0] bval;
      bit [31:0] word;

      fd = $fopen(path, "r");
      if (fd == 0)
        $fatal(1, "cannot open program %s", path);

      lineno = 0;
      while ($fgets(line, fd) != 0) begin
         lineno++;
         pos = 0;

         while (pos < line.len() && is_space(line.getc(pos))) pos++;
         if (pos >= line.len()) continue;

         if (line.getc(pos) != "S")
           $fatal(1, "%s:%0d: not an S-record", path, lineno);
         pos++;

         rectype = hex_field(line, pos, 1);
         count = hex_field(line, pos, 2);
         if (rectype < 0 || count < 0)
           $fatal(1, "%s:%0d: truncated record header", path, lineno);

         case (rectype)
           0, 1, 5, 6, 9: addr_bytes = 2;
           2, 8:          addr_bytes = 3;
           3, 7:          addr_bytes = 4;
           default:       $fatal(1, "%s:%0d: unknown record type S%0d", path, lineno, rectype);
         endcase

         data_bytes = int'(count) - addr_bytes - 1;
         if (data_bytes < 0)
           $fatal(1, "%s:%0d: byte count %0d too small for S%0d", path, lineno, count, rectype);

         sum = count[7:0];
         addr = 0;
         for (int i = 0; i < addr_bytes; i++) begin
            b = hex_field(line, pos, 2);
            if (b < 0)
              $fatal(1, "%s:%0d: truncated address", path, lineno);
            addr = (addr << 8) | b;
            sum += 8'(b);
         end

         if (rectype == 1 || rectype == 2 || rectype == 3) begin
            if (data_bytes % 4 != 0)
              $fatal(1, "%s:%0d: %0d data bytes is not a whole number of words",
                     path, lineno, data_bytes);

            nwords = data_bytes / 4;
            if ((addr + longint'(nwords)) > SIZE)
              $fatal(1, "%s:%0d: address %0h is beyond the %0d word memory",
                     path, lineno, addr, SIZE);

            for (int w = 0; w < nwords; w++) begin
               word = 0;
               for (int i = 0; i < 4; i++) begin
                  b = hex_field(line, pos, 2);
                  if (b < 0)
                    $fatal(1, "%s:%0d: truncated data", path, lineno);
                  bval = 8'(b);
                  word = (word << 8) | 32'(bval);
                  sum += bval;
               end

               word_addr = 16'(addr + longint'(w));
               mem[word_addr] = word;
            end
         end else begin
            for (int i = 0; i < data_bytes; i++) begin
               b = hex_field(line, pos, 2);
               if (b < 0)
                 $fatal(1, "%s:%0d: truncated data", path, lineno);
               sum += 8'(b);
            end
         end

         b = hex_field(line, pos, 2);
         if (b < 0)
           $fatal(1, "%s:%0d: missing checksum", path, lineno);
         sum += 8'(b);
         if (sum != 8'hff)
           $fatal(1, "%s:%0d: bad checksum", path, lineno);

         if (rectype == 7 || rectype == 8 || rectype == 9)
           if (addr != 0)
             $fatal(1, "%s:%0d: entry point %0h is not 0, but the CPU resets to PC 0",
                    path, lineno, addr);
      end

      $fclose(fd);
   endtask

   /* Loads the checks to apply once the program completes. Missing expect
    * files are not an error: completion alone is then the whole test. */
   task automatic load_expect(string path);
      int     fd;
      string  line;
      string  tok;
      int     pos;
      int     lineno;
      longint index;
      longint value;

      fd = $fopen(path, "r");
      if (fd == 0) begin
         $display("NOTE no %s, checking only that the program completes", path);
         return;
      end

      lineno = 0;
      while ($fgets(line, fd) != 0) begin
         lineno++;
         pos = 0;
         tok = next_token(line, pos);

         if (tok == "" || tok.getc(0) == "#")
           continue;

         if (tok == "timeout") begin
            value = parse_num(next_token(line, pos));
            if (value <= 0)
              $fatal(1, "%s:%0d: timeout needs a positive clock count", path, lineno);
            timeout_clks = int'(value);
         end else if (tok == "mem" || tok == "reg") begin
            index = parse_num(next_token(line, pos));
            value = parse_num(next_token(line, pos));
            if (index < 0 || value < 0)
              $fatal(1, "%s:%0d: %s needs an index and a value", path, lineno, tok);
            if (num_checks == MaxChecks)
              $fatal(1, "%s: more than %0d checks", path, MaxChecks);

            check_is_reg[num_checks] = (tok == "reg");
            check_index[num_checks] = int'(index);
            check_value[num_checks] = value[31:0];
            num_checks++;
         end else
           $fatal(1, "%s:%0d: unknown directive %s", path, lineno, tok);

         if (pos < line.len()) begin
            tok = next_token(line, pos);
            if (tok != "" && tok.getc(0) != "#")
              $fatal(1, "%s:%0d: unexpected %s", path, lineno, tok);
         end
      end

      $fclose(fd);
   endtask

   task automatic run_checks();
      bit [31:0] got;

      for (int i = 0; i < num_checks; i++) begin
         if (check_is_reg[i]) begin
            debug_reg_index = check_index[i][3:0];
            #1;
            got = debug_reg;
         end else
           got = mem[check_index[i][15:0]];

         if (got !== check_value[i]) begin
            $display("FAIL %s %0d = %08x, expected %08x",
                     check_is_reg[i] ? "reg" : "mem",
                     check_index[i], got, check_value[i]);
            errors++;
         end else
           $display("OK %s %0d = %08x",
                    check_is_reg[i] ? "reg" : "mem", check_index[i], got);
      end
   endtask

   initial begin
      int t;

      if (!$value$plusargs("srec=%s", srec_path))
        $fatal(1, "usage: verilate +srec=<file> [+expect=<file>] [+timeout=<clks>] [+vcd=<file>]");

      if (!$value$plusargs("expect=%s", expect_path))
        expect_path = expect_path_for(srec_path);

      if ($value$plusargs("vcd=%s", vcd_path)) begin
         $dumpfile(vcd_path);
         $dumpvars(0, _wramp);
      end

      for (int i = 0; i < SIZE; i++)
        mem[i] = 0;

      load_srec(srec_path);
      load_expect(expect_path);

      if ($value$plusargs("timeout=%d", t))
        timeout_clks = t;

      $display("RUN %s", srec_path);

      debug_reg_index = 0;
      rst_async = 1;
      @(posedge clk);
      @(posedge clk);
      rst_async = 0;

      wait (done || aborted || timed_out);
      #1;

      if (timed_out) begin
         $display("FAIL timed out after %0d clocks", timeout_clks);
         errors++;
      end else if (aborted)
        errors++;
      else
        run_checks();

      $dumpflush;

      if (errors != 0) begin
         $display("RESULT FAIL %s (%0d error[s])", srec_path, errors);
         $fatal(1, "test failed");
      end

      $display("RESULT PASS %s", srec_path);
      $finish;
   end

endmodule
