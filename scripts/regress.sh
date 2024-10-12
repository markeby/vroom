#!/usr/bin/env bash

TWD=$(git rev-parse --show-toplevel)

SIM_FLAGS=""
DATE_TAG=$(date "+%y-%m-%d-%H%M%S")
RUNSIM="${TWD}/scripts/runsim.py"
REGRESS="regress.${DATE_TAG}"
REGRESS_SYM="regress.latest"

echo "Regression directory: ${REGRESS}"

run_test(){
    local test_name="$1"
    local rundir="${REGRESS}/${test_name}"
    local cmd="${RUNSIM} ${test_name} --sim-args '+load_disasm +preload:./test/test.pre     +boot_vector:0000000080000000 ${SIM_FLAGS}'"

    mkdir -p "${rundir}"
    echo "rm -f PASS FAIL UNKNOWN" > "${rundir}/runit.sh"
    echo "$cmd" >> "${rundir}/runit.sh"
    echo "if [[ -e FAIL ]]; then echo 'FAIL'; fi" >> "${rundir}/runit.sh"
    echo "if [[ -e PASS ]]; then echo 'PASS'; fi" >> "${rundir}/runit.sh"
    echo "if [[ ! ( -e PASS || -e FAIL ) ]]; then echo 'UNKNOWN'; fi" >> "${rundir}/runit.sh"
    chmod +x "${rundir}/runit.sh"
    pushd "${rundir}" >& /dev/null
    ln -s ${TWD}/tests/${test_name}/ "test"
    ./runit.sh
    popd >& /dev/null
}
# ${RUNSIM} branchy      -d ${REGRESS} --sim-args "+load_disasm +preload:${TWD}/tests/branchy/test.pre     +boot_vector:0000000080000000 ${SIM_FLAGS}"
# ${RUNSIM} math         -d ${REGRESS} --sim-args "+load_disasm +preload:${TWD}/tests/math/test.pre        +boot_vector:0000000080000000 ${SIM_FLAGS}"

run_test branchy
run_test math

NPASS=$(find ${REGRESS} -name PASS | wc -l)
NFAIL=$(find ${REGRESS} -name FAIL | wc -l)
NUNKN=$(find ${REGRESS} -name UNKNOWN | wc -l)
let NTOT="${NPASS} + ${NFAIL} + ${NUNKN}"

echo "${NPASS}/${NTOT} Passes"

find ${REGRESS} -name FAIL
find ${REGRESS} -name UNKNOWN

if [[ -L ${REGRESS_SYM} ]]; then
    rm -rf ${REGRESS_SYM}
fi
ln -s ${REGRESS} ${REGRESS_SYM}
