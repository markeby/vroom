`ifndef __ROB_SV
`define __ROB_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "common.pkg"
`include "rob_defs.pkg"
`include "gen_funcs.pkg"
`include "rename_defs.pkg"

module rob
    import instr::*, instr_decode::*, verif::*, common::*, rob_defs::*, gen_funcs::*, rename_defs::*;
(
    input  logic             clk,
    input  logic             reset,

    output logic             rob_ready_ra0,
    output t_rob_id          oldest_robid,

    input  logic             alloc_ra0,
    input  t_uinstr          uinstr_ra0,
    input  t_rename_pkt      rename_ra0,
    output t_rob_id          next_robid_ra0,

    input  logic             ro_valid_rb0,
    input  t_rob_result      ro_result_rb0,

    input  t_rv_reg_addr     src_addr_ra0          [NUM_SOURCES-1:0],
    output logic             rob_src_reg_pdg_ra0   [NUM_SOURCES-1:0],
    output t_rob_id          rob_src_reg_robid_ra0 [NUM_SOURCES-1:0],

    output logic             reclaim_prf_rb1,
    output t_prf_id          reclaim_prf_id_rb1,

    output t_rat_restore_pkt rat_restore_pkt_rbx,

    output t_uinstr          uinstr_rb1,
    output t_nuke_pkt        nuke_rb1,
    output logic             resume_fetch_rbx
);

//
// Nets
//

t_rob_id head_id; // pointer to oldest valid ROBID (if ~empty)
t_rob_id tail_id; // pointer to first invalid ROBID (if ~full)

t_rob_ent entries [RB_NUM_ENTS-1:0];
logic                  q_retire_rb1;
logic[RB_NUM_ENTS-1:0] e_retire_rb1;

logic[RB_NUM_ENTS-1:0] e_valid;
logic                  q_alloc_ra0;
logic[RB_NUM_ENTS-1:0] e_alloc_ra0;
logic                  rob_full_ra0;
logic                  rob_empty_ra0;

logic                  q_flush_now_rb1;

//
// Logic
//

// ROB pointers

if(1) begin : g_rob_head_ptr
   t_rob_id head_id_nxt;
   assign head_id_nxt = reset           ? '0                    :
                        q_retire_rb1    ? f_incr_robid(head_id) :
                                          head_id;
   `DFF(head_id, head_id_nxt, clk)
end : g_rob_head_ptr
assign oldest_robid = head_id;

if(1) begin : g_rob_tail_ptr
   t_rob_id tail_id_nxt;
   assign tail_id_nxt = reset          ? '0                    :
                        nuke_rb1.valid ? f_incr_robid(head_id) :
                        q_alloc_ra0    ? f_incr_robid(tail_id) :
                                         tail_id;
   `DFF(tail_id, tail_id_nxt, clk)
end : g_rob_tail_ptr

assign next_robid_ra0 = tail_id;

assign rob_empty_ra0 = f_rob_empty(head_id, tail_id);
assign rob_full_ra0  = f_rob_full(head_id, tail_id);
assign rob_ready_ra0 = ~rob_full_ra0;

// Retire

t_rob_ent head_entry;
assign head_entry = entries[head_id.idx];

assign q_retire_rb1 = ~rob_empty_ra0 & head_entry.d.ready;
assign e_retire_rb1 = q_retire_rb1 ? (1 << head_id.idx) : '0;

assign uinstr_rb1 = head_entry.s.uinstr;

assign q_flush_now_rb1 = ~rob_empty_ra0 & head_entry.d.flush_needed;

assign nuke_rb1.valid     = q_flush_now_rb1;
assign nuke_rb1.nuke_type = uinstr_rb1.mispred ? NUKE_BR_MISPRED : NUKE_EXCEPTION;

assign reclaim_prf_rb1    = q_retire_rb1 & uinstr_rb1.dst.optype == OP_REG;
assign reclaim_prf_id_rb1 = head_entry.s.pdst_old;

//
// Alloc
//

assign q_alloc_ra0 = alloc_ra0;
assign e_alloc_ra0 = q_alloc_ra0 ? (1<<tail_id.idx) : '0;

//
// ROB Entries
//

t_rob_ent_static rob_st_new_ra0;
always_comb begin
   rob_st_new_ra0.uinstr   = uinstr_ra0;
   rob_st_new_ra0.pdst_old = rename_ra0.pdst_old;
end

for (genvar i=0; i<RB_NUM_ENTS; i++) begin : g_rob_ents
   rob_entry rbent (
      .clk,
      .reset,
      .e_valid       ( e_valid[i]      ),
      .robid         ( t_rob_id'(i)    ),
      .head_id,
      .q_alloc_s_ra0 ( rob_st_new_ra0  ),
      .e_alloc_ra0   ( e_alloc_ra0[i]  ),
      .ro_valid_rb0,
      .ro_result_rb0,
      .q_flush_now_rb1,
      .e_retire_rb1  ( e_retire_rb1[i] ),
      .rob_entry     ( entries[i]      )
   );
end

// 
// ROB source register
//

logic[RB_NUM_ENTS-1:0] rob_src_match_ra0     [NUM_SOURCES-1:0];
logic[RB_NUM_ENTS-1:0] rob_src_1st_match_ra0 [NUM_SOURCES-1:0];

for (genvar src=0; src<NUM_SOURCES; src++) begin : g_rob_source
    for (genvar ri=0; ri<RB_NUM_ENTS; ri++) begin : g_rob_srcmat
        assign rob_src_match_ra0[src][ri] = e_valid[ri] & (entries[ri].s.uinstr.dst.optype == OP_REG) & (entries[ri].s.uinstr.dst.opreg == src_addr_ra0[src]);
    end : g_rob_srcmat
    assign rob_src_1st_match_ra0[src] = gen_funcs#(.IWIDTH(RB_NUM_ENTS))::find_last1_from(rob_src_match_ra0[src], head_id.idx);

    always_comb begin
        rob_src_reg_pdg_ra0[src]   = |rob_src_match_ra0[src];
        rob_src_reg_robid_ra0[src] = {1'b0, gen_funcs#(.IWIDTH(RB_NUM_ENTS))::oh_encode(rob_src_1st_match_ra0[src])}; // FIXME: does the wrap bit need to be correct?  (probably!)
    end
end

//
// RAT restore
//
// When the oldest ROB entry needs a nuke, the process is:
//   1. q_flush_now_rb1 asserts to all parts of the core to quiesce ASAP
//      - capture tail_id in rr_robid;
//   2. we wait 5 cycles (way too long, but whatever -- TBD, shorten or make dynamic)
//      - at this point, we have stopped renaming
//   3. walk from rr_robid - 1 to rob_head, backwards, restoring the RAT
//   4. once we're at rob_head, send resume_fetch_rbx to fe_ctl

typedef enum logic[1:0] {
    RR_IDLE,
    RR_QUIET,
    RR_WALK,
    RR_RESUME_FETCH
} t_rat_restore_fsm;
t_rat_restore_fsm rr_fsm, rr_fsm_nxt;

localparam RR_QUIESCE_CYCLES = 5;

t_rob_id rr_robid;
logic[$clog2(RR_QUIESCE_CYCLES):0] rr_cntr;

always_comb begin
    rr_fsm_nxt = rr_fsm;
    if (reset) begin
        rr_fsm_nxt = RR_IDLE;
    end else begin
        unique casez (rr_fsm)
            RR_IDLE:         if ( q_flush_now_rb1          ) rr_fsm_nxt = RR_QUIET;
            RR_QUIET:        if ( ~|rr_cntr                ) rr_fsm_nxt = RR_WALK;
            RR_WALK:         if ( rr_robid == head_id      ) rr_fsm_nxt = RR_RESUME_FETCH;
            RR_RESUME_FETCH: if ( 1'b1                     ) rr_fsm_nxt = RR_IDLE;
        endcase
    end
end
`DFF(rr_fsm, rr_fsm_nxt, clk)

