#!/bin/bash

set -e

cmake -Bbuild -S. -GNinja
cmake --build build

./lint.sh
./build/verilate
