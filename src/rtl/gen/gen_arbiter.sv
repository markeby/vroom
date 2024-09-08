`ifndef __GEN_ARBITER_SV
`define __GEN_ARBITER_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "gen_funcs.pkg"
`include "common.pkg"
`include "verif.pkg"

module gen_arbiter
    import gen_funcs::*, common::*, verif::*;
#(parameter int NREQS=4, type T=logic, string POLICY = "FIND_FIRST")
(
`include "gen/gen_arbiter_ports.svh"
);

//
// Logic
//

if (POLICY == "FIND_FIRST") begin : g_ff
    gen_arbiter_ff #(.NREQS(NREQS), .T(T)) arb (.*);
end else begin : g_wtf
    $error("I don't understand arbiter policy %s", POLICY);
end

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

`endif // __GEN_ARBITER_SV


