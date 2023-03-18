SRC_FILES := $(cat src/rtl.f) src/rtl.f
IVERILOG  := iverilog -g2012

sim: $(SRC_FILES)
	$(IVERILOG) -I src/rtl/include -f src/rtl.f -o $@

.PHONY: run
run: sim
	./sim

.PHONY: clean
clean:
	rm -f sim
