#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
verilator -y $SCRIPT_DIR/src -Wall --timing --lint-only $SCRIPT_DIR/src/*.sv
verible-verilog-lint --rules_config_search $(ls $SCRIPT_DIR/src/*.sv | grep -v /testbench.sv$)
