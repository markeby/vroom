`ifndef __FILLQ_SV
`define __FILLQ_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"
`include "mem_common.pkg"
`include "mem_defs.pkg"
`include "gen_funcs.pkg"
`include "verif.pkg"

module fillq
    import instr::*, instr_decode::*, common::*, rob_defs::*, gen_funcs::*, mem_defs::*, mem_common::*, verif::*;
(
    input  logic            clk,
    input  logic            reset,

    output t_mem_req        flq_mem_req_pkt,
    input  t_mem_rsp        flq_mem_rsp_pkt,

    input  logic            flq_alloc_mm5,

    output logic            pipe_req_mm0,
    output t_mempipe_arb    pipe_req_pkt_mm0,
    input  logic            pipe_gnt_mm0,

    input  t_mempipe_arb    pipe_pkt_mm1,

    output logic            flq_addr_mat_mm2,

    input  logic            pipe_valid_mm5,
    input  t_mempipe_arb    pipe_req_pkt_mm5,
    input  t_mempipe_action pipe_action_mm5
);

//
// Nets
//

logic                      q_alloc_mm5;
logic[FLQ_NUM_ENTRIES-1:0] e_alloc_mm5;
logic[FLQ_NUM_ENTRIES-1:0] e_alloc_sel_mm5;

logic[FLQ_NUM_ENTRIES-1:0] e_valid;

logic[FLQ_NUM_ENTRIES-1:0] e_pipe_req_mm0;
t_mempipe_arb              e_pipe_req_pkt_mm0 [FLQ_NUM_ENTRIES-1:0];
logic[FLQ_NUM_ENTRIES-1:0] e_pipe_sel_mm0;
logic[FLQ_NUM_ENTRIES-1:0] e_pipe_gnt_mm0;

t_flq_static q_alloc_static_mm5;
t_flq_static e_static [FLQ_NUM_ENTRIES-1:0];

logic                      q_pipe_req_mm0;
t_mempipe_arb              q_pipe_req_pkt_mm0;
logic                      q_pipe_gnt_mm0;

logic[FLQ_NUM_ENTRIES-1:0] e_mem_req;
t_mem_req                  e_mem_req_pkt [FLQ_NUM_ENTRIES-1:0];
logic[FLQ_NUM_ENTRIES-1:0] e_mem_gnt;

logic                      q_mem_req;
t_mem_req                  q_mem_req_pkt;
logic                      q_mem_gnt;

//
// Logic
//

assign q_alloc_mm5     = flq_alloc_mm5;
assign e_alloc_sel_mm5 = gen_funcs#(.IWIDTH(FLQ_NUM_ENTRIES))::find_first0(e_valid);
assign e_alloc_mm5     = q_alloc_mm5 ? e_alloc_sel_mm5 : '0;

