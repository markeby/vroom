INC_DIR   := src/rtl/include/
SRC_DIR   := src/rtl/
LIB_DIR   := src/rtl/lib/

INC_FILES := $(shell find $(INC_DIR) -name '*.sv')
SRC_FILES := $(shell find $(SRC_DIR) -name '*.sv')
LIB_FILES := $(shell find $(LIB_DIR) -name '*.sv')

IVERILOG  := iverilog -g2012

Vcore: verilated
	make -C obj_dir -f Vcore.mk Vcore

.PHONY: verilated
verilated: $(SRC_FILES) $(LIB_FILES) 
	verilator  --trace --exe tb_core.cpp --cc -y $(LIB_DIR) -I$(INC_DIR) src/rtl/core.sv $(SRC_FILES)

sim: $(SRC_FILES) $(LIB_FILES)
	$(IVERILOG) -I $(INC_DIR) -y $(LIB_DIR) -f src/rtl.f -o $@

.PHONY: run
run: sim
	./sim

.PHONY: clean
clean:
	rm -f sim
