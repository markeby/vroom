# Helper procs
proc prefixAll {prefix xs} {
    set finals [list]
    foreach x $xs {
        lappend finals [format "%s%s" $prefix $x]
    }
    return $finals
}

proc clear_screen {} {
    gtkwave::/Edit/Highlight_All
    gtkwave::/Edit/Cut
}

proc maybeCollapse {collapse} {
    if {$collapse == 1}  {
        gtkwave::/Edit/Toggle_Group_Open|Close
    }
}

proc addSignalGroup {name sigs_list {collapse 0}} {
    gtkwave::addSignalsFromList $sigs_list
    groupSignals $name $sigs_list $collapse
}

proc groupSignals {name sigs_list {collapse 0}} {
    gtkwave::highlightSignalsFromList $sigs_list
    gtkwave::/Edit/Create_Group $name
    maybeCollapse $collapse
    gtkwave::/Edit/UnHighlight_All
}

proc groupGroups {name group_list {collapse 0}} {
    gtkwave::/Edit/UnHighlight_All
    foreach grp $group_list {
        gtkwave::/Edit/Highlight_Regexp $grp
    }
    gtkwave::/Edit/Create_Group $name
    maybeCollapse $collapse
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

clear_screen
gtkwave::/Edit/Insert_Comment "Vroom"

