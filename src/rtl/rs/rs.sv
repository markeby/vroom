`ifndef __RS_SV
`define __RS_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "common.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"
`include "gen_funcs.pkg"

module rs
    import instr::*, instr_decode::*, common::*, rob_defs::*, gen_funcs::*;
    #( parameter int NUM_RS_ENTS = 8 )
(
    input  logic          clk,
    input  logic          reset,

    input  logic          ro_valid_rb0,
    input  t_rob_result   ro_result_rb0,

    output logic          rs_stall_rs0,
    input  logic          disp_valid_rs0,
    input  t_uinstr_disp  uinstr_rs0,

    output logic          gpr_rdens_rd0   [1:0],
    output t_rv_reg_addr  gpr_rdaddrs_rd0 [1:0],
    input  t_rv_reg_data  gpr_rddatas_rd1 [1:0],

    output logic          iss_rs2,
    output t_uinstr_iss   iss_pkt_rs2
);

localparam RS0 = 0;
localparam RS1 = 1;
localparam NUM_EX_STAGES = 1;

localparam SRC1=0;
localparam SRC2=1;

//
// Nets
//

logic                  q_alloc_rs0;
logic[NUM_RS_ENTS-1:0] e_alloc_rs0;
t_rs_entry_static      q_alloc_static_rs0;
t_rs_entry_static      e_static               [NUM_RS_ENTS-1:0];
logic[NUM_RS_ENTS-1:0] e_valid;

logic                  q_req_issue_rs1;
logic[NUM_RS_ENTS-1:0] e_req_issue_rs1;
logic[NUM_RS_ENTS-1:0] e_sel_issue_rs1;
logic                  q_gnt_issue_rs1;
logic[NUM_RS_ENTS-1:0] e_gnt_issue_rs1;
t_uinstr_iss           e_issue_pkt_rs1        [NUM_RS_ENTS-1:0];
logic[NUM_SOURCES-1:0] e_src_from_grf_rs1     [NUM_RS_ENTS-1:0];

logic                  iss_rs1;
t_uinstr_iss           iss_pkt_rs1;
logic[NUM_SOURCES-1:0] src_from_grf_rs1;

logic[NUM_SOURCES-1:0] src_from_grf_rs2;

//
// Logic
//

assign rs_stall_rs0 = 1'b0;
assign q_alloc_rs0 = disp_valid_rs0;
assign e_alloc_rs0 = gen_funcs#(.IWIDTH(NUM_RS_ENTS))::find_first0(e_valid);

// Issue arbitration

assign q_req_issue_rs1 = |e_req_issue_rs1;
assign e_sel_issue_rs1 = gen_funcs#(.IWIDTH(NUM_RS_ENTS))::find_first(e_req_issue_rs1);
assign q_gnt_issue_rs1 = q_req_issue_rs1;
assign e_gnt_issue_rs1 = q_gnt_issue_rs1 ? e_sel_issue_rs1 : '0;

assign iss_rs1     = q_gnt_issue_rs1;
assign iss_pkt_rs1 = gen_funcs#(.IWIDTH(NUM_RS_ENTS),.T(t_uinstr_iss))::uaomux(e_issue_pkt_rs1, e_sel_issue_rs1);
assign src_from_grf_rs1 = gen_funcs#(.IWIDTH(NUM_RS_ENTS),.T(logic[1:0]))::uaomux(e_src_from_grf_rs1, e_sel_issue_rs1);

`DFF(src_from_grf_rs2, src_from_grf_rs1, clk)

// GPR Read

always_comb begin
    gpr_rdens_rd0[0]   = src_from_grf_rs1[SRC1];
    gpr_rdaddrs_rd0[0] = iss_pkt_rs1.uinstr.src1.opreg;
    gpr_rdens_rd0[1]   = src_from_grf_rs1[SRC2];
    gpr_rdaddrs_rd0[1] = iss_pkt_rs1.uinstr.src2.opreg;
end

// Issue staging

`DFF(iss_rs2,        iss_rs1,     clk)

t_uinstr_iss   iss_pkt_nq_rs2;
`DFF(iss_pkt_nq_rs2, iss_pkt_rs1, clk)

always_comb begin
    iss_pkt_rs2 = iss_pkt_nq_rs2;
    iss_pkt_rs2.src1_val = src_from_grf_rs2[SRC1] ? gpr_rddatas_rd1[SRC1] : '0;
    iss_pkt_rs2.src2_val = src_from_grf_rs2[SRC2] ? gpr_rddatas_rd1[SRC2] : '0;
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

       .ro_valid_rb0,
       .ro_result_rb0,

       .e_alloc_rs0 ( e_alloc_rs0[i] ),
       .q_alloc_static_rs0,

       .e_valid ( e_valid[i] ),
       .e_static ( e_static[i] ),
       .e_issue_pkt_rs1 ( e_issue_pkt_rs1[i] ),

       .e_src_from_grf_rs1 ( e_src_from_grf_rs1[i] ),
       .e_req_issue_rs1 ( e_req_issue_rs1[i] ),
       .e_gnt_issue_rs1 ( e_gnt_issue_rs1[i] )
   );
end

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    // if (uinstr_rd1.valid) begin
    //     `INFO(("unit:EX %s result:%08h", describe_uinstr(uinstr_rd1), result_exx[RS0]))
    // end
end
`endif

`ifdef ASSERT
//VASSERT(a_br_mispred, uinstr_rd1.valid & ibr_resvld_ex0, ~ibr_mispred_ex0, "Branch mispredictions not yet supported.")
`endif

endmodule

`endif // __RS_SV

