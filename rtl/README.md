# Pipelined CPU for Wramp

This implements a pipelined CPU for the Wramp architecture.

Very WIP!

# Building

Use CMake to build in the usual way:

```
cmake -B build -GNinja --build
```

... alternatively use the bootstrap.sh to setup, and then run the run.sh
script which will run the linter and the tests:

```
# First boostrap it...
./bootstrap.sh

# Run as many times as you like
./run.sh
```

# Tests

Each program in `tests/` is one test. Put the assembly in `tests/<name>.s`
and the checks in `tests/<name>.expect`. The build assembles every `.s`
into a `.srec`, and `ctest` runs one simulation per `.srec`:

```
ctest --test-dir build --output-on-failure
ctest --test-dir build -R sum --output-on-failure
```

Run a single program by hand:

```
./build/verilate +srec=tests/sum.srec
```

Plusargs:

- `+srec=<file>` program to load, required
- `+expect=<file>` checks to apply, default `<program>.expect`
- `+timeout=<clocks>` give up after this many clocks, default 2000
- `+vcd=<file>` write a waveform

`ctest` writes each test's waveform to `build/traces/<name>.vcd`.

## Writing a program

The CPU resets to PC 0, so link the text segment at 0, which is the wlink
default. A program ends by writing `0xdead` to address `0xfffff`; writing
any other value there fails the test immediately, which lets a program
report its own failure. A program that never writes that address fails on
the timeout.

```
    .text

    .global main

main:
    addi $1, $0, 1

    ori $15, $0, 0xdead
    sw $15, 0xfffff($0)
done:
    j done
```

## Writing an expect file

One check per line. `mem` takes a word address, `reg` a register number,
and both are checked once the program signals completion. `timeout` sets
the clock budget. Values are decimal, or hex with a `0x` prefix. `#`
starts a comment.

```
timeout 500
mem 0xff 0x12345678
reg 2 0x12345678
```

A program with no expect file only has to complete.

## Assembling

Assembly needs `wasm` and `wlink` from the WRAMP toolchain. CMake looks
for them next to the repository; point it elsewhere with:

```
cmake -B build -GNinja -DWRAMP_TOOLCHAIN=/path/to/toolchain
```

Without them the checked in `.srec` files are used as they are. To
assemble without CMake:

```
./build_tests.py --wasm /path/to/wasm --wlink /path/to/wlink
```

A new program is picked up by the next build; you do not need to re-run
CMake.
