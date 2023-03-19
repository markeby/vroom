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

# Core signals
set sigs      [list clk reset]
set sigs      [prefixAll "top.core." $sigs]
addSignalGroup "Core" $sigs
puts $sigs

# Fetch signals
set sigs      [list instr_de0.opcode valid_de0]
set fe_sigs   [prefixAll "top.core." $sigs]
addSignalGroup "Fetch" $fe_sigs

# Decode signals
set uinstr_fields [prefixAll "uinstr_de0." [list funct imm32 opcode valid]]
set sigs      [list {*}$uinstr_fields uinstr_de0.dst.oreg]
set de_sigs   [prefixAll "top.core.decode." $sigs]
addSignalGroup "Decode" $de_sigs

