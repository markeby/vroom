`ifndef __RS_REG_TRK_SV
`define __RS_REG_TRK_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "common.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"

typedef struct packed {
   logic                        from_rob;
   common::t_rob_id             robid;
   instr_decode::t_uopnd_descr  descr;
} t_rs_reg_trk_static;

module rs_reg_trk
    import instr::*, instr_decode::*, common::*, rob_defs::*;
(
   input  logic               clk,
   input  logic               reset,

   input  logic               e_alloc_rs0,
   input  t_rs_reg_trk_static e_alloc_static_rs0,
   input  t_rv_reg_data       regrd_data_rs0,
   output t_rs_reg_trk_static e_static,

   input  logic               ro_valid_rb0,
   input  t_rob_result        ro_result_rb0,

   output logic               ready_rs1,
   output t_rv_reg_data       src_data
);

typedef enum logic {
   SRC_PDG_ROB,
   SRC_READY
} t_fsm;
t_fsm fsm, fsm_nxt;

//
// Nets
//

logic wb_valid_match_rb0;

//
// Logic
//

`DFF_EN(e_static, e_alloc_static_rs0, clk, e_alloc_rs0)

assign wb_valid_match_rb0 = ro_valid_rb0 & ro_result_rb0.robid == e_static.robid;

// capture source data, either at dispatch or rob writeback
if(1) begin : g_src_data
   t_rv_reg_data src_data_nxt;
   logic src_data_wren;
   assign src_data_nxt  = e_alloc_rs0 ? regrd_data_rs0 : ro_result_rb0.value;
   assign src_data_wren = e_alloc_rs0 | wb_valid_match_rb0;
   `DFF_EN(src_data, src_data_nxt, clk, src_data_wren)
end

//
// FSM
//

always_comb begin
   fsm_nxt = fsm;
   if (reset) begin
      fsm_nxt = SRC_READY;
   end else begin
      unique casez (fsm)
         SRC_READY:   if ( e_alloc_rs0 & ~e_alloc_static_rs0.from_rob ) fsm_nxt = SRC_READY;
                 else if ( e_alloc_rs0 &  e_alloc_static_rs0.from_rob ) fsm_nxt = SRC_PDG_ROB;
         SRC_PDG_ROB: if ( wb_valid_match_rb0                         ) fsm_nxt = SRC_READY;
      endcase
   end
end
`DFF(fsm, fsm_nxt, clk)

//
// Debug
//

endmodule

`endif // __RS_REG_TRK_SV

