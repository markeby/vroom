source "rc/common.tcl"

# Core signals
set sigs      [list clk reset]
set sigs      [prefixAll "${CORE}." $sigs]
addSignalGroup "Core" $sigs
puts $sigs

proc addGroupDict {grpd {pfx ""}} {
    gtkwave::/Edit/UnHighlight_All

    # then children
    if {[dict exists $grpd children]} {
        set children [dict get $grpd children]
        foreach child $children {
            set my_pfx [dict get $grpd prefix]
            addGroupDict $child "${pfx}${my_pfx}"
        }
    }

    # first add all signals
    set signals [dict get $grpd signals]
    set pfx_signals [prefixAll [dict get $grpd prefix] $signals]
    if {[dict exists $grpd signals]} {
        gtkwave::addSignalsFromList $pfx_signals 
    }

    #gtkwave::/Edit/UnHighlight_All

    # then iterate over signals again, highlighting
    if {[dict exists $grpd signals]} {
        gtkwave::highlightSignalsFromList $pfx_signals
    }

    # ditto groups
    if {[dict exists $grpd children]} {
        foreach child [dict get $grpd children] {
            gtkwave::/Edit/Highlight_Regexp [dict get $child group_name]
        }
    }

    gtkwave::/Edit/Create_Group [dict get $grpd group_name]
}

proc makeNode {name pfx sigs kids} {
    set grp [dict create]
    dict set grp prefix $pfx
    dict set grp group_name $name
    dict set grp signals $sigs
    dict set grp children $kids
    return $grp
}

proc makeParent {name pfx kids} {
    return [makeNode $name "" [list] $kids]
}

proc makeLeaf {name pfx sigs} {
    return [makeNode $name $pfx $sigs [list]]
}

proc makeUopSrcDst {name pfx uop sigs} {
    set src1   [makeLeaf "${name} Src1" "${uop}.src1." $sigs]
    set src2   [makeLeaf "${name} Src2" "${uop}.src2." $sigs]
    set dst    [makeLeaf "${name} Dst"  "${uop}.dst."  $sigs]
    set grp    [makeNode $name pfx [list] [list $src1 $src2 $dst]]
    return $grp
}

set sigs [list br_mispred_rb1 br_tgt_rb1 stall valid_fe1 instr_fe1.instr.opcode instr_fe1.pc f__instr_fe1]
set fe_ctl [makeLeaf "FE CTL" "${FE_CTL}." $sigs]

set sigs [list state PC]
set fe_misc [makeLeaf "FE MISC" "${FE_CTL}." $sigs]

set sigs [list fb_ic_req_nnn.valid fb_ic_req_nnn.addr]
set fb_ic_req [makeLeaf "FB2IC Req" "${FE_BUF}." $sigs]

set fetch [makeParent "FE" "" [list $fe_ctl $fe_misc $fb_ic_req]]
addGroupDict $fetch

# Decode signals
set uinstr_fields [prefixAll "uinstr_de1." [list valid SIMID.fid uop funct imm64 opcode]]

set glst [list]
lappend glst [makeLeaf "DE CTL" "" [list valid_fe1]]
lappend glst [makeUopSrcDst "DE Operands" "${DECODE}." "uinstr_de1" $T_OPND]
addGroupDict [makeNode "Decode" "${DECODE}." [list] $glst]

# RegRd  signals
set glst [list]
lappend glst [makeLeaf "RD Uop" "uinstr_rd1." [list valid SIMID.fid uop funct imm64 opcode]]
lappend glst [makeUopSrcDst "RD Operands" "${REGRD}." "uinstr_rd1" $T_OPND]
addGroupDict [makeNode "RD" "${REGRD}." [list] $glst]

# EXE  signals
set glst [list]
lappend glst [makeLeaf "EXE Uop"  "uinstr_ex1." [list valid SIMID.fid uop funct imm64 opcode]]
lappend glst [makeUopSrcDst "EXE Operands" "${EXE}." "uinstr_ex1" $T_OPND]
addGroupDict [makeNode "EX" "${EXE}." [list] $glst]

# Mem  signals
set glst [list]
lappend glst [makeLeaf "MEM Uop" "uinstr_mm1." [list valid SIMID.fid uop funct imm64 opcode]]
lappend glst [makeUopSrcDst "MEM Operands" "${MEM}." "uinstr_mm1" $T_OPND]
addGroupDict [makeNode "MM" "${MEM}." [list] $glst]

# Retire signals
set glst []
lappend glst [makeLeaf "RB Uop" "uinstr_rb0." [list valid SIMID.fid uop funct imm64 opcode]]
lappend glst [makeUopSrcDst "RB Operands" "${RETIRE}." "uinstr_rb1" $T_OPND]
lappend glst [makeLeaf "RB RegWr" "" [list wren_rb0 wraddr_rb0 wrdata_rb0]]
addGroupDict [makeNode "RB" "${RETIRE}." [list] $glst]

# Scoreboard
addGroupDict [makeLeaf "Scoreboard" "${SCORE}." [list stall]]

# Regfile
set sigs      [list]
for {set i 0} {$i < 32} {incr i} {
    lappend sigs "REGS\[$i\]"
}
addGroupDict [makeLeaf "GPRs" "${GPRS}." $sigs]

