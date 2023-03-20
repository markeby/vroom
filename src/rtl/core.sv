`ifndef __CORE_SV
`define __CORE_SV

`include "instr.pkg"
`include "vroom_macros.sv"

module core
    import instr::*;
(
    input  logic clk,
    input  logic reset
);

//
// Nets
//

logic         valid_de0;
t_rv_instr    instr_de0;

logic         valid_rd0;
t_uinstr      uinstr_rd0;
logic         rdens_rd0   [1:0];
t_rv_reg_addr rdaddrs_rd0 [1:0];

t_rv_reg_data rddatas_rd1 [1:0];

logic         valid_ex0;
t_uinstr      uinstr_ex0;
t_rv_reg_data rddatas_ex0 [1:0];

t_uinstr      uinstr_mm0;
t_rv_reg_data result_mm0;

/*
logic         valid_mm0;
t_uinstr      uinstr_mm0;

logic         valid_rb0;
t_uinstr      uinstr_rb0;
*/

//
// Nets
//

fetch fetch (
    .clk,
    .reset,
    .valid_de0,
    .instr_de0,
    .stall_de1 ( 1'b0 )
);

decode decode (
    .clk,
    .reset,
    .valid_de0,
    .instr_de0,
    .valid_rd0,
    .uinstr_rd0
);

regrd regrd (
    .clk,
    .reset,
    .valid_rd0,
    .uinstr_rd0,
    .rdens_rd0,
    .rdaddrs_rd0,
    .rddatas_rd1,
    .valid_ex0,
    .uinstr_ex0,
    .rddatas_ex0
);

exe exe (
    .clk,
    .reset,
    .valid_ex0,
    .uinstr_ex0,
    .rddatas_ex0,
    .uinstr_mm0,
    .result_mm0
);

mem mem (
    .clk,
    .reset
);

retire retire (
    .clk,
    .reset
);

gprs gprs (
    .clk,
    .reset,

    .rden   ( rdens_rd0   ),
    .rdaddr ( rdaddrs_rd0 ),
    .rddata ( rddatas_rd1 ),

    .wren   ( '{0} ),
    .wraddr ( '{0} ),
    .wrdata ( '{0} )
);

endmodule

`endif // __CORE_SV
