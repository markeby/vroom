`ifndef __STOREQ_ENTRY_SV
`define __STOREQ_ENTRY_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"
`include "mem_common.pkg"
`include "mem_defs.pkg"
`include "gen_funcs.pkg"

module storeq_entry
    import instr::*, instr_decode::*, common::*, rob_defs::*, gen_funcs::*, mem_defs::*, mem_common::*;
(
    input  logic            clk,
    input  logic            reset,
    input  t_stq_id         id,
    input  t_nuke_pkt       nuke_rb1,

    output logic            e_valid,

    input  logic            e_alloc_mm0,
    input  t_stq_static     q_alloc_static_mm0,
    output t_stq_static     e_static,

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

//
// FSM
//

typedef enum logic[2:0] {
    STQ_IDLE,
    STQ_REQ_PIPE,
    STQ_PDG_PIPE,
    STQ_WAIT
} t_stq_fsm;
t_stq_fsm fsm, fsm_nxt;

always_comb begin
    fsm_nxt = fsm;
    if (reset) begin
        fsm_nxt = STQ_IDLE;
    end else begin
        unique casez(fsm)
            STQ_IDLE:     if ( e_alloc_mm0      ) fsm_nxt = STQ_REQ_PIPE;
            STQ_REQ_PIPE: if ( e_pipe_gnt_mm0   ) fsm_nxt = STQ_PDG_PIPE;
            STQ_PDG_PIPE: if ( e_complete_mm5   ) fsm_nxt = STQ_IDLE;
                     else if ( e_recycle_mm5    ) fsm_nxt = STQ_WAIT;
            STQ_WAIT:     if ( 1'b1             ) fsm_nxt = STQ_REQ_PIPE;
        endcase
    end
end
`DFF(fsm, fsm_nxt, clk)

assign e_valid        = (fsm != STQ_IDLE);
assign e_pipe_req_mm0 = (fsm == STQ_REQ_PIPE);

//
// Logic
//

`DFF_EN(e_static, q_alloc_static_mm0, clk, e_alloc_mm0)

assign e_action_valid_mm5 = pipe_valid_mm5 & pipe_req_pkt_mm5.arb_type == MEM_STORE & pipe_req_pkt_mm5.id == id;
assign e_complete_mm5     = e_action_valid_mm5 & pipe_action_mm5.complete;
assign e_recycle_mm5      = e_action_valid_mm5 & pipe_action_mm5.recycle;

always_comb begin
    e_pipe_req_pkt_mm0          = '0;
    e_pipe_req_pkt_mm0.id       = id;
    e_pipe_req_pkt_mm0.arb_type = MEM_STORE;
    e_pipe_req_pkt_mm0.addr     = e_static.vaddr;
    e_pipe_req_pkt_mm0.robid    = e_static.robid;
    e_pipe_req_pkt_mm0.pdst     = '0;
    e_pipe_req_pkt_mm0.yost     = '0;
    `ifdef SIMULATION
    e_pipe_req_pkt_mm0.SIMID    = e_static.SIMID;
    `endif
end

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
`VASSERT(a_alloc_when_valid, e_alloc_mm0, ~e_valid, "Allocated storeq entry while valid")
`endif

endmodule

`endif // __STOREQ_ENTRY_SV


