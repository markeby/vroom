`ifndef __LOADQ_SV
`define __LOADQ_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"
`include "mem_common.pkg"
`include "mem_defs.pkg"
`include "gen_funcs.pkg"

module loadq
    import instr::*, instr_decode::*, common::*, rob_defs::*, gen_funcs::*, mem_defs::*, mem_common::*;
(
    input  logic            clk,
    input  logic            reset,
    input  t_nuke_pkt       nuke_rb1,
    output logic            idle,
    output logic            full,

    input  logic[STQ_NUM_ENTRIES-1:0]
                            stq_e_valid,

    input  logic            disp_valid_rs0,
    input  t_disp_pkt       disp_pkt_rs0,

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

logic                      q_alloc_mm0;
logic[LDQ_NUM_ENTRIES-1:0] e_alloc_mm0;
logic[LDQ_NUM_ENTRIES-1:0] e_alloc_sel_mm0;

logic[LDQ_NUM_ENTRIES-1:0] e_valid;

logic[LDQ_NUM_ENTRIES-1:0] e_pipe_req_mm0;
t_mempipe_arb              e_pipe_req_pkt_mm0 [LDQ_NUM_ENTRIES-1:0];
logic[LDQ_NUM_ENTRIES-1:0] e_pipe_sel_mm0;
logic[LDQ_NUM_ENTRIES-1:0] e_pipe_gnt_mm0;

t_ldq_static q_alloc_static_mm0;
t_ldq_static e_static [LDQ_NUM_ENTRIES-1:0];

logic                      q_pipe_req_mm0;
t_mempipe_arb              q_pipe_req_pkt_mm0;
logic                      q_pipe_gnt_mm0;

//
// Logic
//

assign q_alloc_mm0     = iss_mm0 & rv_opcode_is_ld(iss_pkt_mm0.uinstr.opcode);
assign e_alloc_sel_mm0 = 1 << iss_pkt_mm0.meta.mem.ldqid;
assign e_alloc_mm0     = q_alloc_mm0 ? e_alloc_sel_mm0 : '0;

always_comb begin
    `ifdef SIMULATION
    q_alloc_static_mm0.SIMID = iss_pkt_mm0.uinstr.SIMID;
    `endif
    q_alloc_static_mm0.robid = iss_pkt_mm0.robid;
    q_alloc_static_mm0.pdst  = iss_pkt_mm0.pdst;
    q_alloc_static_mm0.vaddr = iss_pkt_mm0.src1_val + iss_pkt_mm0.src2_val;
    q_alloc_static_mm0.yost  = iss_pkt_mm0.meta.mem.stqid;
end

//
// Pipe arb
//

gen_arbiter #(.POLICY("FIND_FIRST"), .NREQS(LDQ_NUM_ENTRIES), .T(t_mempipe_arb)) pipe_arb (
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
// Entries
//

for (genvar e=0; e<LDQ_NUM_ENTRIES; e++) begin : g_ldq_entries
    loadq_entry loadq_entry (
        .clk,
        .reset,
        .id                 ( t_ldq_id'(e)          ) ,
        .nuke_rb1,
        .e_valid            ( e_valid[e]            ) ,
        .e_alloc_mm0        ( e_alloc_mm0[e]        ) ,
        .q_alloc_static_mm0,
        .stq_e_valid,
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
    if (iss_mm0) begin
        `INFO(("unit:MM vaddr:%08h %s", q_alloc_static_mm0.vaddr, describe_uinstr(iss_pkt_mm0.uinstr)))
    end
end
`endif

    /*
`ifdef ASSERT
`VASSERT(a_illegal_format, uinstr_de1.valid, uinstr_de1.ifmt inside {RV_FMT_I,RV_FMT_R}, $sformatf("Unsupported instr fmt: %s", uinstr_de1.ifmt.name()))
`endif
    */

endmodule

`endif // __LOADQ_SV


