gtkwave::/Edit/Insert_Comment "Vroom"

# Helper procs
proc addSignalGroup {name path sig_list} {
    set sigs_full [list]
    foreach s $sig_list {
        lappend sigs_full [format "%s.%s" $path $s]
    }
    puts $sigs_full

    gtkwave::addSignalsFromList $sigs_full
    gtkwave::highlightSignalsFromList $sigs_full
    gtkwave::/Edit/Create_Group $name
    gtkwave::/Edit/UnHighlight_All
}

#proc prefixAll {prefix xs} {
#    set finals [list]
#    foreach x $xs {
#        lappend finals [format "%s%s" $prefix $x]
#    }
#    return $finals
#}

# Fetch signals
set sigs      [list instr_de0.opcode]
addSignalGroup "Fetch" "top.core" $sigs

# Decode signals
set sigs      [list uinstr_de0.opcode]
addSignalGroup "Decode" "top.core.decode" $sigs
