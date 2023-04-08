source "rc/common.tcl"

# Core signals
set sigs      [list clk reset]
set sigs      [prefixAll "${CORE}." $sigs]
addSignalGroup "Core" $sigs
puts $sigs

set fetch [dict create]

set sigs [list br_mispred_rb1 br_tgt_rb1 stall valid_fe1 instr_fe1.instr.opcode instr_fe1.pc f__instr_fe1]
dict set fetch "FE" [dict create sigs [prefixAll "${FE_CTL}." $sigs] collapse 0]
set sigs [list state PC]
dict set fetch "FE_CTL" [dict create sigs [prefixAll "${FE_CTL}." $sigs] collapse 1]

dict for {grp grpd} $fetch {
    set sigs     [dict get $grpd sigs]
    set collapse [dict get $grpd collapse]
    addSignalGroup $grp $sigs $collapse
}
groupGroups "Fetch" [dict keys $fetch] 0

# Decode signals
set uinstr_fields [prefixAll "uinstr_de1." [list valid SIMID.fid uop funct imm64 opcode]]
set src1          [prefixAll "uinstr_de1.src1." $T_OPND]
set src2          [prefixAll "uinstr_de1.src2." $T_OPND]
set dst           [prefixAll "uinstr_de1.dst."  $T_OPND]
set sigs      [list fe_valid_de0 {*}$uinstr_fields {*}$dst {*}$src1 {*}$src2]
set de_sigs   [prefixAll "${DECODE}." $sigs]
addSignalGroup "DE" $de_sigs 1

# RegRd  signals
set uinstr_fields [prefixAll "uinstr_rd1." [list valid SIMID.fid uop funct imm64 opcode]]
set src1          [prefixAll "uinstr_rd1.src1." $T_OPND]
set src2          [prefixAll "uinstr_rd1.src2." $T_OPND]
set dst           [prefixAll "uinstr_rd1.dst."  $T_OPND]
set sigs      [list {*}$uinstr_fields {*}$dst {*}$src1 {*}$src2]
set rd_sigs   [prefixAll "${REGRD}." $sigs]
addSignalGroup "RD" $rd_sigs 1

# EXE  signals
set uinstr_fields [prefixAll "uinstr_ex1." [list valid SIMID.fid uop funct imm64 opcode]]
set src1          [prefixAll "uinstr_ex1.src1." $T_OPND]
set src2          [prefixAll "uinstr_ex1.src2." $T_OPND]
set dst           [prefixAll "uinstr_ex1.dst."  $T_OPND]
set sigs      [list {*}$uinstr_fields {*}$dst {*}$src1 {*}$src2]
set ex_sigs   [prefixAll "${EXE}." $sigs]
addSignalGroup "EX" $ex_sigs 1

# Mem  signals
set uinstr_fields [prefixAll "uinstr_mm1." [list valid SIMID.fid uop funct imm64 opcode]]
set src1          [prefixAll "uinstr_mm1.src1." $T_OPND]
set src2          [prefixAll "uinstr_mm1.src2." $T_OPND]
set dst           [prefixAll "uinstr_mm1.dst."  $T_OPND]
set sigs      [list {*}$uinstr_fields {*}$dst {*}$src1 {*}$src2]
set mm_sigs   [prefixAll "${MEM}." $sigs]
addSignalGroup "MM" $mm_sigs 1

# Retire signals
set uinstr_fields [prefixAll "uinstr_rb0." [list valid SIMID.fid uop funct imm64 opcode]]
set src1          [prefixAll "uinstr_rb0.src1." $T_OPND]
set src2          [prefixAll "uinstr_rb0.src2." $T_OPND]
set dst           [prefixAll "uinstr_rb0.dst."  $T_OPND]
set regwr         [list wren_rb0 wraddr_rb0 wrdata_rb0]
set sigs      [list {*}$uinstr_fields {*}$dst {*}$src1 {*}$src2 {*}$regwr]
set rb_sigs   [prefixAll "${RETIRE}." $sigs]
addSignalGroup "RB" $rb_sigs 0

# Scoreboard
set sigs      [list stall]
set sb_sigs   [prefixAll "${SCORE}." $sigs]
addSignalGroup "Scoreboard" $sb_sigs 1

# Regfile
set sigs      [list]
for {set i 0} {$i < 32} {incr i} {
    lappend sigs "REGS\[$i\]"
}
set gpr_sigs  [prefixAll "${GPRS}." $sigs]
addSignalGroup "GPRs" $gpr_sigs 1