if (1) begin : g_rr_robid
    t_rob_id rr_robid_nxt;
    always_comb begin
        rr_robid_nxt = rr_robid;
        if (q_flush_now_rb1) begin
            rr_robid_nxt = tail_id;
        end else if (rr_fsm == RR_WALK) begin
            rr_robid_nxt = f_decr_robid(rr_robid);
        end
    end
    `DFF(rr_robid, rr_robid_nxt, clk)
end

assign rat_restore_pkt_rbx.valid = rr_fsm == RR_WALK
                                 & entries[rr_robid.idx].s.uinstr.dst.optype == OP_REG;
assign rat_restore_pkt_rbx.gpr   = entries[rr_robid.idx].s.uinstr.dst.opreg;
assign rat_restore_pkt_rbx.prfid = entries[rr_robid.idx].s.pdst_old;
`ifdef SIMULATION
assign rat_restore_pkt_rbx.SIMID = entries[rr_robid.idx].s.uinstr.SIMID;
`endif

assign resume_fetch_rbx = rr_fsm == RR_RESUME_FETCH;

`DFF_EN(rr_cntr, (rr_fsm == RR_IDLE) ? (1+$clog2(RR_QUIESCE_CYCLES))'(RR_QUIESCE_CYCLES) : (rr_cntr - (1+$clog2(RR_QUIESCE_CYCLES))'(1)), clk, (rr_fsm == RR_IDLE | (|rr_cntr)))

//
// Debug
//

`ifdef SIMULATION

always @(posedge clk) begin
    if (q_retire_rb1) begin
        `UINFO(head_entry.s.uinstr.SIMID, ("unit:ROB func:retire robid:0x%0x %s",
            head_id,
            describe_uinstr(head_entry.s.uinstr)))
    end

    if (reclaim_prf_rb1) begin
        `UINFO(head_entry.s.uinstr.SIMID, ("unit:ROB func:reclaim %s", f_describe_prf(reclaim_prf_id_rb1)))
    end
end

`endif

`ifdef ASSERT
t_rob_id last_retire_robid;
logic    last_retire_robid_valid;
`DFF_EN(last_retire_robid, head_id, clk, q_retire_rb1)
`DFF(last_retire_robid_valid, ~reset & (last_retire_robid_valid | q_retire_rb1), clk)

`VASSERT(chk_robid_adv, q_retire_rb1 & last_retire_robid_valid, head_id == f_incr_robid(last_retire_robid), $sformatf("ROB advanced from 0x%0h -> 0x%0h", last_retire_robid, head_id))

`VASSERT(alloc_when_full, q_alloc_ra0, rob_ready_ra0, "ROB allocated when not ready!")

`endif

endmodule

`endif // __ROB_SV


