`ifndef __CORE_SV
`define __CORE_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "mem_common.pkg"
`include "common.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"

module core
    import instr::*, instr_decode::*, mem_common::*, common::*, rob_defs::*;
(
    input  logic clk,
    input  logic reset
);

//
// Nets
//

logic         stall;

logic         valid_fe1;
t_instr_pkt   instr_fe1;
t_uinstr      uinstr_de0;

logic         valid_rn1;
t_uinstr      uinstr_rn1;
t_rename_pkt  rename_rn1;

logic         valid_de1;
t_uinstr      uinstr_de1;
logic         rdens_rd0   [1:0];
t_prf_id      rdaddrs_rd0 [1:0];

t_rv_reg_data rddatas_rd1 [1:0];

t_rv_reg_data result_ex1;

logic        iprf_wr_en_ex1;
t_prf_wr_pkt iprf_wr_pkt_ex1;

t_paddr       br_tgt_rb1;
logic         br_mispred_rb1;

logic         reclaim_prf_rb1;
t_prf_id      reclaim_prf_id_rb1;

t_rv_reg_data result_mm1;

t_rv_reg_addr     src_addr_ra0          [NUM_SOURCES-1:0];
logic             rob_src_reg_pdg_ra0   [NUM_SOURCES-1:0];
t_rob_id          rob_src_reg_robid_ra0 [NUM_SOURCES-1:0];

// icache

t_mem_req fb_ic_req_nnn;
t_mem_rsp ic_fb_rsp_nnn;

//
// Nets
//

fetch fetch (
    .clk,
    .reset,
    .fb_ic_req_nnn,
    .ic_fb_rsp_nnn,
    .valid_fe1,
    .instr_fe1,
    .br_tgt_rb1,
    .br_mispred_rb1,
    .stall
);

decode decode (
    .clk,
    .reset,
    .br_mispred_rb1,

    .valid_fe1,
    .stall,
    .instr_fe1,
    .uinstr_de0,
    .valid_de1,
    .uinstr_de1
);

rename rename (
    .clk,
    .reset,

    .valid_rn0 ( uinstr_de1.valid ) ,
    .uinstr_rn0 ( uinstr_de1 ) ,

    .stall_rn0 ( ),

    .iprf_wr_en_ro0   ( '{iprf_wr_en_ex1} ),
    .iprf_wr_pkt_ro0  ( '{iprf_wr_pkt_ex1} ),

    .iprf_rd_en_rd0   ( rdens_rd0 ),
    .iprf_rd_psrc_rd0 ( rdaddrs_rd0 ),
    .iprf_rd_data_rd1 ( rddatas_rd1 ),

    .reclaim_prf_rb1,
    .reclaim_prf_id_rb1,

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
    .uinstr_ra0 ( uinstr_rn1 ),
    .rename_ra0 ( rename_rn1 ),
    .stall_ra0 ( ),
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
    .stall,
    .br_mispred_rb1,

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

    .iss_mm0     ( 1'b0             ) ,
    .iss_pkt_mm0 ( eint_iss_pkt_rs2 ) ,

    .result_mm1
);

retire retire (
    .clk,
    .reset,
    .next_robid_ra0,
    .uinstr_ra0 ( uinstr_rn1 ),
    .rename_ra0 ( rename_rn1 ),

    .src_addr_ra0,
    .rob_src_reg_pdg_ra0,
    .rob_src_reg_robid_ra0,

    .ro_valid_rb0,
    .ro_result_rb0,

    .reclaim_prf_rb1,
    .reclaim_prf_id_rb1,

    .br_mispred_rb1,
    .br_tgt_rb1
);

scoreboard scoreboard (
    .clk,
    .reset,
    .stall
);

icache #(.LATENCY(5)) icache (
    .clk,
    .reset,
    .fb_ic_req_nnn,
    .ic_fb_rsp_nnn
);

`ifdef ASSERT

chk_instr_progress #(.A("FE"), .B("DE")) chk_instr_progress_fe (.clk, .br_mispred_rb1, .reset, .valid_stgA_nn0(valid_fe1       ), .simid_stgA_nn0(instr_fe1.SIMID ), .valid_stgB_nn0(uinstr_de1.valid), .simid_stgB_nn0(uinstr_de1.SIMID));

coredebug coredebug (.clk, .reset);

`endif

endmodule

`endif // __CORE_SV
