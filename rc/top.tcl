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
set DECODE "${CORE}.decode"

set T_OPND        [list opreg opsize optype]

# Core signals
set sigs      [list clk reset]
set sigs      [prefixAll "${CORE}." $sigs]
addSignalGroup "Core" $sigs
puts $sigs

# Fetch signals
set sigs      [list valid_fe0 instr_fe0.opcode f__instr_fe0]
set fe_sigs   [prefixAll "${FETCH}." $sigs]
addSignalGroup "Fetch" $fe_sigs

# Decode signals
set uinstr_fields [prefixAll "uinstr_de0." [list valid funct imm32 opcode]]
set src1          [prefixAll "uinstr_de0.src1." $T_OPND]
set src2          [prefixAll "uinstr_de0.src2." $T_OPND]
set dst           [prefixAll "uinstr_de0.dst."  $T_OPND]
set sigs      [list {*}$uinstr_fields {*}$dst {*}$src1 {*}$src2]
set de_sigs   [prefixAll "${DECODE}." $sigs]
addSignalGroup "Decode" $de_sigs

