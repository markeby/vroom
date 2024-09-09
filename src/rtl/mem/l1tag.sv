`ifndef __L1TAG_SV
`define __L1TAG_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"
`include "mem_common.pkg"
`include "mem_defs.pkg"

module l1tag
    import instr::*, instr_decode::*, common::*, rob_defs::*, mem_defs::*, mem_common::*;
(
    input  logic              clk,
    input  logic              reset,

    input  logic              tag_rd_en_mm1,
    input  logic              tag_wr_en_mm1,
    input  t_l1_set_addr      set_addr_mm1,
    input  t_l1_tag           tag_wr_tag_mm1,
    input  t_l1_way           tag_wr_way_mm1,

    output t_l1_tag           tag_rd_ways_mm2[L1_NUM_WAYS-1:0]
);

//
// Nets
//

t_l1_tag tag_array [L1_NUM_SETS-1:0][L1_NUM_WAYS-1:0];

//
// Logic
//

always_ff @(posedge clk) begin
    if (tag_wr_en_mm1) begin
        tag_array[set_addr_mm1][tag_wr_way_mm1] <= tag_wr_tag_mm1;
    end
end

`DFF(tag_rd_ways_mm2, tag_array[set_addr_mm1], clk)

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

`endif // __L1TAG_SV


