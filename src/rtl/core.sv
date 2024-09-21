`ifndef __CORE_SV
`define __CORE_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "mem_common.pkg"
`include "rename_defs.pkg"
`include "common.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"

module core
    import instr::*, instr_decode::*, mem_common::*, common::*, rob_defs::*, rename_defs::*;
(
    input  logic clk,
    input  logic reset
);

//
// Nets
//

logic         decode_ready_de0;
logic         rename_ready_rn0;
logic         alloc_ready_ra0;
logic         rob_ready_rn0;

logic         valid_fe1;
t_instr_pkt   instr_fe1;

logic         valid_rn1;
logic         rob_wr_rn1;
t_uinstr      uinstr_rn1;
t_rename_pkt  rename_rn1;

logic         valid_de1;
t_uinstr      uinstr_de1;
logic         rdens_rd0   [1:0];
t_prf_id      rdaddrs_rd0 [1:0];

t_rv_reg_data rddatas_rd1 [1:0];

logic         valid_uc0;
t_uinstr      uinstr_uc0;

logic            resume_fetch_rbx;
t_nuke_pkt       nuke_rb1;
t_br_mispred_pkt br_mispred_ex0;

t_rob_id next_robid_rn0;

logic         rs_stall_rs0;
logic         disp_valid_rs0;
t_disp_pkt    disp_pkt_rs0;
t_stq_id      stqid_alloc_rs0;
t_ldq_id      ldqid_alloc_rs0;

logic        ex_iss_rs2;
t_iss_pkt ex_iss_pkt_rs2;

logic        mm_iss_rs2;
t_iss_pkt mm_iss_pkt_rs2;

logic        iprf_wr_en_ex1;
t_prf_wr_pkt iprf_wr_pkt_ex1;

logic        iprf_wr_en_mm5;
t_prf_wr_pkt iprf_wr_pkt_mm5;

t_rob_complete_pkt ex_complete_rb0;;
t_rob_complete_pkt mm_complete_rb0;;

t_gpr_id          src_addr_ra0          [NUM_SOURCES-1:0];
logic             rob_src_reg_pdg_ra0   [NUM_SOURCES-1:0];
t_rob_id          rob_src_reg_robid_ra0 [NUM_SOURCES-1:0];

t_rob_id          oldest_robid;

t_rat_restore_pkt rat_restore_pkt_rbx;
t_rat_reclaim_pkt rat_reclaim_pkt_rb1;

t_mem_req_pkt  ic_l2_req_pkt;
t_mem_rsp_pkt  l2_ic_rsp_pkt;

logic ldq_idle;
logic stq_idle;

logic ldq_full;
logic stq_full;

//
// Blocks
//

fe fe (
    .clk,
    .reset,
    .oldest_robid,
    .ic_l2_req_pkt,
    .l2_ic_rsp_pkt,
    .decode_ready_de0,
    .br_mispred_ex0,
    .valid_fe1,
    .instr_fe1,
    .nuke_rb1,
    .resume_fetch_rbx
);

logic ucode_ready_uc0;
decode decode (
    .clk,
    .reset,
    .nuke_rb1,

    .valid_fe1,
    .decode_ready_de0,
    .ucode_ready_uc0,
    .instr_fe1,
    .valid_de1,
    .uinstr_de1
);

ucode ucode (
    .clk,
    .reset,
    .nuke_rb1,
    .rename_ready_rn0,

    .valid_de1,
    .uinstr_de1,
    .ucode_ready_uc0,

    .valid_uc0,
    .uinstr_uc0
);

