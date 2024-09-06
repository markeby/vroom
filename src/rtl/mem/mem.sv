`ifndef __MEM_SV
`define __MEM_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"

module mem
    import instr::*, instr_decode::*, common::*, rob_defs::*;
(
    input  logic         clk,
    input  logic         reset,
    input  t_nuke_pkt    nuke_rb1,

    input  logic         iss_mm0,
    input  t_uinstr_iss  iss_pkt_mm0,

    output t_rob_complete_pkt complete_mm5
);

localparam MM0 = 0;
localparam MM1 = 1;
localparam NUM_MM_STAGES = 1;

//
// Nets
//

//
// Logic
//

//
// MM0
//

//
// MM1/RB0
//

// RB0 assign

always_comb begin
    complete_mm5 = '0;
end


//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (iss_mm0) begin
        `INFO(("unit:MM %s", describe_uinstr(iss_pkt_mm0.uinstr)))
    end
end
`endif

    /*
`ifdef ASSERT
`VASSERT(a_illegal_format, uinstr_de1.valid, uinstr_de1.ifmt inside {RV_FMT_I,RV_FMT_R}, $sformatf("Unsupported instr fmt: %s", uinstr_de1.ifmt.name()))
`endif
    */

endmodule

`endif // __MEM_SV


