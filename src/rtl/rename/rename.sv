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

    input  logic         valid_rn0,
    input  t_uinstr      uinstr_rn0,

    output logic         stall_rn0,

    input  logic         iprf_wr_en_ro0   [IPRF_NUM_WRITES-1:0],
    input  t_prf_wr_pkt  iprf_wr_pkt_ro0  [IPRF_NUM_WRITES-1:0],

    input  logic         iprf_rd_en_rd0   [IPRF_NUM_READS-1:0],
    input  t_prf_id      iprf_rd_psrc_rd0 [IPRF_NUM_READS-1:0],
    output t_rv_reg_data iprf_rd_data_rd1 [IPRF_NUM_READS-1:0],

    output logic         valid_rn1,
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

//
// Logic
//

assign alloc_pdst_rn0 = valid_rn0 & uinstr_rn0.dst.optype == OP_REG;

`DFF(valid_rn1,  valid_rn0,  clk)
`DFF(uinstr_rn1, uinstr_rn0, clk)

// PRFs

logic rdmap_nq_rd0 [IPRF_NUM_MAP_READS-1:0];
assign rdmap_nq_rd0[SRC1] = valid_rn0 & uinstr_rn0.src1.optype == OP_REG;
assign rdmap_nq_rd0[SRC2] = valid_rn0 & uinstr_rn0.src2.optype == OP_REG;

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
    .rdmap_psrc_rd0 ( {     rename_rn1.psrc2,           rename_rn1.psrc1} ) ,
    .rdmap_pend_rd0 ( {rename_rn1.psrc2_pend,      rename_rn1.psrc1_pend} ) ,

    `ifdef SIMULATION
    .simid_rn0_inst ( uinstr_rn0.SIMID ) ,
    .simid_rd0_inst ( uinstr_rn0.SIMID ) ,
    `endif
    .stall_rn0,

    .alloc_pdst_rn0,
    .gpr_id_rn0     ( uinstr_rn0.dst.opreg                           ) ,
    .pdst_rn0       ( rename_rn1.pdst                                )
);

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (uinstr_rn1.valid) begin
        `UINFO(uinstr_rn1.SIMID, ("unit:RN dst_type:%s dst_reg:%0d pdst:0x%0h src1_type:%s src1_reg:%0d psrc1:0x%0h psrc1_pend:%0d src2_type:%s src2_reg:%0d psrc2:0x%0h psrc2_pend:%d",
            uinstr_rn1.dst.optype.name, uinstr_rn1.dst.opreg, rename_rn1.pdst,
            uinstr_rn1.src1.optype.name, uinstr_rn1.src1.opreg, rename_rn1.psrc1, rename_rn1.psrc1_pend,
            uinstr_rn1.src2.optype.name, uinstr_rn1.src2.opreg, rename_rn1.psrc2, rename_rn1.psrc2_pend))
    end
end
`endif

`ifdef ASSERT
//VASSERT(a_br_mispred, uinstr_rd1.valid & ibr_resvld_ex0, ~ibr_mispred_ex0, "Branch mispredictions not yet supported.")
`endif

endmodule

`endif // __RENAME_SV

