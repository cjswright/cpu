cmake_minimum_required(VERSION 3.28)

project(cpu)
find_package(verilator)

add_executable(verilate)

list(APPEND rtl_sources
  src/alu.sv
  src/decoder.sv
  src/i_fetch.sv
  src/mem_access.sv
  src/register_bank.sv
  src/testbench.sv
  src/types.sv
  src/wramp.sv
  src/writeback.sv)

verilate(verilate
  VERILATOR_ARGS -Wall --sv --timing --main -Wno-lint --assert
  INCLUDE_DIRS "./src"
  SOURCES ${rtl_sources}
  TOP_MODULE testbench
  PREFIX wramp
  TRACE)
