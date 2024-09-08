`ifndef __RS_ENTRY_SV
`define __RS_ENTRY_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "common.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"

typedef struct packed {
   instr_decode::t_uinstr_disp uinstr_disp;
} t_rs_entry_static;

module rs_entry
    import instr::*, instr_decode::*, common::*, rob_defs::*;
(
    input  logic          clk,
    input  logic          reset,

    input  logic          iprf_wr_en_ro0   [IPRF_NUM_WRITES-1:0],
    input  t_prf_wr_pkt   iprf_wr_pkt_ro0  [IPRF_NUM_WRITES-1:0],

    input  logic          e_alloc_rs0,
    input  t_rs_entry_static  q_alloc_static_rs0,

    output logic          e_valid,
    output t_rs_entry_static
                          e_static,
    output t_uinstr_iss   e_issue_pkt_rs1,

    output logic          e_req_issue_rs1,
    input  logic          e_gnt_issue_rs1
);

localparam RS_ENTRY0 = 0;
localparam RS_ENTRY1 = 1;
localparam NUM_EX_STAGES = 1;

typedef enum logic {
    IDLE,
    VALID
} t_rs_ent_fsm;
t_rs_ent_fsm fsm;
t_rs_ent_fsm fsm_nxt;

//
// Nets
//

logic e_dealloc_any;

//
// FSM
//

always_comb begin
    fsm_nxt = fsm;
    if (reset) begin
        fsm_nxt = IDLE;
    end else begin
        unique casez (fsm)
            IDLE:  if ( e_alloc_rs0   ) fsm_nxt = VALID;
            VALID: if ( e_dealloc_any ) fsm_nxt = IDLE;
        endcase
    end
end
`DFF(fsm, fsm_nxt, clk)

assign e_valid = fsm == VALID;

//
// Logic
//

`DFF_EN(e_static, q_alloc_static_rs0, clk, e_alloc_rs0)

// Will eventually need multiple dealloc causes since some uops will need to
// replay... but for now, just dealloc when we successfully issue

assign e_dealloc_any = e_gnt_issue_rs1;

//
// Register tracking
//

t_rs_reg_trk_static    e_alloc_static_rs0[NUM_SOURCES-1:0];
logic[NUM_SOURCES-1:0] src_ready_rs1;

assign e_alloc_static_rs0[SRC1].psrc_pend = q_alloc_static_rs0.uinstr_disp.rename.psrc1_pend;
assign e_alloc_static_rs0[SRC1].psrc      = q_alloc_static_rs0.uinstr_disp.rename.psrc1;
assign e_alloc_static_rs0[SRC1].descr     = q_alloc_static_rs0.uinstr_disp.uinstr.src1;

assign e_alloc_static_rs0[SRC2].psrc_pend = q_alloc_static_rs0.uinstr_disp.rename.psrc2_pend;
assign e_alloc_static_rs0[SRC2].psrc      = q_alloc_static_rs0.uinstr_disp.rename.psrc2;
assign e_alloc_static_rs0[SRC2].descr     = q_alloc_static_rs0.uinstr_disp.uinstr.src2;

for (genvar srcx=0; srcx<NUM_SOURCES; srcx++) begin : g_src_trk
   rs_reg_trk rs_reg_trk (
      .clk,
      .reset,
      .e_alloc_rs0,
      .e_alloc_static_rs0 ( e_alloc_static_rs0[srcx] ) ,
      .e_static           (                          ) ,
      .iprf_wr_en_ro0,
      .iprf_wr_pkt_ro0,
      .ready_rs1          ( src_ready_rs1[srcx]      )
   );
end

assign e_req_issue_rs1 = e_valid & (&src_ready_rs1);
always_comb begin
    e_issue_pkt_rs1.uinstr   = e_static.uinstr_disp.uinstr;
    e_issue_pkt_rs1.robid    = e_static.uinstr_disp.robid;
    e_issue_pkt_rs1.pdst     = e_static.uinstr_disp.rename.pdst;
    e_issue_pkt_rs1.src1_val = '0;
    e_issue_pkt_rs1.src2_val = '0;
    e_issue_pkt_rs1.meta     = t_issue_meta'('0);
end

//
// Debug
//

`ifdef SIMULATION
// always @(posedge clk) begin
//     if (uinstr_rd1.valid) begin
//         `INFO(("unit:EX %s result:%08h", describe_uinstr(uinstr_rd1), result_exx[RS_ENTRY0]))
//     end
// end
`endif

`ifdef ASSERT
//VASSERT(a_br_mispred, uinstr_rd1.valid & ibr_resvld_ex0, ~ibr_mispred_ex0, "Branch mispredictions not yet supported.")
`endif

endmodule

`endif // __RS_ENTRY_SV

