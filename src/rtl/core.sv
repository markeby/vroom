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
logic         rob_ready_ra0;

logic         valid_fe1;
t_instr_pkt   instr_fe1;
t_uinstr      uinstr_de0;

logic         alloc_ra0;

logic         valid_rn1;
t_uinstr      uinstr_rn1;
t_rename_pkt  rename_rn1;

logic         valid_de1;
t_uinstr      uinstr_de1;
logic         rdens_rd0   [1:0];
t_prf_id      rdaddrs_rd0 [1:0];

t_rv_reg_data rddatas_rd1 [1:0];

logic            resume_fetch_rbx;
t_nuke_pkt       nuke_rb1;
t_br_mispred_pkt br_mispred_ex0;
t_rv_reg_data result_ex1;

logic        iprf_wr_en_ex1;
t_prf_wr_pkt iprf_wr_pkt_ex1;

logic         reclaim_prf_rb1;
t_prf_id      reclaim_prf_id_rb1;

t_rv_reg_data result_mm1;

t_rv_reg_addr     src_addr_ra0          [NUM_SOURCES-1:0];
logic             rob_src_reg_pdg_ra0   [NUM_SOURCES-1:0];
t_rob_id          rob_src_reg_robid_ra0 [NUM_SOURCES-1:0];

t_rob_id          oldest_robid;

t_rat_restore_pkt rat_restore_pkt_rbx;

// icache

t_mem_req fb_ic_req_nnn;
t_mem_rsp ic_fb_rsp_nnn;

//
// Nets
//

fetch fetch (
    .clk,
    .reset,
    .decode_ready_de0,
    .fb_ic_req_nnn,
    .ic_fb_rsp_nnn,
    .br_mispred_ex0,
    .valid_fe1,
    .instr_fe1,
    .nuke_rb1,
    .resume_fetch_rbx
);

decode decode (
    .clk,
    .reset,
    .nuke_rb1,

    .valid_fe1,
    .decode_ready_de0,
    .rename_ready_rn0,
    .instr_fe1,
    .uinstr_de0,
    .valid_de1,
    .uinstr_de1
);

rename rename (
    .clk,
    .reset,
    .nuke_rb1,

    .alloc_ready_ra0,
    .rename_ready_rn0,

    .valid_rn0 ( uinstr_de1.valid ) ,
    .uinstr_rn0 ( uinstr_de1 ) ,

    .iprf_wr_en_ro0   ( '{iprf_wr_en_ex1} ),
    .iprf_wr_pkt_ro0  ( '{iprf_wr_pkt_ex1} ),

    .iprf_rd_en_rd0   ( rdens_rd0 ),
    .iprf_rd_psrc_rd0 ( rdaddrs_rd0 ),
    .iprf_rd_data_rd1 ( rddatas_rd1 ),

    .reclaim_prf_rb1,
    .reclaim_prf_id_rb1,
    .rat_restore_pkt_rbx,

    .valid_rn1,
    .uinstr_rn1,
    .rename_rn1
);

t_rob_id next_robid_ra0;

logic         rs_stall_mm_rs0;
logic         disp_valid_mm_rs0;
t_uinstr_disp disp_mm_rs0;

logic         rs_stall_ex_rs0;
logic         disp_valid_ex_rs0;
t_uinstr_disp disp_ex_rs0;

logic        eint_iss_rs2;
t_uinstr_iss eint_iss_pkt_rs2;

alloc alloc (
    .clk,
    .reset,
    .nuke_rb1,
    .alloc_ready_ra0,
    .alloc_ra0,
    .uinstr_ra0 ( uinstr_rn1 ),
    .rename_ra0 ( rename_rn1 ),
    .rob_ready_ra0,
    .next_robid_ra0,
    .rs_stall_ex_rs0,
    .src_addr_ra0,
    .rob_src_reg_pdg_ra0,
    .rob_src_reg_robid_ra0,
    .disp_valid_ex_rs0,
    .disp_ex_rs0
);

rs #(.NUM_RS_ENTS(8), .RS_NAME("RS_EINT")) rs_eint (
    .clk,
    .reset,
    .nuke_rb1,
    .iprf_wr_en_ro0   ( '{iprf_wr_en_ex1} ),
    .iprf_wr_pkt_ro0  ( '{iprf_wr_pkt_ex1} ),

    .rs_stall_rs0 ( rs_stall_ex_rs0     ) ,
    .disp_valid_rs0 ( disp_valid_ex_rs0 ) ,
    .uinstr_rs0   ( disp_ex_rs0         ) ,
    .prf_rdens_rd0 ( rdens_rd0 ) ,
    .prf_rdaddrs_rd0 ( rdaddrs_rd0 ) ,
    .prf_rddatas_rd1 ( rddatas_rd1 ) ,
    .iss_rs2      ( eint_iss_rs2        ) ,
    .iss_pkt_rs2  ( eint_iss_pkt_rs2    )
);

logic        ro_valid_rb0;
t_rob_result ro_result_rb0;
exe exe (
    .clk,
    .reset,
    .nuke_rb1,
    .br_mispred_ex0,

    .iss_ex0      ( eint_iss_rs2        ) ,
    .iss_pkt_ex0  ( eint_iss_pkt_rs2    ) ,

    .iprf_wr_en_ex1,
    .iprf_wr_pkt_ex1,

    .ro_valid_ex1 ( ro_valid_rb0 ) ,
    .ro_result_ex1 (ro_result_rb0 )
);

mem mem (
    .clk,
    .reset,
    .nuke_rb1,

    .iss_mm0     ( 1'b0             ) ,
    .iss_pkt_mm0 ( eint_iss_pkt_rs2 ) ,

    .result_mm1
);

rob rob (
    .clk,
    .reset,
    .oldest_robid,
    .rob_ready_ra0,
    .uinstr_ra0 ( uinstr_rn1 ),
    .rename_ra0 ( rename_rn1 ),
    .alloc_ra0,

    .src_addr_ra0,
    .rob_src_reg_pdg_ra0,
    .rob_src_reg_robid_ra0,

    .ro_valid_rb0,
    .ro_result_rb0,

    .reclaim_prf_rb1,
    .reclaim_prf_id_rb1,
    .rat_restore_pkt_rbx,

    .next_robid_ra0,

    .uinstr_rb1 ( ),

    .nuke_rb1,
    .resume_fetch_rbx
);

icache #(.LATENCY(5)) icache (
    .clk,
    .reset,
    .fb_ic_req_nnn,
    .ic_fb_rsp_nnn
);

`ifdef ASSERT

coredebug coredebug (.clk, .reset);

`endif

endmodule

`endif // __CORE_SV
