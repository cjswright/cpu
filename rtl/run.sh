#!/bin/bash

set -e

cmake --build build

./lint.sh
ctest --test-dir build --output-on-failure
