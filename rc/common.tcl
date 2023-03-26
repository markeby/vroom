gtkwave::/Edit/Insert_Comment "Vroom"

# Helper procs
proc prefixAll {prefix xs} {
    set finals [list]
    foreach x $xs {
        lappend finals [format "%s%s" $prefix $x]
    }
    return $finals
}

proc addSignalGroup {name sigs_list} {
    gtkwave::addSignalsFromList $sigs_list
    groupSignals $name $sigs_list
}

proc groupSignals {name sigs_list} {
    gtkwave::highlightSignalsFromList $sigs_list
    gtkwave::/Edit/Create_Group $name
    gtkwave::/Edit/UnHighlight_All
}

set CORE   "top.core"
set FETCH  "${CORE}.fetch"
set FE_BUF "${FETCH}.fe_buf"
set FE_CTL "${FETCH}.fe_ctl"

set DECODE "${CORE}.decode"
set EXE    "${CORE}.exe"
set REGRD  "${CORE}.regrd"
set MEM    "${CORE}.mem"
set RETIRE "${CORE}.retire"
set SCORE  "${CORE}.scoreboard"
set GPRS   "${CORE}.gprs"

set T_OPND        [list opreg opsize optype]

