# Decouple

This describes an architecture which changes the coupling within the
pipeline to be more flexible.

The goal is make the ALU thinner by pushing more functionality into the
decoder such as register and hazard management, and then splitting the
decoder up into what is purely combinational and what is control
management. The control management will then move into its own module.

The instruction details will become significantly thinner as a result,
and the mem access and writeback stages will become less coupled to the
pipeline.

## ALU

ALU will move more to a model of having two 32-bit inputs, calculating
some math and providing a 32-bit output plus flags. Decisions around
what to do such as around branching, immediate versus registers, rs/rt
hazards, and special casees for jump-and-link will be taken out of the
alu path and move to the decoder, control, and hazard manager.

## Hazard manager

The hazard manager will take charge of register lookups and ensure that:
- If the register lookup requires a memory load that hasn't happened
  yet, it will stall
- If the register lookup accesses an Rd that is in flight, it will
  provide it
- Otherwise, it will route the register bank

## Memory access

The memory access module will be reworked to behave as a queue. Memory
accesses can be requested (and stalled) and the memory access will occur
at a later time.

Once a load is completed, a load_complete is initiated which the control
will route to the write-back module. This can be stalled.

The memory access module can be asked if a particular register is being
loaded to, and it will reply combinatorially if that is so. This can be
used by other modules to stall and wait for the load to complete.

Once data is available locally, it'll be provided immediately; this
facilitates other layers solving short cutting with writeback access. In
other words, the memory access module itself is not responsible for
providing requests for register data itself; it will only provide a
stall indicator if a register is scheduled to be modified.

### Memory access stage and pass-through data

The memory access module has two jobs currently:

1. It performs memory accesses
2. For non-memory accesses, it pass data through

It's important that for non-memory accesses, they pass through the
memory access stage anyway for two reasons:

1. Write-backs must happen sequentially because we don't detect data
   dependencies so can't allow out-of-order write-back
2. We can only write-back one data per cycle anyway

The downside is it makes the memory access module mildly more
complicated, and a cycle of latency is inserted to writeback for
anything that's not a load, which will be majority of instructions.
Therefore, it would be useful to consider if there are other ways
forward.

It'd be worth thinking about whether there's a way to decouple these,
and maybe that makes more sense if the memory access module has
substantial latency added to it.
