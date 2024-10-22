`ifndef __LOADQ_ENTRY_SV
`define __LOADQ_ENTRY_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"
`include "mem_common.pkg"
`include "mem_defs.pkg"
`include "gen_funcs.pkg"

module loadq_entry
    import instr::*, instr_decode::*, common::*, rob_defs::*, gen_funcs::*, mem_defs::*, mem_common::*;
(
    input  logic            clk,
    input  logic            reset,
    input  t_ldq_id         id,
    input  t_nuke_pkt       nuke_rb1,
    input  logic[STQ_NUM_ENTRIES-1:0]
                            stq_e_valid,

    output logic            e_valid,

    input  logic            e_alloc_rs0,
    input  t_ldq_static     q_alloc_static_rs0,
    output t_ldq_static     e_static,

    input  logic            iss_ql_mm0,
    input  t_iss_pkt        iss_pkt_mm0,

    output logic            e_pipe_req_mm0,
    output t_mempipe_arb    e_pipe_req_pkt_mm0,
    input  logic            e_pipe_gnt_mm0,

    input  logic            pipe_valid_mm5,
    input  t_mempipe_arb    pipe_req_pkt_mm5,
    input  t_mempipe_action pipe_action_mm5
);

//
// Nets
//

logic e_complete_mm5;
logic e_recycle_mm5;
logic e_action_valid_mm5;

logic[STQ_NUM_ENTRIES-1:0] e_stq_elders;

t_vaddr  e_addr;
t_prf_id e_pdst;
logic    e_iss_mm0;
logic    e_iss_seen;

//
// FSM
//

typedef enum logic[2:0] {
    LDQ_IDLE,
    LDQ_PDG_ISS,
    LDQ_REQ_PIPE,
    LDQ_PDG_PIPE,
    LDQ_WAIT
} t_ldq_fsm;
t_ldq_fsm fsm, fsm_nxt;

always_comb begin
    fsm_nxt = fsm;
    if (reset) begin
        fsm_nxt = LDQ_IDLE;
    end else begin
        unique casez(fsm)
            LDQ_IDLE:     if ( e_alloc_rs0      ) fsm_nxt = LDQ_PDG_ISS;
            LDQ_PDG_ISS:  if ( e_iss_mm0        ) fsm_nxt = LDQ_REQ_PIPE;
            LDQ_REQ_PIPE: if ( e_pipe_gnt_mm0   ) fsm_nxt = LDQ_PDG_PIPE;
            LDQ_PDG_PIPE: if ( e_complete_mm5   ) fsm_nxt = LDQ_IDLE;
                     else if ( e_recycle_mm5    ) fsm_nxt = LDQ_WAIT;
            LDQ_WAIT:     if ( 1'b1             ) fsm_nxt = LDQ_REQ_PIPE;
        endcase

        if (nuke_rb1.valid & (fsm inside {LDQ_IDLE,LDQ_PDG_ISS,LDQ_REQ_PIPE,LDQ_PDG_PIPE,LDQ_WAIT})) begin
            fsm_nxt = LDQ_IDLE;
        end
    end
end
`DFF(fsm, fsm_nxt, clk)

assign e_valid        = (fsm != LDQ_IDLE);
assign e_pipe_req_mm0 = (fsm == LDQ_REQ_PIPE); // & ~|e_stq_elders;

//
// Logic
//

// Static storage (alloc)

`DFF_EN(e_static, q_alloc_static_rs0, clk, e_alloc_rs0)

// Static storage (issue)

assign e_iss_mm0 = iss_ql_mm0 & iss_pkt_mm0.meta.mem.ldqid == id;
`DFF_EN(e_addr,     (iss_pkt_mm0.src1_val + iss_pkt_mm0.src2_val), clk, e_iss_mm0)
`DFF_EN(e_pdst,     (iss_pkt_mm0.pdst                           ), clk, e_iss_mm0)
`DFF   (e_iss_seen, ~e_alloc_rs0 & (e_iss_seen | e_iss_mm0      ), clk)

// Decodes

assign e_action_valid_mm5 = pipe_valid_mm5 & pipe_req_pkt_mm5.arb_type == MEM_LOAD & pipe_req_pkt_mm5.id == id;
assign e_complete_mm5     = e_action_valid_mm5 & pipe_action_mm5.complete;
assign e_recycle_mm5      = e_action_valid_mm5 & pipe_action_mm5.recycle;

always_comb begin
    e_pipe_req_pkt_mm0          = '0;
    e_pipe_req_pkt_mm0.id       = id;
    e_pipe_req_pkt_mm0.arb_type = MEM_LOAD;
    e_pipe_req_pkt_mm0.addr     = e_addr;
    e_pipe_req_pkt_mm0.robid    = e_static.robid;
    e_pipe_req_pkt_mm0.pdst     = e_pdst;
    e_pipe_req_pkt_mm0.yost     = '0;
    e_pipe_req_pkt_mm0.nukeable = 1'b1;
    e_pipe_req_pkt_mm0.older_stq_ents = e_stq_elders;
    `ifdef SIMULATION
    e_pipe_req_pkt_mm0.SIMID    = e_static.SIMID;
    `endif
end

`DFF(e_stq_elders, e_alloc_rs0 ? stq_e_valid : (e_stq_elders & stq_e_valid), clk)

//
// Debug
//

`ifdef SIMULATION
// always @(posedge clk) begin
//     if (iss_mm0) begin
//         `INFO(("unit:MM %s", describe_uinstr(iss_pkt_mm0.uinstr)))
//     end
// end
`endif

`ifdef ASSERT
`VASSERT(a_alloc_when_valid, e_alloc_rs0, ~e_valid, "Allocated loadq entry while valid")
`VASSERT(a_untimely_issue,   e_iss_mm0, e_valid & fsm == LDQ_PDG_ISS, "Untimely storeq issue")
`VASSERT(a_incorrect_issue, e_iss_mm0, iss_pkt_mm0.uinstr.SIMID == e_static.SIMID, "LdQ entry incorrect issue")
`endif

endmodule

`endif // __LOADQ_ENTRY_SV


