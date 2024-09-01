`ifndef __ROB_SV
`define __ROB_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "common.pkg"
`include "rob_defs.pkg"
`include "gen_funcs.pkg"

module rob
    import instr::*, instr_decode::*, verif::*, common::*, rob_defs::*, gen_funcs::*;
(
    input  logic             clk,
    input  logic             reset,

    input  t_uinstr          uinstr_de1,
    output t_rob_id          next_robid_ra0,

    input  logic             ro_valid_rb0,
    input  t_rob_result      ro_result_rb0,

    input  t_rv_reg_addr     src_addr_ra0          [NUM_SOURCES-1:0],
    output logic             rob_src_reg_pdg_ra0   [NUM_SOURCES-1:0],
    output t_rob_id          rob_src_reg_robid_ra0 [NUM_SOURCES-1:0],

    output t_uinstr          uinstr_rb1,

    output logic             br_mispred_rb1,
    output t_paddr           br_tgt_rb1
);

//
// Nets
//

t_rob_id head_id; // pointer to oldest valid ROBID (if ~empty)
t_rob_id tail_id; // pointer to first invalid ROBID (if ~full)

t_rob_ent entries [RB_NUM_ENTS-1:0];
logic                  q_retire_rb1;
logic[RB_NUM_ENTS-1:0] e_retire_rb1;

t_rv_reg_data          result_rb1;

logic[RB_NUM_ENTS-1:0] e_valid;
logic                  q_alloc_de1;
logic[RB_NUM_ENTS-1:0] e_alloc_de1;
logic                  rob_full_de1;
logic                  rob_empty_de1;

logic                  q_flush_now_rb1;

//
// Logic
//

// ROB pointers

if(1) begin : g_rob_head_ptr
   t_rob_id head_id_nxt;
   assign head_id_nxt = reset        ? '0                    :
                        q_retire_rb1 ? f_incr_robid(head_id) :
                                       head_id;
   `DFF(head_id, head_id_nxt, clk)
end : g_rob_head_ptr

if(1) begin : g_rob_tail_ptr
   t_rob_id tail_id_nxt;
   assign tail_id_nxt = reset       ? '0                    :
                        q_alloc_de1 ? f_incr_robid(tail_id) :
                                      tail_id;
   `DFF(tail_id, tail_id_nxt, clk)
end : g_rob_tail_ptr

assign next_robid_ra0 = tail_id;

assign rob_empty_de1 = f_rob_empty(head_id, tail_id);
assign rob_full_de1  = f_rob_full(head_id, tail_id);

// Retire

t_rob_ent head_entry;
assign head_entry = entries[head_id.idx];

assign q_retire_rb1 = ~rob_empty_de1 & head_entry.d.ready;
assign e_retire_rb1 = q_retire_rb1 ? (1 << head_id.idx) : '0;

assign uinstr_rb1 = head_entry.s.uinstr;
assign result_rb1 = '0; //head_entry.d.result;

assign q_flush_now_rb1 = ~rob_empty_de1 & head_entry.d.flush_needed;

assign br_mispred_rb1 = q_flush_now_rb1 & uinstr_rb1.mispred;
assign br_tgt_rb1     = result_rb1;

//
// Alloc
//

assign q_alloc_de1 = uinstr_de1.valid;
assign e_alloc_de1 = q_alloc_de1 ? (1<<tail_id) : '0;

//
// ROB Entries
//

t_rob_ent_static rob_st_new_de1;
always_comb begin
   rob_st_new_de1.uinstr = uinstr_de1;
end

for (genvar i=0; i<RB_NUM_ENTS; i++) begin : g_rob_ents
   rob_entry rbent (
      .clk,
      .reset,
      .e_valid       ( e_valid[i]      ),
      .robid         ( t_rob_id'(i)    ),
      .q_alloc_s_de1 ( rob_st_new_de1  ),
      .e_alloc_de1   ( e_alloc_de1[i]  ),
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
// Debug
//

`ifdef SIMULATION

`endif

`ifdef ASSERT

`endif

endmodule

`endif // __ROB_SV


