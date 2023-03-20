`ifndef __CHK_NO_CHANGE_SV
`define __CHK_NO_CHANGE_SV

`include "instr.pkg"
`include "vroom_macros.sv"

module chk_no_change
    import instr::*, instr_decode::*;
    #(parameter type T=logic)
(
    input  logic clk,
    input  logic reset,
    input  logic hold,
    input  T     thing
);

T thing_dly;
`DFF(thing_dly, thing, clk)

logic hold_dly;
`DFF(hold_dly, hold, clk)

`VASSERT(a_did_not_hold, hold_dly, thing_dly == thing, "Hold requirement violated!")

endmodule

`endif // __CHK_NO_CHANGE_SV

