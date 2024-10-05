`ifndef __CHICKEN_SV
`define __CHICKEN_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "gen_funcs.pkg"

module chicken
    import gen_funcs::*, common::*;
(
    input  logic         clk,
    input  logic         reset,

    output t_chicken_bits chicken_bits
);

chicken_bit #(.NAME("dis_br_pred"), .WIDTH(1)) cb_dis_br_pred ( .o(chicken_bits.dis_br_pred) );

endmodule

`endif // __CHICKEN_SV
