`ifndef __MEMPIPE_SV
`define __MEMPIPE_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"
`include "mem_common.pkg"
`include "mem_defs.pkg"
`include "gen_funcs.pkg"

module mempipe
    import instr::*, instr_decode::*, common::*, rob_defs::*, gen_funcs::*, mem_defs::*, mem_common::*;
(
    input  logic            clk,
    input  logic            reset,
    input  t_nuke_pkt       nuke_rb1,

    input  logic            ld_req_mm0,
    input  t_mempipe_arb    ld_req_pkt_mm0,
    output logic            ld_gnt_mm0,

    input  logic            st_req_mm0,
    input  t_mempipe_arb    st_req_pkt_mm0,
    output logic            st_gnt_mm0,

    input  logic            fl_req_mm0,
    input  t_mempipe_arb    fl_req_pkt_mm0,
    output logic            fl_gnt_mm0,

    output t_l1_set_addr    set_addr_mm1,

    output logic            tag_rd_en_mm1,
    output logic            tag_wr_en_mm1,
    output t_l1_tag         tag_wr_tag_mm1,
    output t_l1_way         tag_wr_way_mm1,
    input  t_l1_tag         tag_rd_ways_mm2   [L1_NUM_WAYS-1:0],

    output logic            state_rd_en_mm1,
    output logic            state_wr_en_mm1,
    output t_mesi           state_wr_state_mm1,
    output t_l1_way         state_wr_way_mm1,
    input  t_mesi           state_rd_ways_mm2 [L1_NUM_WAYS-1:0],

    output logic            data_rd_en_mm1,
    output logic            data_wr_en_mm1,
    output t_cl             data_wr_data_mm1,
    output t_l1_way         data_wr_way_mm1,
    input  t_cl             data_rd_ways_mm2 [L1_NUM_WAYS-1:0],

    // FLQ CAM
    output t_mempipe_arb    req_pkt_mm1,

    // FLQ CAM
    input  logic            flq_addr_mat_mm2,

    output logic            valid_mm5,
    output t_mempipe_arb    req_pkt_mm5,
    output t_mempipe_action action_mm5,
    output logic            flq_alloc_mm5,

    output t_rob_complete_pkt complete_mm5,
    output logic              iprf_wr_en_mm5,
    output t_prf_wr_pkt       iprf_wr_pkt_mm5
);

/*

MM0 - Arbitration
MM1 - TLB (curently a passthru stage)
      Read tag   set
      Read state set
      Read data  set
      PA to FLQ CAM
MM2 - Calculate hit/miss
      FLQ CAM Match
MM3 - Data mux
MM4 - Data rotate
MM5 - Result valid

*/

//
// Nets
//

t_mempipe_arb req_pkt_mm0;
logic valid_mm0;

`MKPIPE_INIT(t_mempipe_arb,           req_pkt_mmx, req_pkt_mm0,             MM0, NUM_MM_STAGES)
`MKPIPE_INIT(logic,                   valid_mmx,   valid_mm0,               MM0, NUM_MM_STAGES)
`MKPIPE     (logic,                   is_ld_mmx,                            MM0, NUM_MM_STAGES)
`MKPIPE     (logic,                   is_fl_mmx,                            MM0, NUM_MM_STAGES)
`MKPIPE     (logic,                   is_st_mmx,                            MM0, NUM_MM_STAGES)
`MKPIPE     (logic,                   cacheable_mmx,                        MM0, NUM_MM_STAGES)
`MKPIPE     (t_paddr,                 paddr_mmx,                            MM1, NUM_MM_STAGES)
`MKPIPE     (logic,                   hit_mmx,                              MM2, NUM_MM_STAGES)
`MKPIPE     (logic[L1_NUM_WAYS-1:0],  hit_vec_mmx,                          MM2, NUM_MM_STAGES)
`MKPIPE     (t_cl[L1_NUM_WAYS-1:0],   rd_cl_data_set_mmx,                   MM2, NUM_MM_STAGES)
`MKPIPE_INIT(logic,                   flq_addr_mat_mmx, flq_addr_mat_mm2,   MM2, NUM_MM_STAGES)
`MKPIPE     (t_cl,                    rd_cl_data_mmx,                       MM3, NUM_MM_STAGES)
`MKPIPE     (t_rv_reg_data,           rd_cl_data_rot_mmx,                   MM4, NUM_MM_STAGES)

//
// Logic
//

    //
    // MM0
    // - Arbitration
    //

gen_arbiter #(.POLICY("FIND_FIRST"), .NREQS(3), .T(t_mempipe_arb)) pipe_arb (
    .clk,
    .reset,
    .int_req_valids ( {ld_req_mm0,     st_req_mm0,     fl_req_mm0    } ) ,
    .int_req_pkts   ( {ld_req_pkt_mm0, st_req_pkt_mm0, fl_req_pkt_mm0} ) ,
    .int_gnts       ( {ld_gnt_mm0,     st_gnt_mm0,     fl_gnt_mm0    } ) ,
    .ext_req_valid  ( valid_mm0          ) ,
    .ext_req_pkt    ( req_pkt_mm0        ) ,
    .ext_gnt        ( 1'b1               )
);

