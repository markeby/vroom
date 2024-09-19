`ifndef __STOREQ_SV
`define __STOREQ_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"
`include "mem_common.pkg"
`include "mem_defs.pkg"
`include "gen_funcs.pkg"
`include "verif.pkg"

module storeq
    import instr::*, instr_decode::*, common::*, rob_defs::*, gen_funcs::*, mem_defs::*, mem_common::*, verif::*;
(
    input  logic            clk,
    input  logic            reset,
    input  t_nuke_pkt       nuke_rb1,
    input  t_rob_id         oldest_robid,
    output logic            idle,
    output logic            full,

    output logic[STQ_NUM_ENTRIES-1:0]
                            e_valid,

    input  logic            disp_valid_rs0,
    input  t_disp_pkt       disp_pkt_rs0,
    output t_stq_id         stqid_alloc_rs0,

    input  logic            iss_mm0,
    input  t_iss_pkt        iss_pkt_mm0,

    output logic            pipe_req_mm0,
    output t_mempipe_arb    pipe_req_pkt_mm0,
    input  logic            pipe_gnt_mm0,

    input  logic            pipe_valid_mm5,
    input  t_mempipe_arb    pipe_req_pkt_mm5,
    input  t_mempipe_action pipe_action_mm5
);

//
// Nets
//

logic                      q_alloc_rs0;
logic[STQ_NUM_ENTRIES-1:0] e_alloc_rs0;
logic[STQ_NUM_ENTRIES-1:0] e_alloc_sel_rs0;

logic[STQ_NUM_ENTRIES-1:0] e_elders [STQ_NUM_ENTRIES-1:0];

logic[STQ_NUM_ENTRIES-1:0] e_pipe_req_mm0;
t_mempipe_arb              e_pipe_req_pkt_mm0 [STQ_NUM_ENTRIES-1:0];
logic[STQ_NUM_ENTRIES-1:0] e_pipe_sel_mm0;
logic[STQ_NUM_ENTRIES-1:0] e_pipe_gnt_mm0;

t_stq_static q_alloc_static_rs0;
t_stq_static e_static [STQ_NUM_ENTRIES-1:0];

logic                      q_pipe_req_mm0;
t_mempipe_arb              q_pipe_req_pkt_mm0;
logic                      q_pipe_gnt_mm0;

//
// Logic
//

assign q_alloc_rs0     = disp_valid_rs0 & rv_opcode_is_st(disp_pkt_rs0.uinstr.opcode);
assign e_alloc_sel_rs0 = gen_funcs#(.IWIDTH(STQ_NUM_ENTRIES))::find_first0(e_valid);
assign e_alloc_rs0     = q_alloc_rs0 ? e_alloc_sel_rs0 : '0;
assign stqid_alloc_rs0 = gen_lg2_funcs#(.IWIDTH(STQ_NUM_ENTRIES))::oh_encode(e_alloc_sel_rs0);

always_comb begin
    `ifdef SIMULATION
    q_alloc_static_rs0.SIMID = disp_pkt_rs0.uinstr.SIMID;
    `endif
    q_alloc_static_rs0.robid = disp_pkt_rs0.rename.robid;
    q_alloc_static_rs0.osize = disp_pkt_rs0.uinstr.dst.opsize;
end

//
// Pipe arb
//

gen_arbiter #(.POLICY("FIND_FIRST"), .NREQS(STQ_NUM_ENTRIES), .T(t_mempipe_arb)) pipe_arb (
    .clk,
    .reset,
    .int_req_valids ( e_pipe_req_mm0     ) ,
    .int_req_pkts   ( e_pipe_req_pkt_mm0 ) ,
    .int_gnts       ( e_pipe_gnt_mm0     ) ,
    .ext_req_valid  ( q_pipe_req_mm0     ) ,
    .ext_req_pkt    ( q_pipe_req_pkt_mm0 ) ,
    .ext_gnt        ( q_pipe_gnt_mm0     )
);

assign pipe_req_mm0     = q_pipe_req_mm0;
assign pipe_req_pkt_mm0 = q_pipe_req_pkt_mm0;
assign q_pipe_gnt_mm0   = pipe_gnt_mm0;

//
// Age matrix
//

gen_age_matrix #(.DEPTH(STQ_NUM_ENTRIES), .NUM_REQS(1)) age_mtx (
    .clk,
    .reset,
    .e_alloc ( e_alloc_rs0 ),
    .e_elders,
    .e_reqs ( '{ '0 } ),
    .e_sels (         )
);

//
// Entries
//

logic iss_ql_mm0;
assign iss_ql_mm0 = iss_mm0 & rv_opcode_is_st(iss_pkt_mm0.uinstr.opcode);

for (genvar e=0; e<STQ_NUM_ENTRIES; e++) begin : g_stq_entries
    storeq_entry storeq_entry (
        .clk,
        .reset,
        .id                 ( t_stq_id'(e)          ) ,
        .nuke_rb1,
        .oldest_robid,
        .e_valid            ( e_valid[e]            ) ,
        .e_elders           ( e_elders[e]           ) ,
        .e_alloc_rs0        ( e_alloc_rs0[e]        ) ,
        .q_alloc_static_rs0,
        .iss_ql_mm0,
        .iss_pkt_mm0,
        .e_static           ( e_static[e]           ) ,
        .e_pipe_req_mm0     ( e_pipe_req_mm0[e]     ) ,
        .e_pipe_req_pkt_mm0 ( e_pipe_req_pkt_mm0[e] ) ,
        .e_pipe_gnt_mm0     ( e_pipe_gnt_mm0[e]     ) ,
        .pipe_valid_mm5,
        .pipe_req_pkt_mm5,
        .pipe_action_mm5
    );
end

assign idle = ~|e_valid;
assign full =  &e_valid;

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (q_alloc_rs0) begin
        `UINFO(disp_pkt_rs0.uinstr.SIMID, ("unit:STQ func:alloc stqid:%h", stqid_alloc_rs0))
    end
    if (iss_ql_mm0) begin
        `UINFO(iss_pkt_mm0.uinstr.SIMID, ("unit:STQ func:issue stqid:%h", iss_pkt_mm0.meta.mem.stqid))
    end
end
`endif

`ifdef ASSERT
    `VASSERT(a_untimely_disp, disp_valid_rs0, ~&e_valid, "Store dispatch while storeq full")
`endif

endmodule

`endif // __STOREQ_SV