logic rob_alloc_rn0;
rename rename (
    .clk,
    .reset,
    .nuke_rb1,
    .next_robid_rn0,

    .alloc_ready_ra0,
    .rename_ready_rn0,
    .rob_ready_rn0,
    .rob_alloc_rn0,

    .valid_rn0 ( valid_uc0 ) ,
    .uinstr_rn0 ( uinstr_uc0 ) ,

    .iprf_wr_en_ro0   ( '{iprf_wr_en_ex1,  iprf_wr_en_mm5}  ),
    .iprf_wr_pkt_ro0  ( '{iprf_wr_pkt_ex1, iprf_wr_pkt_mm5} ),

    .iprf_rd_en_rd0   ( rdens_rd0 ),
    .iprf_rd_psrc_rd0 ( rdaddrs_rd0 ),
    .iprf_rd_data_rd1 ( rddatas_rd1 ),

    .rat_restore_pkt_rbx,
    .rat_reclaim_pkt_rb1,

    .valid_rn1,
    .rob_wr_rn1,
    .uinstr_rn1,
    .rename_rn1
);

alloc alloc (
    .clk,
    .reset,
    .nuke_rb1,
    .alloc_ready_ra0,
    .ldq_full,
    .stq_full,
    .valid_ra0  ( valid_rn1  ),
    .uinstr_ra0 ( uinstr_rn1 ),
    .rename_ra0 ( rename_rn1 ),
    .rs_stall_rs0,
    .src_addr_ra0,
    .rob_src_reg_pdg_ra0,
    .rob_src_reg_robid_ra0,
    .stqid_alloc_rs0,
    .ldqid_alloc_rs0,
    .disp_valid_rs0,
    .disp_pkt_rs0
);

rs #(.NUM_RS_ENTS(8), .RS_NAME("RS0")) rs (
    .clk,
    .reset,
    .nuke_rb1,
    .ldq_idle,
    .stq_idle,
    .oldest_robid,

    .iprf_wr_en_ro0   ( '{iprf_wr_en_ex1, iprf_wr_en_mm5} ),
    .iprf_wr_pkt_ro0  ( '{iprf_wr_pkt_ex1, iprf_wr_pkt_mm5} ),

    .rs_stall_rs0,
    .disp_valid_rs0,
    .disp_pkt_rs0,

    .prf_rdens_rd0 ( rdens_rd0 ) ,
    .prf_rdaddrs_rd0 ( rdaddrs_rd0 ) ,
    .prf_rddatas_rd1 ( rddatas_rd1 ) ,

    .ex_iss_rs2,
    .ex_iss_pkt_rs2,

    .mm_iss_rs2,
    .mm_iss_pkt_rs2
);

exe exe (
    .clk,
    .reset,
    .nuke_rb1,
    .br_mispred_ex0,

    .iss_ex0      ( ex_iss_rs2        ) ,
    .iss_pkt_ex0  ( ex_iss_pkt_rs2    ) ,

    .iprf_wr_en_ex1,
    .iprf_wr_pkt_ex1,

    .complete_ex1 (ex_complete_rb0)
);

t_mem_req_pkt      dc_l2_req_pkt;
t_mem_rsp_pkt      l2_dc_rsp_pkt;

mem mem (
    .clk,
    .reset,
    .nuke_rb1,
    .oldest_robid,
    .ldq_idle,
    .stq_idle,
    .ldq_full,
    .stq_full,

    .disp_valid_rs0,
    .disp_pkt_rs0,
    .stqid_alloc_rs0,
    .ldqid_alloc_rs0,

    .flq_mem_req_pkt ( dc_l2_req_pkt ) ,
    .flq_mem_rsp_pkt ( l2_dc_rsp_pkt ) ,

    .iss_mm0      ( mm_iss_rs2      ) ,
    .iss_pkt_mm0  ( mm_iss_pkt_rs2  ) ,

    .iprf_wr_en_mm5,
    .iprf_wr_pkt_mm5,

    .complete_mm5 ( mm_complete_rb0 )
);

l2 l2 (
    .clk,
    .reset,

    .dc_l2_req_pkt,
    .l2_dc_rsp_pkt,

    .ic_l2_req_pkt,
    .l2_ic_rsp_pkt
);

rob rob (
    .clk,
    .reset,
    .oldest_robid,
    .rob_ready_rn0,
    .rob_alloc_rn0,
    .uinstr_rn0 ( uinstr_uc0 ),

    .rob_wr_rn1,
    .rename_rn1,

    .src_addr_ra0,
    .rob_src_reg_pdg_ra0,
    .rob_src_reg_robid_ra0,

    .ex_complete_rb0,
    .mm_complete_rb0,

    .rat_reclaim_pkt_rb1,
    .rat_restore_pkt_rbx,

    .next_robid_rn0,

    .uinstr_rb1 ( ),

    .nuke_rb1,
    .resume_fetch_rbx
);

`ifdef ASSERT

coredebug coredebug (.clk, .reset);
preload preload (.clk, .reset);
cdiff cdiff (.clk, .reset);

`endif

endmodule

`endif // __CORE_SV
