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
    input  t_nuke_pkt     nuke_rb1,
    input  t_rob_id       oldest_robid,
    input  logic          ldq_idle,
    input  logic          stq_idle,

    input  logic          iprf_wr_en_ro0   [IPRF_NUM_WRITES-1:0],
    input  t_prf_wr_pkt   iprf_wr_pkt_ro0  [IPRF_NUM_WRITES-1:0],

    output logic          rs_stall_rs0,
    input  logic          disp_valid_rs0,
    input  t_disp_pkt     disp_pkt_rs0,

    output logic          prf_rdens_rd0   [1:0],
    output t_prf_id       prf_rdaddrs_rd0 [1:0],
    input  t_rv_reg_data  prf_rddatas_rd1 [1:0],

    output logic          ex_iss_rs2,
    output t_iss_pkt      ex_iss_pkt_rs2,

    output logic          mm_iss_rs2,
    output t_iss_pkt      mm_iss_pkt_rs2
);

localparam RS0 = 0;
localparam RS1 = 1;
localparam NUM_EX_STAGES = 1;

//
// Nets
//

logic                  q_alloc_rs0;
logic[NUM_RS_ENTS-1:0] e_alloc_rs0;
logic[NUM_RS_ENTS-1:0] e_first_avail_rs0;
t_rs_entry_static      q_alloc_static_rs0;
t_rs_entry_static      e_static               [NUM_RS_ENTS-1:0];
t_rs_entry_static      q_sel_static_rs1;
t_rename_pkt           q_sel_rename_rs1;
logic[NUM_RS_ENTS-1:0] e_valid;
logic[$clog2(NUM_RS_ENTS)-1:0] q_alloc_id_rs0;

logic                  q_req_issue_rs1;
logic[NUM_RS_ENTS-1:0] e_req_issue_rs1;
logic[NUM_RS_ENTS-1:0] e_sel_issue_rs1;
logic                  q_gnt_issue_rs1;
logic[NUM_RS_ENTS-1:0] e_gnt_issue_rs1;
t_iss_pkt           e_issue_pkt_rs1        [NUM_RS_ENTS-1:0];

logic                  iss_rs1;
t_iss_pkt           iss_pkt_rs1;
logic[NUM_SOURCES-1:0] src_from_prf_rs1;

//
// Logic
//

assign rs_stall_rs0      = 1'b0;
assign q_alloc_rs0       = disp_valid_rs0;
assign e_first_avail_rs0 = gen_funcs#(.IWIDTH(NUM_RS_ENTS))::find_first0(e_valid);
assign e_alloc_rs0       = q_alloc_rs0 ? e_first_avail_rs0 : '0;
assign q_alloc_id_rs0    = gen_lg2_funcs#(.IWIDTH(NUM_RS_ENTS))::oh_encode(e_first_avail_rs0);

// Issue arbitration

assign q_req_issue_rs1 = |e_req_issue_rs1;
assign e_sel_issue_rs1 = gen_funcs#(.IWIDTH(NUM_RS_ENTS))::find_first1(e_req_issue_rs1);
assign q_gnt_issue_rs1 = q_req_issue_rs1 & ~nuke_rb1.valid;
assign e_gnt_issue_rs1 = q_gnt_issue_rs1 ? e_sel_issue_rs1 : '0;

assign q_sel_static_rs1 = mux_funcs#(.IWIDTH(NUM_RS_ENTS),.T(t_rs_entry_static))::uaomux(e_static, e_sel_issue_rs1);
assign q_sel_rename_rs1 = q_sel_static_rs1.uinstr_disp.rename;

assign iss_rs1     = q_gnt_issue_rs1;
assign iss_pkt_rs1 = mux_funcs#(.IWIDTH(NUM_RS_ENTS),.T(t_iss_pkt))::uaomux(e_issue_pkt_rs1, e_sel_issue_rs1);

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

logic iss_rs2;
logic iss_nq_rs2;
`DFF(iss_nq_rs2,        iss_rs1,     clk)
assign iss_rs2 = iss_nq_rs2 & ~nuke_rb1.valid;

t_iss_pkt   iss_pkt_nq_rs2;
`DFF(iss_pkt_nq_rs2, iss_pkt_rs1, clk)

function automatic t_rv_reg_data f_opsel(t_optype optype, t_rv_reg_data imm_data, t_rv_reg_data prf_data);
    f_opsel = '0;
    unique casez(optype)
        OP_INVD: f_opsel = '0;
        OP_ZERO: f_opsel = '0;
        OP_IMM:  f_opsel = imm_data;
        OP_MEM:  f_opsel = '0; // ???
        OP_REG:  f_opsel = prf_data;
        default: f_opsel = '0; // ???
    endcase
endfunction

t_iss_pkt iss_pkt_rs2;
always_comb begin
    iss_pkt_rs2 = iss_pkt_nq_rs2;
    iss_pkt_rs2.src1_val = f_opsel(iss_pkt_nq_rs2.uinstr.src1.optype, iss_pkt_nq_rs2.uinstr.imm64, prf_rddatas_rd1[SRC1]);
    iss_pkt_rs2.src2_val = f_opsel(iss_pkt_nq_rs2.uinstr.src2.optype, iss_pkt_nq_rs2.uinstr.imm64, prf_rddatas_rd1[SRC2]);
end

assign ex_iss_rs2     = iss_rs2 & uop_to_fu(iss_pkt_nq_rs2.uinstr.uop) == FU_EXE & ~nuke_rb1.valid;
assign ex_iss_pkt_rs2 = iss_pkt_rs2;

assign mm_iss_rs2     = iss_rs2 & uop_to_fu(iss_pkt_nq_rs2.uinstr.uop) == FU_MEM & ~nuke_rb1.valid;
assign mm_iss_pkt_rs2 = iss_pkt_rs2;

//
// Entries
//

always_comb begin
   q_alloc_static_rs0.uinstr_disp = disp_pkt_rs0;
end

for (genvar i=0; i<NUM_RS_ENTS; i++) begin : g_entries
   rs_entry entry (
       .clk,
       .reset,
       .nuke_rb1,
       .ldq_idle,
       .stq_idle,
       .oldest_robid,

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
    if (q_alloc_rs0) begin
        `UINFO(disp_pkt_rs0.uinstr.SIMID, ("unit:%s func:alloc rs_ent:0x%0h",
            RS_NAME, q_alloc_id_rs0))
    end
    if (ex_iss_rs2) begin
        `UINFO(ex_iss_pkt_rs2.uinstr.SIMID, ("unit:%s func:issue robid:0x%0x pdst:%s src1:0x%0x src2:0x%0x %s",
            RS_NAME, ex_iss_pkt_rs2.robid, f_describe_prf(ex_iss_pkt_rs2.pdst), ex_iss_pkt_rs2.src1_val, ex_iss_pkt_rs2.src2_val,
            describe_uinstr(ex_iss_pkt_rs2.uinstr)))
    end
end
`endif

`ifdef ASSERT
for (genvar e=0; e<NUM_RS_ENTS; e++) begin : g_per_ent_asserts
    `VASSERT(a_stqid_mat, q_alloc_rs0 & e_valid[e] & uop_is_st(disp_pkt_rs0.uinstr.uop) & uop_is_st(e_static[e].uinstr_disp.uinstr.uop), disp_pkt_rs0.meta.mem.stqid != e_static[e].uinstr_disp.meta.mem.stqid, $sformatf("New dispatch with overlapping STQID (RS %d STQID %h)", e, disp_pkt_rs0.meta.mem.stqid))
end
`endif

endmodule

`endif // __RS_SV

