# Pipelined CPU for Wramp

This implements a pipelined CPU for the Wramp architecture.

Very WIP!

# Building

Use CMake to build in the usual way:

```
cmake -B build -GNinja --build
```

... alternatively use the bootstrap.sh to setup, and then run the run.sh script
which will run the linter and simulation:

```
# First boostrap it...
./bootstrap.sh

# Run as many times as you like
./run.sh
```
