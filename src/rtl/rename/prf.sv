`ifndef __PRF_SV
`define __PRF_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "common.pkg"
`include "vroom_macros.sv"
`include "rename_defs.pkg"
`include "gen_funcs.pkg"
`include "verif.pkg"

module prf
   import instr::*, instr_decode::*, common::*, rename_defs::*, gen_funcs::*, verif::*;
#(parameter int NUM_ENTRIES=8, parameter int NUM_REG_READS=2, parameter int NUM_REG_WRITES=1, parameter int NUM_MAP_READS=2)
(
    input  logic         clk,
    input  logic         reset,
    input  t_prf_type    prf_type,

    input  logic         wr_en_nq_ro0 [NUM_REG_WRITES-1:0],
    input  t_prf_wr_pkt  wr_pkt_ro0   [NUM_REG_WRITES-1:0],

    input  logic         rd_en_nq_rd0 [NUM_REG_READS-1:0],
    input  t_prf_id      rd_psrc_rd0  [NUM_REG_READS-1:0],
    output t_rv_reg_data rd_data_rd1  [NUM_REG_READS-1:0],

    input  logic         rdmap_nq_rd0   [NUM_MAP_READS-1:0],
    input  t_gpr_id      rdmap_gpr_rd0  [NUM_MAP_READS-1:0],
    output t_prf_id      rdmap_psrc_rd1 [NUM_MAP_READS-1:0],
    output logic         rdmap_pend_rd1 [NUM_MAP_READS-1:0],

    input  logic         reclaim_prf_rb1,
    input  t_prf_id      reclaim_prf_id_rb1,
    input  t_rat_restore_pkt rat_restore_pkt_rbx,

    output logic         rename_ready_rn0,

    input  logic         alloc_pdst_rn0,
    input  t_gpr_id      gpr_id_rn0,
    `ifdef SIMULATION
    input  t_simid       simid_rn0_inst,
    input  t_simid       simid_rd0_inst,
    `endif
    output t_prf_id      pdst_rn1,
    output t_prf_id      pdst_old_rn1
);

localparam RN0 = 0;
localparam RN1 = 1;
localparam NUM_RN_STAGES = 1;

//
// Nets
//

t_rv_reg_data          PRF        [NUM_ENTRIES-1:0];
t_prf_addr             MAP        [RV_NUM_REGS-1:0];
logic[NUM_ENTRIES-1:0] free_list;
logic[NUM_ENTRIES-1:0] pend_list;

//
// Logic
//

//
// Free list
//

logic[NUM_ENTRIES-1:0] free_list_first_free_rn0;
assign free_list_first_free_rn0 = gen_funcs#(.IWIDTH(NUM_ENTRIES))::find_first1(free_list);

logic[NUM_ENTRIES-1:0] free_list_reclaim_rb1;
assign free_list_reclaim_rb1 = (reclaim_prf_rb1 & reclaim_prf_id_rb1.ptype == prf_type) ? (1 << reclaim_prf_id_rb1.idx) : '0;

logic reclaim_ro0;
assign reclaim_ro0 = 1'b0;  // FIXME

logic[NUM_ENTRIES-1:0] free_list_rst;
logic[NUM_ENTRIES-1:0] free_list_nxt;

