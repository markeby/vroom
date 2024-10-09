INC_DIR   := src/rtl/include/
SRC_DIR   := src/rtl/
LIB_DIR   := src/rtl/lib/

RTL_F := src/rtl.f

INC_FILES := $(wildcard $(INC_DIR)/*.sv)
LIB_FILES := $(wildcard $(LIB_DIR)/*.sv)
SRC_FILES := $(shell cat $(RTL_F))

IVERILOG  := iverilog -g2012
VERILATOR := verilator -Wall -Wno-PINCONNECTEMPTY -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM --assert --timing
VL_TRACE_FLAGS := --trace-fst --trace-structs --trace-params

VL_DEFINES := +define+SIMULATION=1 +define+ASSERT=1 #+define+DEBUGON=1
VL_WAIVER_OUT := --waiver-output new_waivers.txt

SIM_FLAGS :=

.PHONY: run
run: Vtop
	obj_dir/Vtop +load_disasm +preload:tests/branchy/test.pre +boot_vector:0000000080000000 ${SIM_FLAGS} | tee run.log
	#obj_dir/Vtop +load_disasm +preload:tests/hello_ebreak.preload +boot_vector:0000000080000000 ${SIM_FLAGS} | tee run.log
	#obj_dir/Vtop +load_disasm +preload:tests/hello.preload +boot_vector:0000000080000000 ${SIM_FLAGS} | tee run.log
	#obj_dir/Vtop +load_disasm +preload:tests/start.preload +boot_vector:0000000080000000 ${SIM_FLAGS} | tee run.log
	#obj_dir/Vtop ${SIM_FLAGS} | tee run.log
	scripts/split_log -f run.log

Vtop: verilated
	make -C obj_dir -f Vtop.mk Vtop  -j 8

.PHONY: verilated
verilated: $(SRC_FILES) $(LIB_FILES) 
	$(VERILATOR) $(VL_TRACE_FLAGS) --exe tb_top.cpp --cc -y $(LIB_DIR) -I$(INC_DIR) -I$(SRC_DIR) -f $(RTL_F) $(VL_DEFINES) -o Vtop --top-module top $(VL_WAIVER_OUT)

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
