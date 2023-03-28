source "rc/common.tcl"

# Core signals
set sigs      [list clk reset]
set sigs      [prefixAll "${CORE}." $sigs]
addSignalGroup "Core" $sigs
puts $sigs

# Fetch signals
set sigs      [list br_mispred_rb1 br_tgt_rb1 stall valid_fe1 instr_fe1.instr.opcode instr_fe1.pc f__instr_fe1]
set fe_sigs   [prefixAll "${FE_CTL}." $sigs]
addSignalGroup "FE" $fe_sigs

# Fetch signals
set sigs      [list state PC]
set fe_sigs   [prefixAll "${FE_CTL}." $sigs]
addSignalGroup "FE_CTL" $fe_sigs

# Decode signals
set uinstr_fields [prefixAll "uinstr_de1." [list valid SIMID.fid uop funct imm32 opcode]]
set src1          [prefixAll "uinstr_de1.src1." $T_OPND]
set src2          [prefixAll "uinstr_de1.src2." $T_OPND]
set dst           [prefixAll "uinstr_de1.dst."  $T_OPND]
set sigs      [list fe_valid_de0 {*}$uinstr_fields {*}$dst {*}$src1 {*}$src2]
set de_sigs   [prefixAll "${DECODE}." $sigs]
addSignalGroup "DE" $de_sigs

# RegRd  signals
set uinstr_fields [prefixAll "uinstr_rd1." [list valid SIMID.fid uop funct imm32 opcode]]
set src1          [prefixAll "uinstr_rd1.src1." $T_OPND]
set src2          [prefixAll "uinstr_rd1.src2." $T_OPND]
set dst           [prefixAll "uinstr_rd1.dst."  $T_OPND]
set sigs      [list {*}$uinstr_fields {*}$dst {*}$src1 {*}$src2]
set rd_sigs   [prefixAll "${REGRD}." $sigs]
addSignalGroup "RD" $rd_sigs

# EXE  signals
set uinstr_fields [prefixAll "uinstr_ex1." [list valid SIMID.fid uop funct imm32 opcode]]
set src1          [prefixAll "uinstr_ex1.src1." $T_OPND]
set src2          [prefixAll "uinstr_ex1.src2." $T_OPND]
set dst           [prefixAll "uinstr_ex1.dst."  $T_OPND]
set sigs      [list {*}$uinstr_fields {*}$dst {*}$src1 {*}$src2]
set ex_sigs   [prefixAll "${EXE}." $sigs]
addSignalGroup "EX" $ex_sigs

# Mem  signals
set uinstr_fields [prefixAll "uinstr_mm1." [list valid SIMID.fid uop funct imm32 opcode]]
set src1          [prefixAll "uinstr_mm1.src1." $T_OPND]
set src2          [prefixAll "uinstr_mm1.src2." $T_OPND]
set dst           [prefixAll "uinstr_mm1.dst."  $T_OPND]
set sigs      [list {*}$uinstr_fields {*}$dst {*}$src1 {*}$src2]
set mm_sigs   [prefixAll "${MEM}." $sigs]
addSignalGroup "MM" $mm_sigs

# Retire signals
set uinstr_fields [prefixAll "uinstr_rb0." [list valid SIMID.fid uop funct imm32 opcode]]
set src1          [prefixAll "uinstr_rb0.src1." $T_OPND]
set src2          [prefixAll "uinstr_rb0.src2." $T_OPND]
set dst           [prefixAll "uinstr_rb0.dst."  $T_OPND]
set regwr         [list wren_rb0 wraddr_rb0 wrdata_rb0]
set sigs      [list {*}$uinstr_fields {*}$dst {*}$src1 {*}$src2 {*}$regwr]
set rb_sigs   [prefixAll "${RETIRE}." $sigs]
addSignalGroup "RB" $rb_sigs

# Scoreboard
set sigs      [list stall]
set sb_sigs   [prefixAll "${SCORE}." $sigs]
addSignalGroup "Scoreboard" $sb_sigs

# Regfile
#set sigs      [list]
#for {set i 0} {$i < 32} {incr i} {
#    lappend sigs "REGS\[$i\]"
#}
#set gpr_sigs  [prefixAll "${GPRS}." $sigs]
#addSignalGroup "GPRs" $gpr_sigs

