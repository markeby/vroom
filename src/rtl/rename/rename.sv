`ifndef __RENAME_SV
`define __RENAME_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "common.pkg"
`include "vroom_macros.sv"
`include "rename_defs.pkg"
`include "verif.pkg"

module rename
   import instr::*, instr_decode::*, common::*, rename_defs::*, verif::*;
(
    input  logic         clk,
    input  logic         reset,
    input  t_nuke_pkt    nuke_rb1,
    input  t_rob_id      next_robid_rn0,

    input  logic         valid_rn0,
    input  t_uinstr      uinstr_rn0,
    output logic         rob_alloc_rn0,
    input  logic         rob_ready_rn0,

    output logic         rename_ready_rn0,
    input  logic         alloc_ready_ra0,

    input  logic         iprf_wr_en_ro0   [IPRF_NUM_WRITES-1:0],
    input  t_prf_wr_pkt  iprf_wr_pkt_ro0  [IPRF_NUM_WRITES-1:0],

    input  logic         iprf_rd_en_rd0   [IPRF_NUM_READS-1:0],
    input  t_prf_id      iprf_rd_psrc_rd0 [IPRF_NUM_READS-1:0],
    output t_rv_reg_data iprf_rd_data_rd1 [IPRF_NUM_READS-1:0],

    input  t_rat_reclaim_pkt rat_reclaim_pkt_rb1,
    input  t_rat_restore_pkt rat_restore_pkt_rbx,

    output logic         valid_rn1,
    output logic         rob_wr_rn1,
    output t_uinstr      uinstr_rn1,
    output t_rename_pkt  rename_rn1
);

localparam RN0 = 0;
localparam RN1 = 1;
localparam NUM_RN_STAGES = 1;

//
// Nets
//

logic         alloc_pdst_rn0;
`MKPIPE(t_rob_id, robid_rnx, RN0, NUM_RN_STAGES)

t_rename_pkt  rename_nq_rn1;
logic skid_full_rn1;
logic skid_empty_rn1;

logic valid_ql_rn0;

//
// Logic
//

assign valid_ql_rn0 = valid_rn0 & ~nuke_rb1.valid & rename_ready_rn0;

assign alloc_pdst_rn0 = valid_ql_rn0 & uinstr_rn0.dst.optype == OP_REG;
assign rob_alloc_rn0  = valid_ql_rn0;

`DFF(rob_wr_rn1,  valid_ql_rn0,  clk)

logic valid_nq_rn1;
assign valid_nq_rn1 = rob_wr_rn1 & ~nuke_rb1.valid;

t_uinstr uinstr_nq_rn1;
`DFF(uinstr_nq_rn1, uinstr_rn0, clk)

// PRFs

logic rdmap_nq_rd0 [IPRF_NUM_MAP_READS-1:0];
assign rdmap_nq_rd0[SRC1] = valid_rn0 & uinstr_rn0.src1.optype == OP_REG;
assign rdmap_nq_rd0[SRC2] = valid_rn0 & uinstr_rn0.src2.optype == OP_REG;

logic rename_ready_prf_rn0;