`SIMID_SPAWN_CNTR(FILL_SIMID,q_alloc_mm5,clk,pipe_req_pkt_mm5.SIMID,FILL)

always_comb begin
    `ifdef SIMULATION
    q_alloc_static_mm5.SIMID      = FILL_SIMID;
    `endif
    q_alloc_static_mm5.paddr      = pipe_req_pkt_mm5.addr;
    q_alloc_static_mm5.alloc_id   = pipe_req_pkt_mm5.id;
    q_alloc_static_mm5.alloc_type = pipe_req_pkt_mm5.arb_type;
end

//
// Pipe arb
//

gen_arbiter #(.POLICY("FIND_FIRST"), .NREQS(FLQ_NUM_ENTRIES), .T(t_mempipe_arb)) pipe_arb (
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
// Mem arb
//

gen_arbiter #(.POLICY("FIND_FIRST"), .NREQS(FLQ_NUM_ENTRIES), .T(t_mem_req)) mem_arb (
    .clk,
    .reset,
    .int_req_valids ( e_mem_req     ) ,
    .int_req_pkts   ( e_mem_req_pkt ) ,
    .int_gnts       ( e_mem_gnt     ) ,
    .ext_req_valid  ( q_mem_req     ) ,
    .ext_req_pkt    ( q_mem_req_pkt ) ,
    .ext_gnt        ( q_mem_gnt     )
);

assign flq_mem_req_pkt = q_mem_req_pkt;
assign q_mem_gnt       = q_mem_req;

//
// Entries
//

for (genvar e=0; e<FLQ_NUM_ENTRIES; e++) begin : g_flq_entries
    fillq_entry fillq_entry (
        .clk,
        .reset,
        .id                 ( t_flq_id'(e)          ) ,
        .e_valid            ( e_valid[e]            ) ,
        .e_alloc_mm5        ( e_alloc_mm5[e]        ) ,
        .q_alloc_static_mm5,
        .e_static           ( e_static[e]           ) ,
        .e_mem_req          ( e_mem_req[e]          ) ,
        .e_mem_req_pkt      ( e_mem_req_pkt[e]      ) ,
        .e_mem_gnt          ( e_mem_gnt[e]          ) ,
        .q_mem_rsp_pkt      ( '0                    ) ,
        .e_pipe_req_mm0     ( e_pipe_req_mm0[e]     ) ,
        .e_pipe_req_pkt_mm0 ( e_pipe_req_pkt_mm0[e] ) ,
        .e_pipe_gnt_mm0     ( e_pipe_gnt_mm0[e]     ) ,
        .pipe_valid_mm5,
        .pipe_req_pkt_mm5,
        .pipe_action_mm5
    );
end

//
// CAM
//

if(1) begin : g_pipe_cam
    logic[FLQ_NUM_ENTRIES-1:0] e_pipe_pkt_addr_mat_set_mm1;
    logic[FLQ_NUM_ENTRIES-1:0] e_pipe_pkt_addr_mat_ful_mm1;
    logic                      q_pipe_pkt_addr_mat_mm1;
    logic                      q_pipe_pkt_addr_mat_mm2;
    for (genvar e=0; e<FLQ_NUM_ENTRIES; e++) begin : g_cam_loop
        assign e_pipe_pkt_addr_mat_set_mm1[e] = e_valid[e] & e_static[e].paddr                      == pipe_pkt_mm1.addr;
        assign e_pipe_pkt_addr_mat_ful_mm1[e] = e_valid[e] & e_static[e].paddr[L1_SET_HI:L1_SET_LO] == pipe_pkt_mm1.addr[L1_SET_HI:L1_SET_LO];
    end
    assign q_pipe_pkt_addr_mat_mm1 = (|e_pipe_pkt_addr_mat_set_mm1); // FIXME: too conservative
    `DFF(q_pipe_pkt_addr_mat_mm2, q_pipe_pkt_addr_mat_mm1, clk)
    assign flq_addr_mat_mm2 = q_pipe_pkt_addr_mat_mm2;
end

//
// SVAs
//

`ifdef SIMULATION
    for (genvar e=0; e<FLQ_NUM_ENTRIES; e++) begin : g_addr_chk
        `VASSERT(a_addr_chk, q_alloc_mm5 & e_valid[e], q_alloc_static_mm5.paddr != e_static[e].paddr, "Multiple FLQ entries with same PA!")
    end
`endif

//
// Debug
//

`ifdef SIMULATION
// always @(posedge clk) begin
//     if (iss_mm5) begin
//         `INFO(("unit:MM %s", describe_uinstr(iss_pkt_mm5.uinstr)))
//     end
// end
`endif

    /*
`ifdef ASSERT
`VASSERT(a_illegal_format, uinstr_de1.valid, uinstr_de1.ifmt inside {RV_FMT_I,RV_FMT_R}, $sformatf("Unsupported instr fmt: %s", uinstr_de1.ifmt.name()))
`endif
    */

endmodule

`endif // __FILLQ_SV


