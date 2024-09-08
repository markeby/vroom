`ifndef __ALLOC_SV
`define __ALLOC_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "common.pkg"
`include "vroom_macros.sv"
`include "verif.pkg"

module alloc
   import instr::*, instr_decode::*, common::*, verif::*;
(
    input  logic         clk,
    input  logic         reset,
    input  t_nuke_pkt    nuke_rb1,

    input  logic         rob_ready_ra0,
    input  t_uinstr      uinstr_ra0,
    input  t_rename_pkt  rename_ra0,

    output logic         alloc_ready_ra0,
    output logic         alloc_ra0,
    input  t_rob_id      next_robid_ra0,

    output t_rv_reg_addr src_addr_ra0          [NUM_SOURCES-1:0],
    input  logic         rob_src_reg_pdg_ra0   [NUM_SOURCES-1:0],
    input  t_rob_id      rob_src_reg_robid_ra0 [NUM_SOURCES-1:0],

    input  logic         rs_stall_rs0,
    output logic         disp_valid_rs0,
    output t_disp_pkt    disp_pkt_rs0
);

localparam RA0 = 0;
localparam RA1 = 1;
localparam NUM_RA_STAGES = 1;

//
// Nets
//

t_disp_pkt disp_pkt_ra0;
t_disp_pkt disp_pkt_ra1;

//
// Logic
//

assign src_addr_ra0[SRC1] = uinstr_ra0.src1.opreg;
assign src_addr_ra0[SRC2] = uinstr_ra0.src2.opreg;

always_comb begin
   disp_pkt_ra0.uinstr       = uinstr_ra0;
   disp_pkt_ra0.robid        = next_robid_ra0;
   disp_pkt_ra0.rename       = rename_ra0;
   disp_pkt_ra0.meta         = '0;
end

`DFF(disp_pkt_ra1, disp_pkt_ra0, clk)

logic stall_ra1;

assign disp_pkt_rs0   = disp_pkt_ra1;
assign disp_valid_rs0 = disp_pkt_ra1.uinstr.valid & ~stall_ra1;

// Stall

assign stall_ra1 = rs_stall_rs0 | ~rob_ready_ra0;

assign alloc_ready_ra0 = rob_ready_ra0 & ~stall_ra1;
assign alloc_ra0 = uinstr_ra0.valid & alloc_ready_ra0;

//
// Debug
//

`ifdef SIMULATION
    always @(posedge clk) begin
        if (disp_valid_rs0) begin
            `UINFO(disp_pkt_rs0.uinstr.SIMID, ("unit:RA robid:0x%0x pdst:0x%0x psrc1:0x%0x psrc2:0x%0x %s", 
                disp_pkt_rs0.robid, disp_pkt_rs0.rename.pdst, disp_pkt_rs0.rename.psrc1, disp_pkt_rs0.rename.psrc2, 
                describe_uinstr(disp_pkt_rs0.uinstr)))
        end
    end
`endif

`ifdef ASSERT
//VASSERT(a_br_mispred, uinstr_rd1.valid & ibr_resvld_ex0, ~ibr_mispred_ex0, "Branch mispredictions not yet supported.")
`endif

endmodule

`endif // __ALLOC_SV