prf #(.NUM_ENTRIES(IPRF_NUM_ENTS), .NUM_REG_READS(IPRF_NUM_READS), .NUM_REG_WRITES(IPRF_NUM_WRITES), .NUM_MAP_READS(IPRF_NUM_MAP_READS)) iprf
(
    .clk,
    .reset,
    .prf_type       ( IPRF                                                ) ,

    .wr_en_nq_ro0   ( iprf_wr_en_ro0                                      ) ,
    .wr_pkt_ro0     ( iprf_wr_pkt_ro0                                     ) ,

    .rd_en_nq_rd0   ( iprf_rd_en_rd0                                      ) ,
    .rd_psrc_rd0    ( iprf_rd_psrc_rd0                                    ) ,
    .rd_data_rd1    ( iprf_rd_data_rd1                                    ) ,

    .rdmap_nq_rd0   ( {   rdmap_nq_rd0[SRC2],         rdmap_nq_rd0[SRC1]} ) ,
    .rdmap_gpr_rd0  ( {uinstr_rn0.src2.opreg,      uinstr_rn0.src1.opreg} ) ,
    .rdmap_psrc_rd1 ( {     rename_nq_rn1.psrc2,     rename_nq_rn1.psrc1} ) ,
    .rdmap_pend_rd1 ( {rename_nq_rn1.psrc2_pend,rename_nq_rn1.psrc1_pend} ) ,

    `ifdef SIMULATION
    .simid_rn0_inst ( uinstr_rn0.SIMID ) ,
    .simid_rd0_inst ( uinstr_rn0.SIMID ) ,
    `endif
    .rename_ready_rn0 ( rename_ready_prf_rn0 ) ,

    .rat_reclaim_pkt_rb1,
    .rat_restore_pkt_rbx,

    .alloc_pdst_rn0,
    .gpr_id_rn0     ( uinstr_rn0.dst.opreg                           ) ,
    .pdst_rn1       ( rename_nq_rn1.pdst                                ) ,
    .pdst_old_rn1   ( rename_nq_rn1.pdst_old                            )
);

assign robid_rnx[RN0] = next_robid_rn0;
assign rename_nq_rn1.robid = robid_rnx[RN1];

assign rename_ready_rn0 = rename_ready_prf_rn0 & rob_ready_rn0 & skid_empty_rn1;

// Skid FIFO

typedef struct packed {
    t_uinstr uinstr;
    t_rename_pkt rename;
} t_rn_skid_pkt;

t_rn_skid_pkt rn_skid_in_rn1;
t_rn_skid_pkt rn_skid_out_rn1;

assign rn_skid_in_rn1.uinstr = uinstr_nq_rn1;
assign rn_skid_in_rn1.rename = rename_nq_rn1;
assign uinstr_rn1 = rn_skid_out_rn1.uinstr;
assign rename_rn1 = rn_skid_out_rn1.rename;

gen_skid #(.DEPTH(2), .T(t_rn_skid_pkt)) skid (
    .clk,
    .reset     ( reset | nuke_rb1.valid ) ,
    .full      ( skid_full_rn1    ) ,
    .empty     ( skid_empty_rn1   ) ,
    .valid_xw0 ( valid_nq_rn1     ) ,
    .din_xw0   ( rn_skid_in_rn1   ) ,
    .hold_xr0  ( ~alloc_ready_ra0 ) ,
    .valid_xr0 ( valid_rn1        ) ,
    .dout_xr0  ( rn_skid_out_rn1  )
);

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (valid_rn1) begin
        `UINFO(uinstr_rn1.SIMID, ("unit:RN dst_type:%s dst_reg:%s pdst:%s pdst_old:%s, src1_type:%s src1_reg:%s psrc1:%s psrc1_pend:%0d src2_type:%s src2_reg:%s psrc2:%s psrc2_pend:%d",
            uinstr_rn1.dst.optype.name,  f_describe_gpr_addr(uinstr_rn1.dst.opreg ), f_describe_prf(rename_nq_rn1.pdst ), f_describe_prf(rename_nq_rn1.pdst_old),
            uinstr_rn1.src1.optype.name, f_describe_gpr_addr(uinstr_rn1.src1.opreg), f_describe_prf(rename_nq_rn1.psrc1), rename_nq_rn1.psrc1_pend,
            uinstr_rn1.src2.optype.name, f_describe_gpr_addr(uinstr_rn1.src2.opreg), f_describe_prf(rename_nq_rn1.psrc2), rename_nq_rn1.psrc2_pend))
    end
end
`endif

`ifdef ASSERT
//VASSERT(a_br_mispred, uinstr_rd1.valid & ibr_resvld_ex0, ~ibr_mispred_ex0, "Branch mispredictions not yet supported.")
`endif

endmodule

`endif // __RENAME_SV

