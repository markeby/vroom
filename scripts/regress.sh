#!/usr/bin/env bash

SIM_FLAGS=""
TWD=$(git rev-parse --show-toplevel)
RUNSIM="${TWD}/scripts/runsim.py"

${RUNSIM} branchy -d regress/ --sim-args "+load_disasm +preload:${TWD}/tests/branchy/test.pre +boot_vector:0000000080000000 ${SIM_FLAGS}"
${RUNSIM} hello_ebreak -d regress/ --sim-args "+load_disasm +preload:${TWD}/tests/hello_ebreak.preload +boot_vector:0000000080000000 ${SIM_FLAGS}"
# ${RUNSIM} -d regress/test3 --sim-args "+load_disasm +preload:${TWD}/tests/hello.preload +boot_vector:0000000080000000 ${SIM_FLAGS}"
# ${RUNSIM} -d regress/test4 --sim-args "+load_disasm +preload:${TWD}/tests/start.preload +boot_vector:0000000080000000 ${SIM_FLAGS}"
