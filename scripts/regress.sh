#!/usr/bin/env bash

TWD=$(git rev-parse --show-toplevel)

SIM_FLAGS=""
DATE_TAG=$(date "+%y-%m-%d-%H%M%S")
RUNSIM="${TWD}/scripts/runsim.py"
REGRESS="regress.${DATE_TAG}/"

echo "Regression directory: ${REGRESS}"

${RUNSIM} branchy      -d ${REGRESS} --sim-args "+load_disasm +preload:${TWD}/tests/branchy/test.pre     +boot_vector:0000000080000000 ${SIM_FLAGS}"
${RUNSIM} hello_ebreak -d ${REGRESS} --sim-args "+load_disasm +preload:${TWD}/tests/hello_ebreak.preload +boot_vector:0000000080000000 ${SIM_FLAGS}"

NPASS=$(find ${REGRESS} -name PASS | wc -l)
NFAIL=$(find ${REGRESS} -name FAIL | wc -l)
NUNKN=$(find ${REGRESS} -name UNKNOWN | wc -l)
let NTOT="${NPASS} + ${NFAIL} + ${NUNKN}"

echo "${NPASS}/${NTOT} Passes"