assign is_ld_mmx[MM0] = req_pkt_mm0.arb_type == MEM_LOAD;
assign is_st_mmx[MM0] = req_pkt_mm0.arb_type == MEM_STORE;
assign is_fl_mmx[MM0] = req_pkt_mm0.arb_type == MEM_FILL;
assign cacheable_mmx[MM0] = valid_mm0;

    //
    // MM1
    // - TLB (currently a passthru)
    // - Read tag   set
    // - Read state set
    // - Read data  set
    //

assign paddr_mmx[MM1]   = req_pkt_mmx[MM1].addr;
assign set_addr_mm1     = req_pkt_mmx[MM1].addr[L1_SET_HI:L1_SET_LO];

assign tag_rd_en_mm1    = valid_mmx[MM1] & cacheable_mmx[MM1] & ( is_ld_mmx[MM1] | is_st_mmx[MM1] );
assign tag_wr_en_mm1    = valid_mmx[MM1] & cacheable_mmx[MM1] & ( is_fl_mmx[MM1] );
assign tag_wr_tag_mm1   = req_pkt_mmx[MM1].addr[L1_TAG_HI:L1_TAG_LO];
assign tag_wr_way_mm1   = req_pkt_mmx[MM1].arb_way;

assign state_rd_en_mm1    = valid_mmx[MM1] & cacheable_mmx[MM1] & ( is_ld_mmx[MM1] | is_st_mmx[MM1] );
assign state_wr_en_mm1    = valid_mmx[MM1] & cacheable_mmx[MM1] & ( is_fl_mmx[MM1] );
assign state_wr_state_mm1 = MESI_E; // FIXME
assign state_wr_way_mm1   = req_pkt_mmx[MM1].arb_way;

assign data_rd_en_mm1    = valid_mmx[MM1] & cacheable_mmx[MM1] & ( is_ld_mmx[MM1] | is_st_mmx[MM1] );
assign data_wr_en_mm1    = valid_mmx[MM1] & cacheable_mmx[MM1] & ( is_fl_mmx[MM1] );
assign data_wr_data_mm1  = req_pkt_mmx[MM1].arb_data;
assign data_wr_way_mm1   = req_pkt_mmx[MM1].arb_way;

assign req_pkt_mm1 = req_pkt_mmx[MM1];

    //
    // MM2
    // - Calculate hit/miss
    //

for (genvar w=0; w<L1_NUM_WAYS; w++) begin : g_hit_vec
    assign hit_vec_mmx[MM2][w] = valid_mmx[MM2]
                               & cacheable_mmx[MM2]
                               & tag_rd_ways_mm2[w] == paddr_mmx[MM2][L1_TAG_HI:L1_TAG_LO]
                               & ( is_ld_mmx[MM2] & state_rd_ways_mm2[w] inside {MESI_M, MESI_E, MESI_S}
                                 | is_st_mmx[MM2] & state_rd_ways_mm2[w] inside {MESI_M, MESI_E        }
                                 );
    assign rd_cl_data_set_mmx[MM2][w] = data_rd_ways_mm2[w];
end
assign hit_mmx[MM2] = |hit_vec_mmx[MM2];

    //
    // MM3
    // - Data mux
    //

assign rd_cl_data_mmx[MM3] = mux_funcs#(.IWIDTH(L1_NUM_WAYS), .T(t_cl))::aomux(rd_cl_data_set_mmx[MM3], hit_vec_mmx[MM3]);

    //
    // MM4
    // - Data rotate
    //

always_comb begin
    t_cl_offset o;
    rd_cl_data_rot_mmx[MM4] = '0;
    o = paddr_mmx[MM4][L1_OFFSET_HI:L1_OFFSET_LO];;
    for (int b=0; b<8; b++) begin
        rd_cl_data_rot_mmx[MM4][8*b +: 8] = rd_cl_data_mmx[MM4].B[o];
        o += 1'b1;
    end
end

    //
    // MM5
    // - Result valid
    //

assign valid_mm5   = valid_mmx[MM5];
assign req_pkt_mm5 = req_pkt_mmx[MM5];
assign flq_alloc_mm5 = valid_mm5
                     & req_pkt_mmx[MM5].arb_type inside {MEM_LOAD, MEM_STORE}
                     & ~hit_mmx[MM5]
                     & ~flq_addr_mat_mmx[MM5];

always_comb begin
    action_mm5.complete = valid_mmx[MM5]
                        & ( (req_pkt_mmx[MM5].arb_type inside {MEM_LOAD} & hit_mmx[MM5])
                          | (req_pkt_mmx[MM5].arb_type inside {MEM_FILL}               )
                          );
    action_mm5.recycle  = valid_mmx[MM5] & ~action_mm5.complete;
end

always_comb begin
    complete_mm5.valid   = valid_mmx[MM5] & action_mm5.complete & req_pkt_mmx[MM5].arb_type inside {MEM_LOAD, MEM_STORE};
    complete_mm5.mispred = 1'b0;
    complete_mm5.robid   = req_pkt_mmx[MM5].robid;

    iprf_wr_en_mm5 = valid_mmx[MM5] & action_mm5.complete & req_pkt_mmx[MM5].arb_type inside {MEM_LOAD};
    iprf_wr_pkt_mm5 = '0;
    iprf_wr_pkt_mm5.pdst = req_pkt_mmx[MM5].pdst;
    iprf_wr_pkt_mm5.data = rd_cl_data_rot_mmx[MM5];
    `ifdef SIMULATION
    iprf_wr_pkt_mm5.SIMID = req_pkt_mmx[MM5].SIMID;
    `endif
end

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

`endif // __MEMPIPE_SV