assign free_list_nxt = (  free_list
                       & ~(alloc_pdst_rn0 ? free_list_first_free_rn0 : '0)
                       )
                     | free_list_reclaim_rb1;

always_comb begin
    free_list_rst = '1;
    for (int i=0; i<RV_NUM_REGS; i++) begin
        free_list_rst[i] = 1'b0;
    end
end

`DFF(free_list, reset ? free_list_rst : free_list_nxt, clk)

assign rename_ready_rn0 = |free_list;

t_prf_id      pdst_rn0;
t_prf_id      pdst_old_rn0;
always_comb begin
    pdst_rn0.ptype = prf_type;
    pdst_rn0.idx  = gen_funcs#(.IWIDTH(NUM_ENTRIES))::oh_encode(free_list_first_free_rn0);

    pdst_old_rn0.ptype = prf_type;
    pdst_old_rn0.idx   = MAP[gpr_id_rn0];
end

`DFF(pdst_rn1, pdst_rn0, clk);
`DFF(pdst_old_rn1, pdst_old_rn0, clk);

//
// Pend list
//

logic[NUM_ENTRIES-1:0] pend_list_nxt;
logic[NUM_ENTRIES-1:0] prf_wrs_dec_ro0;
always_comb begin
    prf_wrs_dec_ro0 = '0;
    for (int w=0; w<NUM_REG_WRITES; w++) begin
        prf_wrs_dec_ro0[wr_pkt_ro0[w].pdst.idx] |= wr_en_nq_ro0[w] & wr_pkt_ro0[w].pdst.ptype == prf_type;
    end
end

assign pend_list_nxt = ( pend_list
                       | (alloc_pdst_rn0 ? free_list_first_free_rn0 : '0))
                     & ~prf_wrs_dec_ro0;
`DFF(pend_list, reset ? '0 : pend_list_nxt, clk)

//
// Mapping table
//

t_prf_addr map_tbl_rst [RV_NUM_REGS-1:0];
for (genvar g=0; g<RV_NUM_REGS; g++) begin : g_gpr_loop
    assign map_tbl_rst[g] = t_prf_addr'(g);
end

always_ff @(posedge clk) begin
    if (reset) begin
        MAP <= map_tbl_rst;
    end else if(rat_restore_pkt_rbx.valid) begin
        MAP[rat_restore_pkt_rbx.gpr] <= rat_restore_pkt_rbx.prfid.idx;
    end else if(alloc_pdst_rn0) begin
        MAP[gpr_id_rn0] <= pdst_rn0.idx;
    end
end

t_prf_id      rdmap_psrc_rd0 [NUM_MAP_READS-1:0];
logic         rdmap_pend_rd0 [NUM_MAP_READS-1:0];
for (genvar r=0; r<NUM_MAP_READS; r++) begin : g_map_read
    assign rdmap_psrc_rd0[r].ptype = prf_type;
    assign rdmap_psrc_rd0[r].idx   = MAP[rdmap_gpr_rd0[r]];
    assign rdmap_pend_rd0[r]       = pend_list_nxt[rdmap_psrc_rd0[r].idx];
end

`DFF(rdmap_psrc_rd1, rdmap_psrc_rd0, clk);
`DFF(rdmap_pend_rd1, rdmap_pend_rd0, clk);

//
// PRF data
//

always_ff @(posedge clk) begin
    if (reset) begin
        for (int i=0; i<NUM_ENTRIES; i++) begin
            PRF[i] <= '0;
        end
    end else begin
        for (int w=0; w<NUM_REG_WRITES; w++) begin
            if (wr_en_nq_ro0[w] & wr_pkt_ro0[w].pdst.ptype == prf_type) begin
                PRF[wr_pkt_ro0[w].pdst.idx] <= wr_pkt_ro0[w].data;
            end
        end
    end
end

for (genvar r=0; r<NUM_REG_READS; r++) begin : g_prf_rd
    `DFF(rd_data_rd1[r], PRF[rd_psrc_rd0[r].idx], clk)
end

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (alloc_pdst_rn0) begin
        `UINFO(simid_rn0_inst, ("unit:RN func:pdst_alloc gpr_id:0x%0x pdst:0x%0x", gpr_id_rn0, pdst_rn0))
    end

    for (int r=0; r<NUM_MAP_READS; r++) begin
        if (rdmap_nq_rd0[r]) begin
            `UINFO(simid_rd0_inst, ("unit:RN func:rat_read gpr_id:0x%0x psrc:0x%0x psrc_pend:%0d", rdmap_gpr_rd0[r], rdmap_psrc_rd0[r], rdmap_pend_rd0[r]))
        end
    end
end

localparam FAIL_DLY = 10;
logic[FAIL_DLY:0] boom_pipe;
`DFF(boom_pipe[FAIL_DLY:1], boom_pipe[FAIL_DLY-1:0], clk);

always @(posedge clk) begin
    boom_pipe[0] <= 1'b0;
    // if (uinstr_mm1.valid) begin
    //     `INFO(("unit:RB %s result:%08h", describe_uinstr(uinstr_mm1), result_mm1))
    //     print_retire_info(uinstr_mm1);
    // end

    // for (int w=0; w<NUM_REG_WRITES; w++) begin
    //     if (wr_en_nq_ro0[w] & /*wraddr_rb1 == 0 &*/ wr_pkt_ro0[w].data == 64'h666) begin
    //         `INFO(("Saw write of 666 to SOME register... goodbye, folks!"))
    //         boom_pipe[0] <= 1'b1;
    //     end
    // end

    if (boom_pipe[FAIL_DLY]) begin
        $finish();
        $finish();
        $finish();
    end
end
`endif

`ifdef ASSERT
//VASSERT(a_br_mispred, uinstr_rd1.valid & ibr_resvld_ex0, ~ibr_mispred_ex0, "Branch mispredictions not yet supported.")
`endif

endmodule

`endif // __PRF_SV

