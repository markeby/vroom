vroom
=====

vroom is a simple RISC-V core written in SystemVerilog, compiled with Verilator.

- **src/** contains the RTL
- **rc/** contains TCL scripts for gtkwave

To build the model:

```
make Vtop
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

