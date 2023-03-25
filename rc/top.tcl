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

# Core signals
set sigs      [list clk reset]
set sigs      [prefixAll "${CORE}." $sigs]
addSignalGroup "Core" $sigs
puts $sigs

# Fetch signals
set sigs      [list state stall PC instr_fe0.opcode f__instr_fe0]
set fe_sigs   [prefixAll "${FE_CTL}." $sigs]
addSignalGroup "FE_CTL" $fe_sigs

set sigs      [list state];
set fe_sigs   [prefixAll "${FE_BUF}." $sigs]
addSignalGroup "FE_BUF" $fe_sigs

set sigs      [list fe_fb_req_fb0.valid fe_fb_req_fb0.addr fe_req_hit_fb0 fe_req_mis_fb0]
set fe_sigs   [prefixAll "${FE_BUF}." $sigs]
addSignalGroup "FE_BUF_REQ" $fe_sigs

set sigs      [list fb_fe_rsp_nnn.valid fb_fe_rsp_nnn.pc f__fb_fe_rsp_nnn_data]
set fe_sigs   [prefixAll "${FE_BUF}." $sigs]
addSignalGroup "FE_BUF_RSP" $fe_sigs

set sigs      [list fb_ic_req_nnn.valid fb_ic_req_nnn.addr ic_fb_rsp_nnn.valid ic_fb_rsp_nnn.data.flat ic_fb_rsp_nnn.__addr_inst]
set fe_sigs   [prefixAll "${FE_BUF}." $sigs]
addSignalGroup "FB_IC" $fe_sigs

for {set e 0} {$e < 4} {incr e} {
    set sigs    [list valid cl_addr data]
    set esigs   [prefixAll "${FE_BUF}.FBUF\[${e}\]." $sigs]
    addSignalGroup "FE_BUF_ENT${e}" $esigs
}

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

