`ifndef __PEND_WATCHER_SV
`define __PEND_WATCHER_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "common.pkg"
`include "vroom_macros.sv"
`include "verif.pkg"

module pend_watcher
   import instr::*, instr_decode::*, common::*, verif::*;
(
    input  logic         iprf_wr_en_ro0   [IPRF_NUM_WRITES-1:0],
    input  t_prf_wr_pkt  iprf_wr_pkt_ro0  [IPRF_NUM_WRITES-1:0],

    input  t_rename_pkt  i_rename_pkt,
    output t_rename_pkt  o_rename_pkt
);

//
// Logic
//

always_comb begin
    o_rename_pkt = i_rename_pkt;
    for (int w=0; w<IPRF_NUM_WRITES; w++) begin
        o_rename_pkt.psrc1_pend &= ~(iprf_wr_en_ro0[w] & iprf_wr_pkt_ro0[w].pdst == i_rename_pkt.psrc1);
        o_rename_pkt.psrc2_pend &= ~(iprf_wr_en_ro0[w] & iprf_wr_pkt_ro0[w].pdst == i_rename_pkt.psrc2);
    end
end

//
// Debug
//

`ifdef SIMULATION
`endif

`ifdef ASSERT
`endif

endmodule

`endif // __PEND_WATCHER_SV

