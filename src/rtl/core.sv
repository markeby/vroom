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

t_paddr       br_tgt_ex0;
logic         br_mispred_ex0;

t_uinstr      uinstr_mm1;
t_rv_reg_data result_mm1;

logic             wren_rb0;
t_rv_reg_addr     wraddr_rb0;
t_rv_reg_data     wrdata_rb0;

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
    .stall
);

decode decode (
    .clk,
    .reset,

    .valid_fe1,
    .stall,
    .instr_fe1,
    .uinstr_de0,
    .uinstr_de1
);

regrd regrd (
    .clk,
    .reset,
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
    .uinstr_rd1,
    .rddatas_rd1,
    .br_tgt_ex0,
    .br_mispred_ex0,
    .uinstr_ex1,
    .result_ex1
);

mem mem (
    .clk,
    .reset,
    .uinstr_ex1,
    .result_ex1,
    .uinstr_mm1,
    .result_mm1
);

retire retire (
    .clk,
    .reset,
    .uinstr_mm1,
    .result_mm1,
    .wren_rb0,
    .wraddr_rb0,
    .wrdata_rb0
);

gprs gprs (
    .clk,
    .reset,

    .rden   ( rdens_rd0   ),
    .rdaddr ( rdaddrs_rd0 ),
    .rddata ( rddatas_rd1 ),

    .wren   ( '{wren_rb0  } ),
    .wraddr ( '{wraddr_rb0} ),
    .wrdata ( '{wrdata_rb0} )
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
    .stall
);

icache #(.LATENCY(5)) icache (
    .clk,
    .reset,
    .fb_ic_req_nnn,
    .ic_fb_rsp_nnn
);

`ifdef ASSERT

chk_instr_progress #(.A("FE"), .B("DE")) chk_instr_progress_fe (.clk, .reset, .valid_stgA_nn0(valid_fe1       ), .simid_stgA_nn0(instr_fe1.SIMID ), .valid_stgB_nn0(uinstr_de1.valid), .simid_stgB_nn0(uinstr_de1.SIMID));
chk_instr_progress #(.A("DE"), .B("RD")) chk_instr_progress_de (.clk, .reset, .valid_stgA_nn0(uinstr_de1.valid), .simid_stgA_nn0(uinstr_de1.SIMID), .valid_stgB_nn0(uinstr_rd1.valid), .simid_stgB_nn0(uinstr_rd1.SIMID));
chk_instr_progress #(.A("RD"), .B("EX")) chk_instr_progress_rd (.clk, .reset, .valid_stgA_nn0(uinstr_rd1.valid), .simid_stgA_nn0(uinstr_rd1.SIMID), .valid_stgB_nn0(uinstr_ex1.valid), .simid_stgB_nn0(uinstr_ex1.SIMID));
chk_instr_progress #(.A("EX"), .B("MM")) chk_instr_progress_ex (.clk, .reset, .valid_stgA_nn0(uinstr_ex1.valid), .simid_stgA_nn0(uinstr_ex1.SIMID), .valid_stgB_nn0(uinstr_mm1.valid), .simid_stgB_nn0(uinstr_mm1.SIMID));

`endif

endmodule

`endif // __CORE_SV
