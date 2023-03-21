`ifndef __CORE_SV
`define __CORE_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "mem_common.pkg"
`include "vroom_macros.sv"

module core
    import instr::*, instr_decode::*, mem_common::*;
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

t_uinstr      uinstr_mm1;
t_rv_reg_data result_mm1;

logic             wren_rb0;
t_rv_reg_addr     wraddr_rb0;
t_rv_reg_data     wrdata_rb0;

// icache

t_mem_req fe_ic_req_nnn;
t_mem_rsp ic_fe_rsp_nnn;

//
// Nets
//

fetch fetch (
    .clk,
    .reset,
    .fe_ic_req_nnn,
    .ic_fe_rsp_nnn,
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

icache icache (
    .clk,
    .reset,
    .fe_ic_req_nnn,
    .ic_fe_rsp_nnn
);

`ifdef ASSERT
    /*
    `define MK_REG_COLLISION_ASRT(STAGELC,SRCN) \
        `VASSERT(a_collision_ex_``STAGELC``_``SRCN``, uinstr_rd1.valid & uinstr_rd1.dst.optype == OP_REG & uinstr_``STAGELC``0.valid & uinstr_``STAGELC``0.src``SRCN``.optype == OP_REG, uinstr_rd1.dst.opreg != uinstr_``STAGELC``0.src``SRCN``.opreg , $sformatf("Register collision! rd.dst <-> STAGELC.src%-d", SRCN))
    `MK_REG_COLLISION_ASRT(mm,1)
    `MK_REG_COLLISION_ASRT(mm,2)
    `MK_REG_COLLISION_ASRT(rb,1)
    `MK_REG_COLLISION_ASRT(rb,2)
    */
`endif

endmodule

`endif // __CORE_SV
