`ifndef __MEMPIPE_SV
`define __MEMPIPE_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"
`include "mem_common.pkg"
`include "mem_defs.pkg"
`include "gen_funcs.pkg"

module mempipe
    import instr::*, instr_decode::*, common::*, rob_defs::*, gen_funcs::*, mem_defs::*, mem_common::*, verif::*;
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
    output t_l1_set_addr    set_addr_mm3,

    output logic            tag_rd_en_mm1,
    output logic            tag_wr_en_mm1,
    output t_l1_tag         tag_wr_tag_mm1,
    output t_l1_way         tag_wr_way_mm1,
    input  t_l1_tag         tag_rd_ways_mm2   [L1_NUM_WAYS-1:0],

    output logic            state_rd_en_mm1,
    input  t_mesi           state_rd_ways_mm2 [L1_NUM_WAYS-1:0],

    output logic            data_rd_en_mm1,
    input  t_cl             data_rd_ways_mm2 [L1_NUM_WAYS-1:0],

    output logic            state_wr_en_mm3,
    output t_mesi           state_wr_state_mm3,
    output t_l1_way         state_wr_way_mm3,

    output logic            data_wr_en_mm3,
    output t_cl             data_wr_data_mm3,
    output t_cl_be          data_wr_be_mm3,
    output t_l1_way         data_wr_way_mm3,

    output t_mempipe_stuff  mempipe_stuff_mm2,
    input  logic[STQ_NUM_ENTRIES-1:0]
                            stq_e_addr_match_mm2,

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
      Write data
MM4 - Data rotate
MM5 - Result valid

*/

//
// Nets
//

t_mempipe_arb req_pkt_mm0;
logic valid_mm0;
logic[NUM_MM_STAGES:MM1] valid_mmx;
logic[NUM_MM_STAGES:MM0] valid_ql_mmx;

`MKPIPE_INIT(t_mempipe_arb,           req_pkt_mmx, req_pkt_mm0,             MM0, NUM_MM_STAGES)
`MKPIPE     (logic,                   is_ld_mmx,                            MM0, NUM_MM_STAGES)
`MKPIPE     (logic,                   is_fl_mmx,                            MM0, NUM_MM_STAGES)
`MKPIPE     (logic,                   is_st_mmx,                            MM0, NUM_MM_STAGES)
`MKPIPE     (logic,                   cacheable_mmx,                        MM0, NUM_MM_STAGES)
`MKPIPE     (t_paddr,                 paddr_mmx,                            MM1, NUM_MM_STAGES)
`MKPIPE     (logic,                   hit_mmx,                              MM2, NUM_MM_STAGES)
`MKPIPE     (t_l1_way,                hit_way_mmx,                          MM2, NUM_MM_STAGES)
`MKPIPE     (logic[L1_NUM_WAYS-1:0],  hit_vec_mmx,                          MM2, NUM_MM_STAGES)
`MKPIPE     (t_cl[L1_NUM_WAYS-1:0],   rd_cl_data_set_mmx,                   MM2, NUM_MM_STAGES)
`MKPIPE_INIT(logic,                   flq_addr_mat_mmx, flq_addr_mat_mm2,   MM2, NUM_MM_STAGES)
`MKPIPE_INIT(logic,                   flq_alloc_mmx,    flq_alloc_mm6,      MM6, NUM_MM_STAGES)
`MKPIPE     (t_cl,                    rd_cl_data_mmx,                       MM3, NUM_MM_STAGES)
`MKPIPE     (t_rv_reg_data,           rd_cl_data_rot_mmx,                   MM4, NUM_MM_STAGES)
`MKPIPE     (logic,                   older_stq_mat_mmx,                    MM2, NUM_MM_STAGES)

//
// Logic
//

