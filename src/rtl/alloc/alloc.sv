`ifndef __ALLOC_SV
`define __ALLOC_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "common.pkg"
`include "vroom_macros.sv"

module alloc
    import instr::*, instr_decode::*, common::*;
(
    input  logic         clk,
    input  logic         reset,

    input  t_uinstr      uinstr_de1,

    input  t_rob_id      next_robid_ra0,

    input  logic         rs_stall_ex_rs0,
    output logic         disp_valid_ex_rs1,
    output t_uinstr_disp disp_ex_rs1,

    input  logic         rs_stall_mm_rs0,
    output logic         disp_valid_mm_rs1,
    output t_uinstr_disp disp_mm_rs1
);

localparam RA0 = 0;
localparam RA1 = 1;
localparam NUM_RA_STAGES = 1;

//
// Nets
//

t_uinstr_disp disp_rs0;
t_uinstr_disp disp_rs1;

//
// Logic
//

always_comb begin
   disp_rs0.uinstr       = uinstr_de1;
   disp_rs0.robid        = next_robid_ra0;
   disp_rs0.src1_rob_pdg = 1'b0;
   disp_rs0.src1_robid   = '0;
   disp_rs0.src2_rob_pdg = 1'b0;
   disp_rs0.src2_robid   = '0;
end

`DFF(disp_rs1, disp_rs0, clk)

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (uinstr_ra1.valid) begin
        `INFO(("unit:RA %s", describe_uinstr(uinstr_ra1)))
    end
end
`endif

`ifdef ASSERT
//VASSERT(a_br_mispred, uinstr_rd1.valid & ibr_resvld_ex0, ~ibr_mispred_ex0, "Branch mispredictions not yet supported.")
`endif

endmodule

`endif // __ALLOC_SV

