`ifndef __RENAME_SV
`define __RENAME_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "common.pkg"
`include "vroom_macros.sv"
`include "rename_defs.pkg"

module rename
   import instr::*, instr_decode::*, common::*, rename_defs::*;
(
    input  logic         clk,
    input  logic         reset,

    input  logic         valid_rn0,
    input  t_uinstr      uinstr_rn0,

    output logic         stall_rn0,

    input  logic         iprf_wr_en_ro0,

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

// PRFs

prf #(.NUM_ENTRIES(IPRF_NUM_ENTS), .NUM_READS(IPRF_NUM_READS), .NUM_WRITES(IPRF_NUM_WRITES)) iprf
(
    .clk,
    .reset,
    .prf_type       ( IPRF                                                ) ,

    .wren_nq_ro0    ( iprf_wren_ro0                                       ) ,
    .wr_pdst_ro0    ( iprf_wr_pdst_ro0                                    ) ,
    .wr_data_ro0    ( iprf_wr_data_ro0                                    ) ,

    .rden_nq_rd0    ( iprf_rd_en_rd0                                      ) ,
    .rd_psrc_rd0    ( iprf_rd_psrc_rd0                                    ) ,
    .rd_data_rd1    ( iprf_rd_data_rd1                                    ) ,

    .rdmap_nq_rd0   ( {                 1'b1,                       1'b1} ) ,
    .rdmap_gpr_rd0  ( {uinstr_rn0.src2.opreg,      uinstr_rn0.src1.opreg} ) ,
    .rdmap_psrc_rd0 ( {     rename_rn1.psrc2,           rename_rn1.psrc1} ) ,
    .rdmap_pend_rd0 ( {rename_rn1.psrc2_pend,      rename_rn1.psrc1_pend} ) ,

    .stall_rn0,

    .alloc_pdst_rn0,
    .gpr_id_rn0     ( uinstr_rn0.dst.opreg                           ) ,
    .pdst_rn0       ( rename_rn1.pdst                                )
);

//
// Debug
//

`ifdef SIMULATION
// always @(posedge clk) begin
//     if (uinstr_ra1.valid) begin
//         `INFO(("unit:RA %s", describe_uinstr(uinstr_ra1)))
//     end
// end
`endif

`ifdef ASSERT
//VASSERT(a_br_mispred, uinstr_rd1.valid & ibr_resvld_ex0, ~ibr_mispred_ex0, "Branch mispredictions not yet supported.")
`endif

endmodule

`endif // __RENAME_SV

