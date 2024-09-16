`ifndef __CDIFF_SV
`define __CDIFF_SV

`include "instr.pkg"
`include "asm.pkg"
`include "mem_common.pkg"
`include "mem_defs.pkg"
`include "vroom_macros.sv"
`include "sim/cache_sim.pkg"

module cdiff
    import instr::*, asm::*, mem_defs::*, mem_common::*, common::*, cache_sim::*;
(
    input  logic      clk,
    input  logic      reset
);

`define L1_MEMPIPE_PEEK(T,S) \
    T S; \
    assign S = core.mem.mempipe.``S``;

`define L1_MEMPIPE_PEEK_RENAME(T,S,ORIG) \
    T S; \
    assign S = core.mem.mempipe.``ORIG``;

    `L1_MEMPIPE_PEEK(logic    , tag_rd_en_mm1)
    `L1_MEMPIPE_PEEK(logic    , tag_wr_en_mm1)
    `L1_MEMPIPE_PEEK(t_l1_tag , tag_wr_tag_mm1)
    `L1_MEMPIPE_PEEK(t_l1_way , tag_wr_way_mm1)
    //`L1_MEMPIPE_PEEK(t_l1_tag , tag_rd_ways_mm2)

    `L1_MEMPIPE_PEEK(logic    , state_rd_en_mm1)
    `L1_MEMPIPE_PEEK(logic    , state_wr_en_mm3)
    `L1_MEMPIPE_PEEK(t_mesi   , state_wr_state_mm3)
    `L1_MEMPIPE_PEEK(t_l1_way , state_wr_way_mm3)
    //`L1_MEMPIPE_PEEK(t_mesi   , state_rd_ways_mm2)

    `L1_MEMPIPE_PEEK(logic    , data_rd_en_mm1)
    `L1_MEMPIPE_PEEK(logic    , data_wr_en_mm3)
    `L1_MEMPIPE_PEEK(t_cl     , data_wr_data_mm3)
    `L1_MEMPIPE_PEEK(t_l1_way , data_wr_way_mm3)
    //`L1_MEMPIPE_PEEK(t_cl     , data_rd_ways_mm2)

    `L1_MEMPIPE_PEEK_RENAME(t_paddr, paddr_mm4, paddr_mmx[MM4])
    `L1_MEMPIPE_PEEK_RENAME(t_mempipe_arb, req_pkt_mm4, req_pkt_mmx[MM4])

function automatic void f_print_diff_set_way(string arb_type, t_l1_set_addr set, t_l1_way way);
    t_paddr paddr;
    t_mesi  mesi;
    t_cl    data;

    paddr[L1_TAG_HI:L1_TAG_LO] = core.mem.l1tag.tag_array[set][way];
    paddr[L1_SET_HI:L1_SET_LO] = set;
    paddr[L1_SET_LO-1:0] = '0;

    mesi = core.mem.l1state.state_array[set][way];

    data = core.mem.l1data.data_array[set][way];

    `PMSG(CDIFF, ("s%s w%s / %s %s / %s (%s)", f_format_set(set), f_format_way(way), mesi.name(), f_format_paddr(paddr), f_format_cl_data(data), arb_type));
endfunction

`MKPIPE_INIT(logic, tag_wr_en_mmx,   tag_wr_en_mm1,   MM1, NUM_MM_STAGES);
`MKPIPE_INIT(logic, state_wr_en_mmx, state_wr_en_mm3, MM3, NUM_MM_STAGES);
`MKPIPE_INIT(logic, data_wr_en_mmx,  data_wr_en_mm3,  MM3, NUM_MM_STAGES);

always @(posedge clk) begin
    if (!reset) begin
        if (tag_wr_en_mmx[MM4] | state_wr_en_mmx[MM4] | data_wr_en_mmx[MM4]) begin
            f_print_diff_set_way(req_pkt_mm4.arb_type.name(), paddr_mm4[L1_SET_HI:L1_SET_LO], req_pkt_mm4.arb_way);
        end
    end
end


endmodule

`endif // __CDIFF_SV


