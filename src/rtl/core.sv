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

t_uinstr      uinstr_de1;
logic         rdens_rd0   [1:0];
t_rv_reg_addr rdaddrs_rd0 [1:0];

t_rv_reg_data rddatas_rd1 [1:0];

t_rv_reg_data result_ex1;

t_paddr       br_tgt_rb1;
logic         br_mispred_rb1;

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

logic         rs_stall_ports_rs0    [common::NUM_DISP_PORTS-1:0];
logic         disp_valid_ports_rs0  [common::NUM_DISP_PORTS-1:0];
t_uinstr_disp disp_ports_rs0        [common::NUM_DISP_PORTS-1:0];

logic         rs_stall_mm_rs0;
logic         disp_valid_mm_rs0;
t_uinstr_disp disp_mm_rs0;

logic         rs_stall_ex_rs0;
logic         disp_valid_ex_rs0;
t_uinstr_disp disp_ex_rs0;

assign disp_valid_mm_rs0                          = disp_valid_ports_rs0 [common::DISP_PORT_MEM ];
assign disp_mm_rs0                                = disp_ports_rs0       [common::DISP_PORT_MEM ];
assign rs_stall_ports_rs0[common::DISP_PORT_MEM ] = rs_stall_mm_rs0;

assign disp_valid_ex_rs0                          = disp_valid_ports_rs0 [common::DISP_PORT_EINT];
assign disp_ex_rs0                                = disp_ports_rs0       [common::DISP_PORT_EINT];
assign rs_stall_ports_rs0[common::DISP_PORT_EINT] = rs_stall_ex_rs0;

logic        eint_iss_rs1;
t_uinstr_iss eint_iss_pkt_rs1;

rs #(.NUM_RS_ENTS(8)) rs_exe (
    .clk,
    .reset,
    .ro_valid_rb0,
    .ro_result_rb0,
    .rs_stall_rs0 ( rs_stall_ex_rs0     ) ,
    .disp_valid_rs0 ( disp_valid_ex_rs0 ) ,
    .uinstr_rs0   ( disp_ex_rs0         ) ,
    .rddatas_rs0  ( rddatas_rd1         ) ,
    .iss_rs1      ( eint_iss_rs1        ) ,
    .iss_pkt_rs1  ( eint_iss_pkt_rs1    )
);

alloc alloc (
    .clk,
    .reset,
    .uinstr_de1,
    .next_robid_ra0,
    .rs_stall_ports_rs0,
    .disp_valid_ex_rs1,
    .disp_ex_rs1
);

regrd regrd (
    .clk,
    .reset,
    .br_mispred_rb1,
    .uinstr_de1,
    .rdens_rd0,
    .rdaddrs_rd0,
    .stall,
    .rddatas_rd1 ( rddatas_rd1 )
);

logic        ro_valid_rb0;
t_rob_result ro_result_rb0;
exe exe (
    .clk,
    .reset,
    .stall,
    .br_mispred_rb1,

    .iss_ex0      ( eint_iss_rs1        ) ,
    .iss_pkt_ex0  ( eint_iss_pkt_rs1    ) ,

    .ro_valid_ex1 ( ro_valid_rb0 ) ,
    .ro_result_ex1 (ro_result_rb0 )
);

mem mem (
    .clk,
    .reset,

    .iss_mm0     ( 1'b0             ) ,
    .iss_pkt_mm0 ( eint_iss_pkt_rs1 ) ,

    .result_mm1
);

retire retire (
    .clk,
    .reset,
    .next_robid_ra0,
    .uinstr_de1,

    .ro_valid_rb0,
    .ro_result_rb0,

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

`endif

endmodule

`endif // __CORE_SV