`DFF(valid_mmx[MM9:MM1], valid_ql_mmx[MM8:MM0], clk)

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
assign valid_ql_mmx[MM0] = valid_mm0 & ~(req_pkt_mm0.nukeable & nuke_rb1.valid);

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

assign state_rd_en_mm1  = valid_mmx[MM1] & cacheable_mmx[MM1] & ( is_ld_mmx[MM1] | is_st_mmx[MM1] );

assign data_rd_en_mm1   = valid_mmx[MM1] & cacheable_mmx[MM1] & ( is_ld_mmx[MM1] | is_st_mmx[MM1] );

assign req_pkt_mm1 = req_pkt_mmx[MM1];

assign valid_ql_mmx[MM1] = valid_mmx[MM1] & ~(req_pkt_mmx[MM1].nukeable & nuke_rb1.valid);

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
assign hit_way_mmx[MM2] = gen_lg2_funcs#(.IWIDTH(L1_NUM_WAYS))::oh_encode(hit_vec_mmx[MM2]);

assign valid_ql_mmx[MM2] = valid_mmx[MM2] & ~(req_pkt_mmx[MM2].nukeable & nuke_rb1.valid);

always_comb begin
    mempipe_stuff_mm2.valid    = valid_mmx[MM2];
    mempipe_stuff_mm2.arb_type = req_pkt_mmx[MM2].arb_type;
    mempipe_stuff_mm2.paddr    = paddr_mmx[MM2];
end

assign older_stq_mat_mmx[MM2] = |(req_pkt_mmx[MM2].older_stq_ents & stq_e_addr_match_mm2);

    //
    // MM3
    // - Data mux
    // - Data write
    //

assign rd_cl_data_mmx[MM3] = mux_funcs#(.IWIDTH(L1_NUM_WAYS), .T(t_cl))::aomux(rd_cl_data_set_mmx[MM3], hit_vec_mmx[MM3]);

assign set_addr_mm3     = req_pkt_mmx[MM3].addr[L1_SET_HI:L1_SET_LO];

assign data_wr_en_mm3    = valid_mmx[MM3] & cacheable_mmx[MM3]
                         & ( is_fl_mmx[MM3]
                           | is_st_mmx[MM3] & req_pkt_mmx[MM3].phase.st == MEM_ST_FINAL & hit_mmx[MM3]);
assign data_wr_data_mm3  = req_pkt_mmx[MM3].arb_data;
assign data_wr_way_mm3   = req_pkt_mmx[MM3].arb_way;
assign data_wr_be_mm3    = req_pkt_mmx[MM3].byte_en;

assign state_wr_en_mm3    = valid_mmx[MM3] & cacheable_mmx[MM3]
                          & ( is_fl_mmx[MM3]
                            | is_st_mmx[MM3] & req_pkt_mmx[MM3].phase.st == MEM_ST_FINAL & hit_mmx[MM3]);
assign state_wr_state_mm3 = is_fl_mmx[MM3] ? MESI_E : MESI_M;
assign state_wr_way_mm3   = is_fl_mmx[MM3] ? req_pkt_mmx[MM3].arb_way : hit_way_mmx[MM3];

assign valid_ql_mmx[MM3] = valid_mmx[MM3] & ~(req_pkt_mmx[MM3].nukeable & nuke_rb1.valid);

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

assign valid_ql_mmx[MM4] = valid_mmx[MM4] & ~(req_pkt_mmx[MM4].nukeable & nuke_rb1.valid);

    //
    // MM5
    // - Result valid
    //

logic flq_alloc_mm6;
`DFF(flq_alloc_mm6, flq_alloc_mm5, clk)
// uh, verilator inferring circular path if I use MM5..MM8... so just stage directly to MM6 myself

