`ifndef __RS_SV
`define __RS_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "common.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"
`include "gen_funcs.pkg"
`include "verif.pkg"

module rs
    import instr::*, instr_decode::*, common::*, rob_defs::*, gen_funcs::*, verif::*;
    #( parameter int NUM_RS_ENTS = 8, parameter string RS_NAME = "" )
(
    input  logic          clk,
    input  logic          reset,

    input  logic          iprf_wr_en_ro0   [IPRF_NUM_WRITES-1:0],
    input  t_prf_wr_pkt   iprf_wr_pkt_ro0  [IPRF_NUM_WRITES-1:0],

    output logic          rs_stall_rs0,
    input  logic          disp_valid_rs0,
    input  t_uinstr_disp  uinstr_rs0,

    output logic          prf_rdens_rd0   [1:0],
    output t_prf_id       prf_rdaddrs_rd0 [1:0],
    input  t_rv_reg_data  prf_rddatas_rd1 [1:0],

    output logic          iss_rs2,
    output t_uinstr_iss   iss_pkt_rs2
);

localparam RS0 = 0;
localparam RS1 = 1;
localparam NUM_EX_STAGES = 1;

//
// Nets
//

logic                  q_alloc_rs0;
logic[NUM_RS_ENTS-1:0] e_alloc_rs0;
t_rs_entry_static      q_alloc_static_rs0;
t_rs_entry_static      e_static               [NUM_RS_ENTS-1:0];
t_rs_entry_static      q_sel_static_rs1;
t_rename_pkt           q_sel_rename_rs1;
logic[NUM_RS_ENTS-1:0] e_valid;

logic                  q_req_issue_rs1;
logic[NUM_RS_ENTS-1:0] e_req_issue_rs1;
logic[NUM_RS_ENTS-1:0] e_sel_issue_rs1;
logic                  q_gnt_issue_rs1;
logic[NUM_RS_ENTS-1:0] e_gnt_issue_rs1;
t_uinstr_iss           e_issue_pkt_rs1        [NUM_RS_ENTS-1:0];

logic                  iss_rs1;
t_uinstr_iss           iss_pkt_rs1;
logic[NUM_SOURCES-1:0] src_from_prf_rs1;

//
// Logic
//

assign rs_stall_rs0 = 1'b0;
assign q_alloc_rs0 = disp_valid_rs0;
assign e_alloc_rs0 = q_alloc_rs0 ? gen_funcs#(.IWIDTH(NUM_RS_ENTS))::find_first0(e_valid) : '0;

// Issue arbitration

assign q_req_issue_rs1 = |e_req_issue_rs1;
assign e_sel_issue_rs1 = gen_funcs#(.IWIDTH(NUM_RS_ENTS))::find_first1(e_req_issue_rs1);
assign q_gnt_issue_rs1 = q_req_issue_rs1;
assign e_gnt_issue_rs1 = q_gnt_issue_rs1 ? e_sel_issue_rs1 : '0;

assign q_sel_static_rs1 = gen_funcs#(.IWIDTH(NUM_RS_ENTS),.T(t_rs_entry_static))::uaomux(e_static, e_sel_issue_rs1);
assign q_sel_rename_rs1 = q_sel_static_rs1.uinstr_disp.rename;

assign iss_rs1     = q_gnt_issue_rs1;
assign iss_pkt_rs1 = gen_funcs#(.IWIDTH(NUM_RS_ENTS),.T(t_uinstr_iss))::uaomux(e_issue_pkt_rs1, e_sel_issue_rs1);

assign src_from_prf_rs1[SRC1] = q_sel_static_rs1.uinstr_disp.uinstr.src1.optype == OP_REG;
assign src_from_prf_rs1[SRC2] = q_sel_static_rs1.uinstr_disp.uinstr.src2.optype == OP_REG;

// GPR Read

always_comb begin
    prf_rdens_rd0[0]   = src_from_prf_rs1[SRC1];
    prf_rdaddrs_rd0[0] = q_sel_rename_rs1.psrc1;
    prf_rdens_rd0[1]   = src_from_prf_rs1[SRC2];
    prf_rdaddrs_rd0[1] = q_sel_rename_rs1.psrc2;
end

// Issue staging

`DFF(iss_rs2,        iss_rs1,     clk)

t_uinstr_iss   iss_pkt_nq_rs2;
`DFF(iss_pkt_nq_rs2, iss_pkt_rs1, clk)

function automatic t_rv_reg_data f_opsel(t_optype optype, t_rv_reg_data imm_data, t_rv_reg_data prf_data);
    f_opsel = '0;
    unique casez(optype)
        OP_INVD: f_opsel = '0;
        OP_ZERO: f_opsel = '0;
        OP_IMM:  f_opsel = imm_data;
        OP_MEM:  f_opsel = '0; // ???
        OP_REG:  f_opsel = prf_data;
    endcase
endfunction

always_comb begin
    iss_pkt_rs2 = iss_pkt_nq_rs2;
    iss_pkt_rs2.src1_val = f_opsel(iss_pkt_nq_rs2.uinstr.src1.optype, iss_pkt_nq_rs2.uinstr.imm64, prf_rddatas_rd1[SRC1]);
    iss_pkt_rs2.src2_val = f_opsel(iss_pkt_nq_rs2.uinstr.src2.optype, iss_pkt_nq_rs2.uinstr.imm64, prf_rddatas_rd1[SRC2]);
end

//
// Entries
//

always_comb begin
   q_alloc_static_rs0.uinstr_disp = uinstr_rs0;
end

for (genvar i=0; i<NUM_RS_ENTS; i++) begin : g_entries
   rs_entry entry (
       .clk,
       .reset,

       .iprf_wr_en_ro0,
       .iprf_wr_pkt_ro0,

       .e_alloc_rs0 ( e_alloc_rs0[i] ),
       .q_alloc_static_rs0,

       .e_valid ( e_valid[i] ),
       .e_static ( e_static[i] ),
       .e_issue_pkt_rs1 ( e_issue_pkt_rs1[i] ),

       .e_req_issue_rs1 ( e_req_issue_rs1[i] ),
       .e_gnt_issue_rs1 ( e_gnt_issue_rs1[i] )
   );
end

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (iss_rs2) begin
        `UINFO(iss_pkt_rs2.uinstr.SIMID, ("unit:%s func:issue robid:0x%0x pdst:%s src1:0x%0x src2:0x%0x %s",
            RS_NAME, iss_pkt_rs2.robid, f_describe_prf(iss_pkt_rs2.pdst), iss_pkt_rs2.src1_val, iss_pkt_rs2.src2_val,
            describe_uinstr(iss_pkt_rs2.uinstr)))
    end
end
`endif

`ifdef ASSERT
//VASSERT(a_br_mispred, uinstr_rd1.valid & ibr_resvld_ex0, ~ibr_mispred_ex0, "Branch mispredictions not yet supported.")
`endif

endmodule

`endif // __RS_SV

