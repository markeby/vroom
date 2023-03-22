INC_DIR   := src/rtl/include/
SRC_DIR   := src/rtl/
LIB_DIR   := src/rtl/lib/

RTL_F := src/rtl.f

INC_FILES := $(wildcard $(INC_DIR)/*.sv)
LIB_FILES := $(wildcard $(LIB_DIR)/*.sv)
SRC_FILES := $(shell cat $(RTL_F))

IVERILOG  := iverilog -g2012
VERILATOR := verilator -Wall -Wno-PINCONNECTEMPTY -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM --assert
VL_TRACE_FLAGS := --trace-fst --trace-structs --trace-params 

VL_DEFINES := +define+SIMULATION=1 +define+ASSERT=1 #+define+DEBUGON=1

.PHONY: run
run: Vtop
	obj_dir/Vtop | tee run.log
	@echo
	@echo "Splitting run.log"
	@echo
	scripts/split_log -f run.log

Vtop: verilated
	make -C obj_dir -f Vtop.mk Vtop 

.PHONY: verilated
verilated: $(SRC_FILES) $(LIB_FILES) 
	$(VERILATOR) $(VL_TRACE_FLAGS) --exe tb_top.cpp --cc -y $(LIB_DIR) -I$(INC_DIR) -f $(RTL_F) $(VL_DEFINES) -o Vtop --top-module top

.PHONY: clean
clean:
	rm -rf obj_dir/
	rm -f waves.fst
	rm -f *.log

#sim: $(SRC_FILES) $(LIB_FILES)
#	$(IVERILOG) -I $(INC_DIR) -y $(LIB_DIR) -f src/rtl.f -o $@
#
#.PHONY: run
#run: sim
#	./sim
#
#.PHONY: clean
#clean:
#	rm -f sim
