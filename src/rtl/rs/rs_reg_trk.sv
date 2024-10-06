`ifndef __RS_REG_TRK_SV
`define __RS_REG_TRK_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "common.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"
`include "gen_funcs.pkg"

typedef struct packed {
   logic                        psrc_pend;
   common::t_prf_id             psrc;
   instr_decode::t_uopnd_descr  descr;
} t_rs_reg_trk_static;

module rs_reg_trk
    import instr::*, instr_decode::*, common::*, rob_defs::*, gen_funcs::*;
(
   input  logic               clk,
   input  logic               reset,

   input  logic               e_alloc_rs0,
   input  t_rs_reg_trk_static e_alloc_static_rs0,
   output t_rs_reg_trk_static e_static,
   input  logic               e_dealloc,

   input  logic               iprf_wr_en_ro0   [IPRF_NUM_WRITES-1:0],
   input  t_prf_wr_pkt        iprf_wr_pkt_ro0  [IPRF_NUM_WRITES-1:0],

   output logic               ready_rs1
);

typedef enum logic[1:0] {
    SRC_IDLE,
    SRC_PDG_RSLT,
    SRC_READY
} t_fsm;
t_fsm fsm, fsm_nxt;

//
// Nets
//

logic[IPRF_NUM_WRITES-1:0] wb_valid_matches_ro0;
logic                      wb_valid_match_any_ro0;
t_rv_reg_data              wb_valid_datas_ro0 [IPRF_NUM_WRITES-1:0];
t_rv_reg_data              wb_valid_data_ro0;

//
// Logic
//

t_rs_reg_trk_static e_static_nxt;
assign e_static_nxt = e_alloc_rs0 ? e_alloc_static_rs0 : e_static;
`DFF_EN(e_static, e_static_nxt, clk, e_alloc_rs0)

for (genvar p=0; p<IPRF_NUM_WRITES; p++) begin : g_wb_mat
    assign wb_valid_matches_ro0[p] = iprf_wr_en_ro0[p] & iprf_wr_pkt_ro0[p].pdst == e_static_nxt.psrc;
    assign wb_valid_datas_ro0[p] = iprf_wr_pkt_ro0[p].data;
end
assign wb_valid_match_any_ro0 = |wb_valid_matches_ro0;
assign wb_valid_data_ro0 = wb_valid_datas_ro0[0]; //gen_funcs#(.IWIDTH(IPRF_NUM_WRITES),.T(t_rv_reg_data))::uaomux(wb_valid_datas_ro0, wb_valid_matches_ro0);

assign ready_rs1 = fsm == SRC_READY
                 | fsm == SRC_PDG_RSLT & wb_valid_match_any_ro0;
//
// FSM
//

always_comb begin
   fsm_nxt = fsm;
   if (reset) begin
      fsm_nxt = SRC_IDLE;
   end else begin
      unique casez (fsm)
         SRC_IDLE:     if ( e_alloc_rs0 & ~e_alloc_static_rs0.psrc_pend                           ) fsm_nxt = SRC_READY;
                  else if ( e_alloc_rs0 &  e_alloc_static_rs0.psrc_pend &  wb_valid_match_any_ro0 ) fsm_nxt = SRC_READY;
                  else if ( e_alloc_rs0 &  e_alloc_static_rs0.psrc_pend & ~wb_valid_match_any_ro0 ) fsm_nxt = SRC_PDG_RSLT;
         SRC_PDG_RSLT: if ( e_dealloc                                                             ) fsm_nxt = SRC_IDLE;
                  else if ( wb_valid_match_any_ro0                                                ) fsm_nxt = SRC_READY;
         SRC_READY:    if ( e_dealloc                                                             ) fsm_nxt = SRC_IDLE;
      endcase
   end
end
`DFF(fsm, fsm_nxt, clk)

//
// Debug
//

`ifdef ASSERT
    `VASSERT(a_illegal_psrc_pend, e_alloc_rs0 & e_alloc_static_rs0.psrc_pend, e_alloc_static_rs0.descr.optype == OP_REG, $sformatf("rs_reg_trk allocated with non-reg pending (%s)", e_alloc_static_rs0.descr.optype.name))
    `VASSERT(a_bad_pend_psrc, fsm == SRC_PDG_RSLT, core.rename.iprf.pend_list[e_static.psrc.idx], "RS entry stuck waiting on non-pending PRF entry")
`endif


endmodule

`endif // __RS_REG_TRK_SV

