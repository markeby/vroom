`ifndef __CORE_SV
`define __CORE_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "vroom_macros.sv"

module core
    import instr::*, instr_decode::*;
(
    input  logic clk,
    input  logic reset
);

//
// Nets
//

logic         stall;

logic         fe_valid_de0;
t_rv_instr    instr_de0;
t_uinstr      uinstr_de0;

t_uinstr      uinstr_rd0;
logic         rdens_rd0   [1:0];
t_rv_reg_addr rdaddrs_rd0 [1:0];

t_rv_reg_data rddatas_rd1 [1:0];

t_uinstr      uinstr_ex0;
t_rv_reg_data rddatas_ex0 [1:0];

t_uinstr      uinstr_mm0;
t_rv_reg_data result_mm0;

t_uinstr      uinstr_rb0;
t_rv_reg_data result_rb0;

logic             wren_rb0;
t_rv_reg_addr     wraddr_rb0;
t_rv_reg_data     wrdata_rb0;

//
// Nets
//

fetch fetch (
    .clk,
    .reset,
    .fe_valid_de0,
    .instr_de0,
    .stall
);

decode decode (
    .clk,
    .reset,

    .fe_valid_de0,
    .stall,
    .instr_de0,
    .uinstr_de0,
    .uinstr_rd0
);

regrd regrd (
    .clk,
    .reset,
    .uinstr_rd0,
    .rdens_rd0,
    .rdaddrs_rd0,
    .stall,
    .rddatas_rd1,
    .uinstr_ex0,
    .rddatas_ex0
);

exe exe (
    .clk,
    .reset,
    .stall,
    .uinstr_nq_ex0 ( uinstr_ex0 ),
    .rddatas_ex0,
    .uinstr_mm0,
    .result_mm0
);

mem mem (
    .clk,
    .reset,
    .uinstr_mm0,
    .result_mm0,
    .uinstr_rb0,
    .result_rb0
);

retire retire (
    .clk,
    .reset,
    .uinstr_rb0,
    .result_rb0,
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
    .fe_valid_de0,
    .uinstr_de0,
    .uinstr_rd0,
    .uinstr_ex0,
    .uinstr_mm0,
    .uinstr_rb0,

    .stall
);

`ifdef ASSERT
    /*
    `define MK_REG_COLLISION_ASRT(STAGELC,SRCN) \
        `VASSERT(a_collision_ex_``STAGELC``_``SRCN``, uinstr_ex0.valid & uinstr_ex0.dst.optype == OP_REG & uinstr_``STAGELC``0.valid & uinstr_``STAGELC``0.src``SRCN``.optype == OP_REG, uinstr_ex0.dst.opreg != uinstr_``STAGELC``0.src``SRCN``.opreg , $sformatf("Register collision! rd.dst <-> STAGELC.src%-d", SRCN))
    `MK_REG_COLLISION_ASRT(mm,1)
    `MK_REG_COLLISION_ASRT(mm,2)
    `MK_REG_COLLISION_ASRT(rb,1)
    `MK_REG_COLLISION_ASRT(rb,2)
    */
`endif

endmodule

`endif // __CORE_SV
