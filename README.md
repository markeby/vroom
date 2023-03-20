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

vroom has a simple six-stage pipeline:

* **FETCH** has a FSM to read instructions from main memory.  
* **DECODE** receives instructions from **FETCH** and decodes them into uops.
* **REGRD** receives uops from **DECODE** and reads registers, if needed.
* **EXE** receives uops from **REGRD** with register sources resolved.
* **MEM** receives uops from **EXE** with address calculations performed, and does requisite memory accesses.
* **WB** receives uops from **MEM** and updates registers as needed.

Branches are resolved in **EXE**.  Branches are currently always predicted NT.  
