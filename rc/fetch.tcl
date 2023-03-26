source "rc/common.tcl"

# Core signals
set sigs      [list clk reset]
set sigs      [prefixAll "${CORE}." $sigs]
addSignalGroup "Core" $sigs
puts $sigs

# FB<->IC
set sigs      [list fb_ic_req_nnn.valid fb_ic_req_nnn.addr]
set fe_sigs   [prefixAll "${FE_BUF}." $sigs]
addSignalGroup "FB -> IC Req" $fe_sigs

set sigs      [list ic_fb_rsp_nnn.valid ic_fb_rsp_nnn.data.flat ic_fb_rsp_nnn.__addr_inst]
set fe_sigs   [prefixAll "${FE_BUF}." $sigs]
addSignalGroup "FB <- IC Rsp" $fe_sigs

set sigs      [list fe_fb_req_fb0.valid fe_fb_req_fb0.addr fe_req_hit_fb0 fe_req_mis_fb0]
set fe_sigs   [prefixAll "${FE_BUF}." $sigs]
addSignalGroup "FE_BUF_REQ" $fe_sigs

set sigs      [list fb_fe_rsp_nnn.valid fb_fe_rsp_nnn.pc f__fb_fe_rsp_nnn_data]
set fe_sigs   [prefixAll "${FE_BUF}." $sigs]
addSignalGroup "FE_BUF_RSP" $fe_sigs

# Fetch signals
set sigs      [list state stall PC instr_fe0.opcode f__instr_fe0]
set fe_sigs   [prefixAll "${FE_CTL}." $sigs]
addSignalGroup "FE_CTL" $fe_sigs

set sigs      [list state];
set fe_sigs   [prefixAll "${FE_BUF}." $sigs]
addSignalGroup "FE_BUF" $fe_sigs

for {set e 0} {$e < 4} {incr e} {
    set sigs    [list valid cl_addr data.flat]
    set esigs   [prefixAll "${FE_BUF}.FBUF\[${e}\]." $sigs]
    addSignalGroup "FE_BUF_ENT${e}" $esigs
}

# Regfile
#set sigs      [list]
#for {set i 0} {$i < 32} {incr i} {
#    lappend sigs "REGS\[$i\]"
#}
#set gpr_sigs  [prefixAll "${GPRS}." $sigs]
#addSignalGroup "GPRs" $gpr_sigs


