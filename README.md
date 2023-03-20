vroom
=====

vroom is a simple RISC-V core written in SystemVerilog.  

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
