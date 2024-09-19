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
* **DECODE** receives instructions from **FETCH** and decodes them into uops.
* **ALLOC** receives decoded instructions from **DECODE**, assigns ROBIDs, and sends uops to the appropriate **RS**.

**Out-of-Order**

* **EXE** executes integer uops from its **RS** when its deps are available, and writes back to the **ROB**.
* **MEM** executes memory uops from its **RS** when its deps are available, and writes back to the **ROB**.

**In-Order**

* **RETIRE** receives writebacks from the OoO part of the pipe and writes them back.

Presently, renaming is *super* basic.  In **ALLOC**, we scan the ROB for the youngest older instruction that is writing each of our source operands.  If any such instructions exist, the RS will wait for that ROB result to be written; otherwise, reads come out of the GPR RF when a uop is issued.  Eventually we'll do full renaming with a PRF, keeping a free list and reclaiming registers, etc...  but not today.

Branches are resolved in **EXE** but not taken until **RETIRE**.  Branches are currently always predicted NT.

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

