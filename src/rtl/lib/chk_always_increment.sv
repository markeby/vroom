`ifndef __CHK_ALWAYS_INCREMENT_SV
`define __CHK_ALWAYS_INCREMENT_SV

`include "instr.pkg"
`include "vroom_macros.sv"

module chk_always_increment
    #(parameter type T=logic, logic CONSECUTIVE=0, int INCR_BY=1)
(
    input  logic clk,
    input  logic reset,
    input  logic valid,
    input  T     count
);

T     last_count;
logic last_count_valid;

`DFF_EN(last_count, count, clk, valid)
`DFF(last_count_valid, valid | ~reset & last_count_valid, clk)

if (CONSECUTIVE) begin
    `VASSERT(a_not_mono_incr, valid & last_count_valid, count == last_count+INCR_BY, "Count is not monotically incrementing!")
end else begin
    `VASSERT(a_not_mono_incr, valid & last_count_valid, count > last_count, "Count is not monotically incrementing!")
end

endmodule

`endif // __CHK_ALWAYS_INCREMENT_SV

