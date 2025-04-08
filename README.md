vroom
=====

vroom is a simple RISC-V core written in SystemVerilog, compiled with Verilator.

- **src/** contains the RTL
- **rc/** contains TCL scripts for gtkwave

Platform and Verilator versions verified:
- WSL Ubuntu 24.04.2 LTS 
- Verilator  v5.034
- riscv64-unknown-elf-gcc 13.2.0
- Spike RISC-V ISA Simulator 1.1.1-dev

To build the model:

```
make Vtop
```

To build the test:

```
cd tests/branchy
make all
```

To run the model:

```
make run
```

To view your waveform:

```
gtkwave -S rc/top.tcl waves.fst
```

Pipeline
--------

vroom is going out-of-order!  The pipeline looks like this:

**In-Order**

* **FETCH** has a FSM to read instructions from main memory.
* **DECODE** receives instruction bytes decodes them into uops.
* **UCODE** generally just passes uops through from **DECODE**.  Uops from decode with `trap_to_ucode` set will cause the microsequencer to take over and deliver uops from the ROM until an `eom` is seen.
* **RENAME** renames register sources and dests, and sends the renamed uop to **ALLOC**.
* **ALLOC** assigns ROBIDs and allocates into the appropriate **RS**.

**Out-of-Order**

* **EXE** executes integer uops from its **RS** when its deps are available, and writes back to the **ROB**.
* **MEM** executes memory uops from its **RS** when its deps are available, and writes back to the **ROB**.  Stores complete shortly after issue, and then commit post-retirement.

**In-Order**

* **RETIRE** receives writebacks from the OoO part of the pipe and writes them back.

Branches
--------

Branches are resolved in **EXE** but not taken until **RETIRE**.  Branches are currently always predicted NT.

Micro branches (or ubranches) are normal branch uops where the uop comes from
ucrom and does not have an "eom".  These branches are resolved just like normal
branches, including a nuke... but the misprediction calculation is based on rom
address, not PC, and the FE/DE stages are untouched by the correction flow.

Nukes are a mess.  Thinking that br mispred needs to communicate a PC (always)
and a uPC (sometimes) and an indication of whether we resume from ucrom or
fetch.  Nukes reset both front-ends.  Otherwise it is hard to disentangle what
happens if we're mixing ucode and non-ucode instructions.

CSRs
----

Following are the CSRs defined in the base ISA (omitting RV32i-only CSRs).

Number  Privilege  Name     Description
------- ---------- -------- ------------------------------------------------------------
0x001   Read write fflags   Floating-Point Accrued Exceptions.
0x002   Read write frm      Floating-Point Dynamic Rounding Mode.
0x003   Read write fcsr     Floating-Point Control and Status Register (frm + fflags).
0xC00   Read-only  cycle    Cycle counter for RDCYCLE instruction.
0xC01   Read-only  time     Timer for RDTIME instruction.
0xC02   Read-only  instret  Instructions-retired counter for RDINSTRET instruction.

UCODE/FE interactions
----------------------

When ucode sees a `trap_to_ucode` instruction, its state machine becomes active
and it begins asserting `uc_trapped_uc0` to the fetch and decode units.  This
causes the fetch unit to reset its PC to `uc_resume_pc_uc0` and suppress its
valid bit until `uc_trapped_uc0` deasserts, at which point it will begin
fetching again.  It also causes the decode unit to flush itself.

Branch correction
----------------------

When a branch is mispredicted and needs to be corrected, we have to know several things:

1. what is the PC of the next instruction?
2. are we resuming from ucode rom?  (i.e. was the mispredicted branch a ucbr?)
3. if the branch was a ucbr, what is the USPC of next ROM instruction?

When any branch is mispredicted -- regardless of type -- both FE and US go into a PDG_RESUME state.  The misprediction packet indicates both next PC and next USPC, as well as an indication of whether the new target is from the PC or the USPC.  USPC is only valid if the `resume_from_ucode` bit is set.

When the ROB finishes its RAT unwind, it sends a resume_fetch packet to both FE and US.

TODOs
--------

**Correctness**
[x] ldq/stq full not connected; dealloc not yet hooked up into ldq/stq id tracker in allocation unit
[ ] no exceptions

**New functionality**
[ ] no CSRs
[ ] ucode rom not implemented (need renamed temp regs?)
[ ] unaligned ld/st not implemented (ucode implementation first?)

**IPC and other fun stuff**
[ ] no compressed instruction support
[ ] no BTB or nontrivial branch prediction
[ ] no pipeline selective clears (just nukes)

