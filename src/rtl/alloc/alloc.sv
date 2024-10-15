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

    input  logic         ldq_stall_rs0,
    input  logic         stq_stall_rs0,

    input  logic         valid_ra0,
    input  t_uinstr      uinstr_ra0,
    input  t_rename_pkt  rename_ra0,

    output logic         alloc_ready_ra0,

    output t_gpr_id      src_addr_ra0          [NUM_SOURCES-1:0],
    input  logic         rob_src_reg_pdg_ra0   [NUM_SOURCES-1:0],
    input  t_rob_id      rob_src_reg_robid_ra0 [NUM_SOURCES-1:0],

    input  logic         rs_stall_rs0,
    input  t_stq_id      stqid_alloc_rs0,
    input  t_ldq_id      ldqid_alloc_rs0,
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

logic    valid_ql_ra0;

//
// Logic
//

assign valid_ql_ra0 = valid_ra0;

assign src_addr_ra0[SRC1] = uinstr_ra0.src1.opreg;
assign src_addr_ra0[SRC2] = uinstr_ra0.src2.opreg;

always_comb begin
    disp_pkt_ra0.uinstr       = uinstr_ra0;
    disp_pkt_ra0.rename       = rename_ra0;
    disp_pkt_ra0.meta         = '0;
end

`DFF(disp_pkt_ra1, disp_pkt_ra0, clk)

logic valid_nq_ra1;
logic valid_ra1;
`DFF(valid_nq_ra1, valid_ql_ra0, clk);
assign valid_ra1 = valid_nq_ra1 & ~nuke_rb1.valid;

logic stall_ra1;

always_comb begin
    disp_valid_rs0 = valid_ra1 & ~nuke_rb1.valid;

    disp_pkt_rs0   = disp_pkt_ra1;
    if (uop_is_ldst(disp_pkt_ra1.uinstr.uop)) begin
        disp_pkt_rs0.meta.mem = '{ldqid: ldqid_alloc_rs0, stqid: stqid_alloc_rs0};
    end
end

// Stall

assign stall_ra1 = rs_stall_rs0 | ldq_stall_rs0 | stq_stall_rs0;

assign alloc_ready_ra0 = ~stall_ra1;

//
// Debug
//

`ifdef SIMULATION
    always @(posedge clk) begin
        if (disp_valid_rs0) begin
            `UINFO(disp_pkt_rs0.uinstr.SIMID, ("unit:RA robid:0x%0x pdst:0x%0x psrc1:0x%0x psrc1_pend:%0d psrc2:0x%0x psrc2_pend:%0d %s",
                disp_pkt_rs0.rename.robid, disp_pkt_rs0.rename.pdst, disp_pkt_rs0.rename.psrc1, disp_pkt_rs0.rename.psrc1_pend, disp_pkt_rs0.rename.psrc2, disp_pkt_rs0.rename.psrc2_pend,
                describe_uinstr(disp_pkt_rs0.uinstr)))
        end
    end
`endif

`ifdef ASSERT
`endif

endmodule

`endif // __ALLOC_SV

