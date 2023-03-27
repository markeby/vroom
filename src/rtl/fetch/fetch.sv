`ifndef __FETCH_SV
`define __FETCH_SV

`include "instr.pkg"
`include "verif.pkg"
`include "asm.pkg"
`include "mem_common.pkg"
`include "common.pkg"
`include "vroom_macros.sv"

module fetch
    import instr::*, mem_common::*, verif::*, common::*;
(
    input  logic       clk,
    input  logic       reset,
                       
    output t_mem_req   fb_ic_req_nnn,
    input  t_mem_rsp   ic_fb_rsp_nnn,
                       
    input  t_paddr     br_tgt_rb1,
    input  logic       br_mispred_rb1,

    output logic       valid_fe1,
    output t_instr_pkt instr_fe1,
    input  logic       stall
);

//
// Fake stuff
//

//
// Nets
//

t_fe_fb_req fe_fb_req_nnn;
t_fb_fe_rsp fb_fe_rsp_nnn;

//
// Logic
//

fe_ctl fe_ctl (
    .clk,
    .reset,

    .br_tgt_rb1,
    .br_mispred_rb1,

    .fe_fb_req_nnn,
    .fb_fe_rsp_nnn,

    .valid_fe1,
    .instr_fe1,
    .stall
);

fe_buf fe_buf (
    .clk,
    .reset,

    .fe_fb_req_fb0 ( fe_fb_req_nnn ),
    .fb_fe_rsp_nnn,

    .fb_ic_req_nnn,
    .ic_fb_rsp_nnn
);

//
// Displays
//

`ifdef ASSERT

`VASSERT(a_corrupt_instr, valid_fe1, instr_fe1.instr == t_rv_instr'(core.icache.IROM[instr_fe1.pc >> 2]), $sformatf("Instruction mismatch simid:%s exp(%h) != act(%h)", format_simid(instr_fe1.SIMID), core.icache.IROM[instr_fe1.pc >> 2], instr_fe1.instr))

fetch_chk fechk (
    .clk,
    .reset,
    .stall,
    .valid_fe1,
    .instr_fe1,
    .br_mispred_rb1,
    .br_tgt_rb1
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

`endif // __FETCH_SV

