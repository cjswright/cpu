#!/bin/bash

set -e

cmake --build build

./lint.sh

if [ -z $1 ]; then
    ctest --test-dir build --output-on-failure
else
    ctest --test-dir build -V -R $1
fi
