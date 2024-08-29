`ifndef __ROB_SV
`define __ROB_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "common.pkg"
`include "rob_defs.pkg"

module rob
    import instr::*, instr_decode::*, verif::*, common::*, rob_defs::*;
(
    input  logic             clk,
    input  logic             reset,

    input  t_uinstr          uinstr_de1,
    output t_rob_id          next_robid_ra0,

    input  logic             ro_valid_rb0,
    input  t_rob_result      ro_result_rb0,

    output t_uinstr          uinstr_rb1,
    output logic             wren_rb1,
    output t_rv_reg_addr     wraddr_rb1,
    output t_rv_reg_data     wrdata_rb1,

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
   assign head_id_nxt = reset       ? '0                    :
                        q_alloc_de1 ? f_incr_robid(head_id) :
                                      head_id;
   `DFF(head_id, head_id_nxt, clk)
end : g_rob_head_ptr

if(1) begin : g_rob_tail_ptr
   t_rob_id tail_id_nxt;
   assign tail_id_nxt = reset        ? '0                    :
                        q_retire_rb1 ? f_incr_robid(tail_id) :
                                       head_id;
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
assign result_rb1 = head_entry.d.result;

assign wren_rb1   = q_retire_rb1 & uinstr_rb1.dst.optype == OP_REG;
assign wraddr_rb1 = uinstr_rb1.dst.opreg;
assign wrdata_rb1 = result_rb1;

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
// Debug
//

`ifdef SIMULATION

`endif

`ifdef ASSERT

`endif

endmodule

`endif // __ROB_SV


