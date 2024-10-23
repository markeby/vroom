`ifndef __GEN_AGE_MATRIX_SV
`define __GEN_AGE_MATRIX_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "gen_funcs.pkg"
`include "common.pkg"
`include "verif.pkg"

module gen_age_matrix
    import gen_funcs::*, common::*, verif::*;
#(parameter int DEPTH=8, int NUM_REQS=1)
(
    input  logic             clk,
    input  logic             reset,

    input  logic[DEPTH-1:0]  e_alloc,
    output logic[DEPTH-1:0]  e_elders [DEPTH-1:0],

    input  logic[DEPTH-1:0]  e_reqs [NUM_REQS-1:0],
    output logic[DEPTH-1:0]  e_sels [NUM_REQS-1:0]
);

//
// Nets
//

logic[DEPTH-1:0]  e_elders_nxt [DEPTH-1:0];

//
// Logic
//

// Age matrix

for (genvar this_ent=0; this_ent<DEPTH; this_ent++) begin : g_this_ent
    for (genvar that_ent=0; that_ent<DEPTH; that_ent++) begin : g_that_ent
        // when an entry is allocated, all other entries are its elders
        // afterwards, when another entry is allocated, "that" entry is no longer "this" entry's elder
        assign e_elders_nxt[this_ent][that_ent] = ~reset
                                                & ~(this_ent == that_ent)
                                                & ( e_alloc[this_ent]                                 // set when allocated
                                                  | e_elders[this_ent][that_ent] & ~e_alloc[that_ent] // clear when other is allocated
                                                  );
    end
    `DFF(e_elders[this_ent], e_elders_nxt[this_ent], clk)
end

// Arbitration

for (genvar r=0; r<NUM_REQS; r++) begin : g_reqs
    for (genvar e=0; e<DEPTH; e++) begin : g_entries
        assign e_sels[r][e] = e_reqs[r][e] & ~|(e_reqs[r] & e_elders[e]);
    end
end

//
// Debug
//

`ifdef SIMULATION
`endif

`ifdef ASSERT
    // `VASSERT(push_when_full, push_front_xw0[0], ~full,  "Illegal AGE_MATRIX push when full")
    // `VASSERT(pop_when_empty, pop_back_xr0[0],   ~empty, "Illegal AGE_MATRIX pop when empty")
`endif

endmodule

`endif // __GEN_AGE_MATRIX_SV


