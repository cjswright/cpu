#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
verilator -y $SCRIPT_DIR/src -Wall --timing --lint-only $SCRIPT_DIR/src/*.sv
