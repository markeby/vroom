`ifndef __FE_SV
`define __FE_SV

`include "instr.pkg"
`include "verif.pkg"
`include "asm.pkg"
`include "mem_common.pkg"
`include "common.pkg"
`include "vroom_macros.sv"

module fe
    import instr::*, mem_common::*, verif::*, common::*;
(
    input  logic       clk,
    input  logic       reset,
    input  t_rob_id    oldest_robid,

    output t_mem_req_pkt  ic_l2_req_pkt,
    input  t_mem_rsp_pkt  l2_ic_rsp_pkt,

    input  t_br_mispred_pkt br_mispred_ex0,
    input  t_nuke_pkt       nuke_rb1,
    input  logic            resume_fetch_rbx,

    input  logic       decode_ready_de0,
    output logic       valid_fe1,
    output t_instr_pkt instr_fe1
);

//
// Fake stuff
//

//
// Nets
//

t_fe_fb_req fe_fb_req_nnn;
t_fb_fe_rsp fb_fe_rsp_nnn;

t_mem_req_pkt   fb_ic_req_nnn;
t_mem_rsp_pkt   ic_fb_rsp_nnn;

//
// Logic
//

fe_ctl fe_ctl (
    .clk,
    .reset,
    .nuke_rb1,
    .resume_fetch_rbx,
    .oldest_robid,

    .br_mispred_ex0,

    .fe_fb_req_nnn,
    .fb_fe_rsp_nnn,

    .valid_fe1,
    .instr_fe1,
    .decode_ready_de0
);

fe_buf fe_buf (
    .clk,
    .reset,

    .fe_fb_req_fb0 ( fe_fb_req_nnn ),
    .fb_fe_rsp_nnn,

    .fb_ic_req_nnn,
    .ic_fb_rsp_nnn
);

icache #(.LATENCY(5)) icache (
    .clk,
    .reset,
    .ic_l2_req_pkt,
    .l2_ic_rsp_pkt,
    .fb_ic_req_nnn,
    .ic_fb_rsp_nnn
);

//
// Displays
//

`ifdef ASSERT

// logic[$clog2(128)-1:0] irom_index;
// always_comb irom_index = instr_fe1.pc[$clog2(128)+1:2];
// `VASSERT(a_corrupt_instr, valid_fe1, instr_fe1.instr == t_rv_instr'(icache.IROM[irom_index]), $sformatf("Instruction mismatch simid:%s exp(%h) != act(%h)", format_simid(instr_fe1.SIMID), icache.IROM[irom_index], instr_fe1.instr))

fetch_chk fetch_chk (
    .clk,
    .reset,
    .nuke_rb1,
    .decode_ready_de0,
    .valid_fe1,
    .instr_fe1,
    .br_mispred_ex0
);

    /*
logic valid_fe2_inst;

`DFF(instr_pkt_fe2,  instr_pkt_fe1, clk)
`DFF(valid_fe2_inst, valid_fe1,     clk)

`VASSERT(a_lost_instr, valid_fe1 & valid_fe2_inst & instr_pkt_fe1.SIMID != instr_pkt_fe2.SIMID, core.decode.uinstr_de1.SIMID == instr_pkt_fe2.SIMID, $sformatf("Lost an instruction with simid:%s", format_simid(instr_pkt_fe2.SIMID)))
*/

//chk_no_change #(.T(t_instr_pkt)) cnc ( .clk, .reset, .hold(stall & valid_fe1), .thing(instr_pkt_fe1) );
`endif


endmodule

`endif // __FE_SV

