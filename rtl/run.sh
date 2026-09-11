#!/bin/bash

set -e

cmake --build build

./lint.sh
./build/verilate
