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

logic      valid_de0;
t_rv_instr instr_de0;


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
    .uinstr_de1 ( )
);

regrd regrd (
    .clk,
    .reset
);

exe exe (
    .clk,
    .reset
);

mem mem (
    .clk,
    .reset
);

retire retire (
    .clk,
    .reset
);

endmodule

`endif // __CORE_SV
