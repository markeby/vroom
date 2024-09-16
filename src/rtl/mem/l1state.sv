`ifndef __L1STATE_SV
`define __L1STATE_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"
`include "mem_common.pkg"
`include "mem_defs.pkg"

module l1state
    import instr::*, instr_decode::*, common::*, rob_defs::*, mem_defs::*, mem_common::*;
(
    input  logic              clk,
    input  logic              reset,

    input  logic              state_rd_en_mm1,
    input  t_l1_set_addr      set_addr_mm1,

    output t_mesi             state_rd_ways_mm2[L1_NUM_WAYS-1:0],

    input  t_l1_set_addr      set_addr_mm3,
    input  logic              state_wr_en_mm3,
    input  t_mesi             state_wr_state_mm3,
    input  t_l1_way           state_wr_way_mm3
);

//
// Nets
//

t_mesi state_array [L1_NUM_SETS-1:0][L1_NUM_WAYS-1:0];

//
// Logic
//

always_ff @(posedge clk) begin
    if (state_wr_en_mm3) begin
        state_array[set_addr_mm3][state_wr_way_mm3] <= state_wr_state_mm3;
    end
end

`DFF(state_rd_ways_mm2, state_array[set_addr_mm1], clk)

//
// Debug
//

`ifdef SIMULATION
// always @(posedge clk) begin
//     if (iss_mm0) begin
//         `INFO(("unit:MM %s", describe_uinstr(iss_pkt_mm0.uinstr)))
//     end
// end
`endif

    /*
`ifdef ASSERT
`VASSERT(a_illegal_format, uinstr_de1.valid, uinstr_de1.ifmt inside {RV_FMT_I,RV_FMT_R}, $sformatf("Unsupported instr fmt: %s", uinstr_de1.ifmt.name()))
`endif
    */

endmodule

`endif // __L1STATE_SV


