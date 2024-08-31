`ifndef __ROB_ENTRY_SV
`define __ROB_ENTRY_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "common.pkg"
`include "rob_defs.pkg"

module rob_entry
    import instr::*, instr_decode::*, verif::*, common::*, rob_defs::*;
(
    input  logic                  clk,
    input  logic                  reset,
    input  t_rob_id               robid,

    input  rob_defs::t_rob_ent_static
                                  q_alloc_s_de1,
    input  logic                  e_alloc_de1,

    input  logic                  ro_valid_rb0,
    input  t_rob_result           ro_result_rb0,

    input  logic                  q_flush_now_rb1,

    output logic                  e_valid,
    output rob_defs::t_rob_ent    rob_entry,
    input  logic                  e_retire_rb1
);

//
// FSM
//

typedef enum logic[1:0] {
   RBE_IDLE,
   RBE_PDG,
   RBE_READY,
   RBE_FLUSH
} t_rob_ent_fsm;
t_rob_ent_fsm fsm, fsm_nxt;

//
// Nets
//

logic         e_value_wr_rb0;
t_rv_reg_data e_result;

// Flushes
logic         e_flush_needed;
logic         e_flush_needed_rb0;

//
// FSM
//

always_comb begin
   fsm_nxt = fsm;
   if (reset) begin
      fsm_nxt = RBE_IDLE;
   end else begin
      unique casez (fsm)
         RBE_IDLE:    if ( e_alloc_de1     ) fsm_nxt = RBE_PDG;
         RBE_PDG:     if ( q_flush_now_rb1 ) fsm_nxt = RBE_IDLE;
                 else if ( e_flush_needed  ) fsm_nxt = RBE_FLUSH;
                 else if ( e_value_wr_rb0  ) fsm_nxt = RBE_READY;
         RBE_READY:   if ( q_flush_now_rb1 ) fsm_nxt = RBE_IDLE;
                 else if ( e_retire_rb1    ) fsm_nxt = RBE_IDLE;
         RBE_FLUSH:   if ( q_flush_now_rb1 ) fsm_nxt = RBE_IDLE;
      endcase
   end
end
`DFF(fsm, fsm_nxt, clk)

assign e_valid = (fsm != RBE_IDLE);

//
// Logic
//

// Flushes
assign e_flush_needed = e_value_wr_rb0 & ro_result_rb0.mispred;

//
// Dynamic state
//

assign rob_entry.d.ready        = fsm == RBE_READY;
assign rob_entry.d.flush_needed = fsm == RBE_FLUSH;
assign rob_entry.d.result       = e_result;

//
// Static state
//

t_rob_ent_static s;
`DFF_EN(s, q_alloc_s_de1, clk, e_alloc_de1)
assign rob_entry.s = s;

//
// Debug
//

`ifdef SIMULATION

`endif

`ifdef ASSERT

`endif

endmodule

`endif // __ROB_ENTRY_SV


