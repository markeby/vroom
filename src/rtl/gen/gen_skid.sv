`ifndef __GEN_SKID_SV
`define __GEN_SKID_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "gen_funcs.pkg"
`include "common.pkg"
`include "verif.pkg"

module gen_skid
    import gen_funcs::*, common::*, verif::*;
#(parameter int DEPTH=2, type T=logic, string NAME = "GENERIC_SKID")
(
    input  logic             clk,
    input  logic             reset,

    output logic             full,
    output logic             empty,

    input  logic             valid_xw0,
    input  T                 din_xw0,

    input  logic             hold_xr0,
    output logic             valid_xr0,
    output T                 dout_xr0
);

localparam DEPTH_LG2=$clog2(DEPTH);

//
// Nets
//

T skid_dout_xr0;
logic pop_back_xr0;
logic push_front_xw0;
logic skid_valid_xr0;

//
// Logic
//

gen_fifo #(.DEPTH(DEPTH), .NPUSH(1), .NPOP(1), .T(T), .NAME(NAME)) fifo (
    .clk,
    .reset,

    .full,
    .empty,

    .num_push_ok ( ),

    .push_front_xw0 ( '{push_front_xw0} ),
    .din_xw0        ( '{din_xw0} ) ,

    .pop_back_xr0   ( '{pop_back_xr0 } ),
    .valid_xr0      ( '{skid_valid_xr0 } ),
    .dout_xr0       ( '{skid_dout_xr0} )
);

assign push_front_xw0 = valid_xw0 & (hold_xr0 | skid_valid_xr0);
assign pop_back_xr0 = skid_valid_xr0 & ~hold_xr0;
assign valid_xr0 = skid_valid_xr0 | valid_xw0;
assign dout_xr0 = skid_valid_xr0 ? skid_dout_xr0 : din_xw0;

//
// Debug
//

`ifdef SIMULATION
`endif

`ifdef ASSERT
    // `VASSERT(push_when_full, push_front_xw0[0], ~full,  "Illegal SKID push when full")
    // `VASSERT(pop_when_empty, pop_back_xr0[0],   ~empty, "Illegal SKID pop when empty")
`endif

endmodule

`endif // __GEN_SKID_SV


