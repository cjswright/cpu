cmake_minimum_required(VERSION 3.28)

project(cpu)
find_package(verilator)
enable_testing()

add_executable(verilate)

list(APPEND rtl_sources
  src/alu.sv
  src/decoder.sv
  src/i_fetch.sv
  src/mem_access.sv
  src/register_bank.sv
  src/testbench.sv
  src/testlib.sv
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

# Assemble tests/*.s into tests/*.srec. Needs the WRAMP toolchain; without it
# the checked in .srec files are used as they are.
set(WRAMP_TOOLCHAIN "${CMAKE_CURRENT_SOURCE_DIR}/../../wramp/toolchain"
    CACHE PATH "Directory holding the wasm and wlink binaries")
find_program(WASM wasm HINTS ${WRAMP_TOOLCHAIN})
find_program(WLINK wlink HINTS ${WRAMP_TOOLCHAIN})
find_package(Python3 COMPONENTS Interpreter QUIET)

if(WASM AND WLINK AND Python3_Interpreter_FOUND)
  add_custom_target(assemble-tests
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/build_tests.py
            --wasm ${WASM} --wlink ${WLINK} --tests ${CMAKE_CURRENT_SOURCE_DIR}/tests
    COMMENT "Assembling tests")
  add_dependencies(verilate assemble-tests)
else()
  message(STATUS "wasm/wlink not found, tests/*.s will not be assembled")
endif()

# One test per program. Traces and any memory dumps land in build/traces.
set(trace_dir ${CMAKE_CURRENT_BINARY_DIR}/traces)
file(MAKE_DIRECTORY ${trace_dir})

# Globbing the sources as well as the .srec files means a newly added program
# is picked up on the build that assembles it.
file(GLOB test_programs CONFIGURE_DEPENDS
     "${CMAKE_CURRENT_SOURCE_DIR}/tests/*.s"
     "${CMAKE_CURRENT_SOURCE_DIR}/tests/*.srec")

set(test_names "")
foreach(program IN LISTS test_programs)
  get_filename_component(name ${program} NAME_WE)
  list(APPEND test_names ${name})
endforeach()
list(REMOVE_DUPLICATES test_names)

foreach(name IN LISTS test_names)
  set(srec ${CMAKE_CURRENT_SOURCE_DIR}/tests/${name}.srec)
  add_test(NAME ${name}
           COMMAND $<TARGET_FILE:verilate> +srec=${srec} +vcd=${name}.vcd)
  set_tests_properties(${name} PROPERTIES
    WORKING_DIRECTORY ${trace_dir}
    TIMEOUT 120
    FAIL_REGULAR_EXPRESSION "RESULT FAIL")
endforeach()
