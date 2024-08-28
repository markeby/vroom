`ifndef __CORE_SV
`define __CORE_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "mem_common.pkg"
`include "common.pkg"
`include "vroom_macros.sv"

module core
    import instr::*, instr_decode::*, mem_common::*, common::*;
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

t_uinstr      uinstr_de1;
logic         rdens_rd0   [1:0];
t_rv_reg_addr rdaddrs_rd0 [1:0];

t_uinstr      uinstr_rd1;
t_rv_reg_data rddatas_rd1 [1:0];

t_uinstr      uinstr_ex1;
t_rv_reg_data result_ex1;

t_paddr       br_tgt_rb1;
logic         br_mispred_rb1;

t_uinstr      uinstr_mm1;
t_rv_reg_data result_mm1;

t_uinstr      uinstr_rb1;

logic             wren_rb1;
t_rv_reg_addr     wraddr_rb1;
t_rv_reg_data     wrdata_rb1;

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
    .uinstr_de1
);

t_rob_id next_robid_ra0;
alloc alloc (
    .clk,
    .reset,
    .uinstr_de1,
    .next_robid_ra0,
    .rs_stall_ex_rs0,
    .disp_valid_ex_rs1,
    .disp_ex_rs1,
    .rs_stall_mm_rs0,
    .disp_valid_mm_rs1,
    .disp_mm_rs1
);

regrd regrd (
    .clk,
    .reset,
    .br_mispred_rb1,
    .uinstr_de1,
    .rdens_rd0,
    .rdaddrs_rd0,
    .stall,
    .rddatas_rd1,
    .uinstr_rd1
);

exe exe (
    .clk,
    .reset,
    .stall,
    .br_mispred_rb1,
    .uinstr_rd1,
    .rddatas_rd1,
    .uinstr_ex1,
    .result_ex1
);

mem mem (
    .clk,
    .reset,
    .br_mispred_rb1,
    .uinstr_ex1,
    .result_ex1,
    .uinstr_mm1,
    .result_mm1
);

retire retire (
    .clk,
    .reset,
    .next_robid_ra0,
    .uinstr_de1,
    .uinstr_mm1,
    .result_mm1,
    .uinstr_rb1,
    .wren_rb1,
    .wraddr_rb1,
    .wrdata_rb1,
    .br_mispred_rb1,
    .br_tgt_rb1
);

gprs gprs (
    .clk,
    .reset,

    .rden   ( rdens_rd0   ),
    .rdaddr ( rdaddrs_rd0 ),
    .rddata ( rddatas_rd1 ),

    .wren   ( '{wren_rb1  } ),
    .wraddr ( '{wraddr_rb1} ),
    .wrdata ( '{wrdata_rb1} )
);

scoreboard scoreboard (
    .clk,
    .reset,
    .valid_fe1,
    .uinstr_de0,
    .uinstr_de1,
    .uinstr_rd1,
    .uinstr_ex1,
    .uinstr_mm1,
    .uinstr_rb1,
    .br_mispred_rb1,
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
chk_instr_progress #(.A("DE"), .B("RD")) chk_instr_progress_de (.clk, .br_mispred_rb1, .reset, .valid_stgA_nn0(uinstr_de1.valid), .simid_stgA_nn0(uinstr_de1.SIMID), .valid_stgB_nn0(uinstr_rd1.valid), .simid_stgB_nn0(uinstr_rd1.SIMID));
chk_instr_progress #(.A("RD"), .B("EX")) chk_instr_progress_rd (.clk, .br_mispred_rb1, .reset, .valid_stgA_nn0(uinstr_rd1.valid), .simid_stgA_nn0(uinstr_rd1.SIMID), .valid_stgB_nn0(uinstr_ex1.valid), .simid_stgB_nn0(uinstr_ex1.SIMID));
chk_instr_progress #(.A("EX"), .B("MM")) chk_instr_progress_ex (.clk, .br_mispred_rb1, .reset, .valid_stgA_nn0(uinstr_ex1.valid), .simid_stgA_nn0(uinstr_ex1.SIMID), .valid_stgB_nn0(uinstr_mm1.valid), .simid_stgB_nn0(uinstr_mm1.SIMID));
chk_instr_progress #(.A("MM"), .B("RB")) chk_instr_progress_mm (.clk, .br_mispred_rb1, .reset, .valid_stgA_nn0(uinstr_mm1.valid), .simid_stgA_nn0(uinstr_mm1.SIMID), .valid_stgB_nn0(uinstr_rb1.valid), .simid_stgB_nn0(uinstr_rb1.SIMID));

`endif

endmodule

`endif // __CORE_SV
