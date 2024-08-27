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

    input  t_uinstr          uinstr_mm1,
    input  t_rv_reg_data     result_mm1,

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
logic     retire_valid_rb1;

logic                  q_alloc_de1;
logic[RB_NUM_ENTS-1:0] e_alloc_de1;
logic                  rob_full_de1;
logic                  rob_empty_de1;

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
   assign tail_id_nxt = reset            ? '0                    :
                        retire_valid_rb1 ? f_incr_robid(head_id) :
                                           head_id;
   `DFF(tail_id, tail_id_nxt, clk)
end : g_rob_tail_ptr

assign rob_empty_de1 = f_rob_empty(head_id, tail_id);
assign rob_full_de1  = f_rob_full(head_id, tail_id);

// Retire

assign retire_valid_rb1 = ~rob_empty_de1 & entries[head_id.idx].d.ready;

// Tieoffs

always_comb begin
   uinstr_rb1 = '0;
   wren_rb1 = '0;
   wraddr_rb1 = '0;
   wrdata_rb1 = '0;
   br_mispred_rb1 = '0;
   br_tgt_rb1 = '0;
end

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
      .q_alloc_s_de1 ( rob_st_new_de1 ),
      .e_alloc_de1   ( e_alloc_de1[i] ),
      .rob_entry     ( entries[i]     )
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


