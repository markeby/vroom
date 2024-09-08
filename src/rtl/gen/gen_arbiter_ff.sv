`ifndef __GEN_ARBITER_FF_SV
`define __GEN_ARBITER_FF_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "gen_funcs.pkg"
`include "common.pkg"
`include "verif.pkg"

module gen_arbiter_ff
    import gen_funcs::*, common::*, verif::*;
#(parameter int NREQS=4, type T=logic)
(
`include "gen/gen_arbiter_ports.svh"
);

//
// Nets
//

logic[NREQS-1:0] int_req_sel;

//
// Logic
//

assign int_req_sel = gen_funcs#(.IWIDTH(NREQS))::find_first1(int_req_valids);
assign ext_req_valid = |int_req_valids;
assign ext_req_pkt   = mux_funcs#(.IWIDTH(NREQS), .T(T))::uaomux(int_req_pkts, int_req_sel);
assign int_gnts      = ext_gnt ? int_req_sel : '0;

//
// Debug
//

`ifdef SIMULATION
`endif

`ifdef ASSERT
    // `VASSERT(push_when_full, push_front_xw0[0], ~full,  "Illegal FIFO push when full")
    // `VASSERT(pop_when_empty, pop_back_xr0[0],   ~empty, "Illegal FIFO pop when empty")
`endif

endmodule

`endif // __GEN_ARBITER_FF_SV


