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

    input  rob_defs::t_rob_ent_static
                                  q_alloc_s_de1,
    input  logic                  e_alloc_de1,

    output rob_defs::t_rob_ent    rob_entry
);

//
// Nets
//

logic ready;

//
// Logic
//

assign rob_entry.d = '0;

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


