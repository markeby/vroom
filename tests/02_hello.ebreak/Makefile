.PHONY: all run clean

SRC=$(wildcard *.s)
OBJ=$(SRC:%.s=%.o)
ELF=$(SRC:%.s=%.elf)
DIS=$(SRC:%.s=%.dis)
LOG=$(SRC:%.s=%.log)
PRE=$(SRC:%.s=%.pre)
DIS2PRE=../../scripts/dis2pre.py

.PRECIOUS: $(LOG)

all: $(PRE) $(ELF) $(DIS)
run: $(LOG)

%.pre: %.dis
	$(DIS2PRE) $< $@

%.o: %.s
	riscv64-unknown-elf-gcc -c -march=rv64i -mabi=lp64 -ggdb -o $@ $<
	#riscv64-unknown-elf-gcc -c -march=rv64imafdc -mabi=lp64 -ggdb -o $@ $<

%.elf: %.o %.ld
	riscv64-unknown-elf-gcc -nostdlib -T $*.ld -o $@ $<

%.dis: %.elf
	riscv64-unknown-elf-objdump -d $< > $@

%.log: %.elf
	spike -l --log=$@ -m0x80000000:0x100000 $< | tee output.txt

clean:
	rm -f $(ELF) $(OBJ) $(LOG) $(DIS) output.txt
