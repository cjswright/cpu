/*
 * testlib.sv
 *
 * Copyright 2026 Christian Wright <cjswright00@gmail.com>
 */

`ifndef TESTLIB_SV
`define TESTLIB_SV

package testlib;

   /* Value of a single hex digit, or -1 if c is not one. */
   function automatic int hex_nibble(byte c);
      if (c >= "0" && c <= "9") return int'(c) - int'("0");
      if (c >= "a" && c <= "f") return (int'(c) - int'("a")) + 10;
      if (c >= "A" && c <= "F") return (int'(c) - int'("A")) + 10;
      return -1;
   endfunction

   function automatic bit is_space(byte c);
      return (c == " " || c == "\t" || c == "\n" || c == "\r");
   endfunction

   /* Reads n hex digits from s starting at pos, advancing pos past them.
    * Returns -1 if fewer than n hex digits are available. */
   function automatic longint hex_field(string s, ref int pos, input int n);
      longint v;
      int     d;

      v = 0;
      for (int i = 0; i < n; i++) begin
         if (pos >= s.len()) return -1;
         d = hex_nibble(s.getc(pos));
         if (d < 0) return -1;
         v = (v << 4) | longint'(d);
         pos++;
      end
      return v;
   endfunction

   /* Next whitespace delimited token in s starting at pos, advancing pos
    * past it. Returns "" at the end of the string. */
   function automatic string next_token(string s, ref int pos);
      int start;

      while (pos < s.len() && is_space(s.getc(pos))) pos++;
      start = pos;
      while (pos < s.len() && !is_space(s.getc(pos))) pos++;
      if (pos == start) return "";
      return s.substr(start, pos - 1);
   endfunction

   /* Parses a decimal token, or a hex one when prefixed with 0x. Returns -1
    * if the token is not a number. */
   function automatic longint parse_num(string t);
      longint v;
      int     d;
      int     i;

      v = 0;
      i = 0;
      if (t.len() == 0) return -1;

      if (t.len() > 2 && t.getc(0) == "0" && (t.getc(1) == "x" || t.getc(1) == "X")) begin
         for (i = 2; i < t.len(); i++) begin
            d = hex_nibble(t.getc(i));
            if (d < 0) return -1;
            v = (v << 4) | longint'(d);
         end
         return v;
      end

      for (i = 0; i < t.len(); i++) begin
         d = hex_nibble(t.getc(i));
         if (d < 0 || d > 9) return -1;
         v = (v * 10) + longint'(d);
      end
      return v;
   endfunction

endpackage

`endif