assign valid_mm5   = valid_mmx[MM5];
assign req_pkt_mm5 = req_pkt_mmx[MM5];
assign flq_alloc_mm5 = valid_mm5
                     & req_pkt_mmx[MM5].arb_type inside {MEM_LOAD, MEM_STORE}
                     & ~hit_mmx[MM5]
                     & ~flq_addr_mat_mmx[MM5]
                     & ~( valid_mmx[MM6] & flq_alloc_mmx[MM6] & req_pkt_mmx[MM5].addr[PA_SZ-1:6] == req_pkt_mmx[MM6].addr[PA_SZ-1:6]
                        | valid_mmx[MM7] & flq_alloc_mmx[MM7] & req_pkt_mmx[MM5].addr[PA_SZ-1:6] == req_pkt_mmx[MM7].addr[PA_SZ-1:6]
                        | valid_mmx[MM8] & flq_alloc_mmx[MM8] & req_pkt_mmx[MM5].addr[PA_SZ-1:6] == req_pkt_mmx[MM8].addr[PA_SZ-1:6]
                        | valid_mmx[MM9] & flq_alloc_mmx[MM9] & req_pkt_mmx[MM5].addr[PA_SZ-1:6] == req_pkt_mmx[MM9].addr[PA_SZ-1:6]
                        );

always_comb begin
    action_mm5.complete      = 1'b0;
    action_mm5.recycle       = 1'b0;
    action_mm5.recycle_cause = '0;

    unique casez ({valid_mmx[MM5], req_pkt_mmx[MM5].arb_type})
        //
        // Loads
        //
        {1'b1, MEM_LOAD }: begin
            action_mm5.recycle_cause.mat_stq = older_stq_mat_mmx[MM5];
            action_mm5.recycle_cause.miss    = ~hit_mmx[MM5];
            action_mm5.recycle               = |action_mm5.recycle_cause;
            action_mm5.complete              = ~action_mm5.recycle;
        end

        //
        // Fills
        //
        {1'b1, MEM_FILL }: begin
            action_mm5.recycle_cause = '0;
            action_mm5.recycle  = |action_mm5.recycle_cause;
            action_mm5.complete = ~action_mm5.recycle;
        end

        //
        // Stores
        //
        {1'b1, MEM_STORE}: begin
            unique casez(req_pkt_mmx[MM5].phase.st)
                MEM_ST_INITIAL: action_mm5.complete = 1'b1;
                MEM_ST_FINAL: begin
                    action_mm5.recycle_cause.miss = ~hit_mmx[MM5];
                    action_mm5.recycle            = |action_mm5.recycle_cause;
                    action_mm5.complete           = ~action_mm5.recycle;
                end
            endcase
        end

        default: begin
            if (valid_mmx[MM5]) $error("Unexpected transaction");
        end
    endcase
end

always_comb begin
    complete_mm5.valid   = 1'b0;
    unique casez (req_pkt_mmx[MM5].arb_type)
        MEM_LOAD:  complete_mm5.valid = action_mm5.complete;
        MEM_STORE: complete_mm5.valid = action_mm5.complete & req_pkt_mmx[MM5].phase.st == MEM_ST_INITIAL;
        default:   complete_mm5.valid = 1'b0;
    endcase
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

assign valid_ql_mmx[MM5] = valid_mmx[MM5] & ~(req_pkt_mmx[MM5].nukeable & nuke_rb1.valid);

//
// Etc
//

for (genvar mmx=MM6; mmx<=NUM_MM_STAGES; mmx++) begin : g_valid_pipe
    assign valid_ql_mmx[mmx] = valid_mmx[mmx] & ~(req_pkt_mmx[mmx].nukeable & nuke_rb1.valid);
end

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (valid_ql_mmx[MM5]) begin
        `UINFO(req_pkt_mmx[MM5].SIMID , ("unit:MEMPIPE func:action arb_type:%s id:%0d complete:%0d recycle:%0d miss:%0d mat_stq:%0d",
            req_pkt_mmx[MM5].arb_type.name, req_pkt_mmx[MM5].id, action_mm5.complete, action_mm5.recycle, action_mm5.recycle_cause.miss, action_mm5.recycle_cause.mat_stq))
    end
end
`endif

    /*
`ifdef ASSERT
`VASSERT(a_illegal_format, uinstr_de1.valid, uinstr_de1.ifmt inside {RV_FMT_I,RV_FMT_R}, $sformatf("Unsupported instr fmt: %s", uinstr_de1.ifmt.name()))
`endif
    */

endmodule

`endif // __MEMPIPE_SV


