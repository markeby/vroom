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

    output logic            e_valid,

    input  logic            e_alloc_mm0,
    input  t_ldq_static     q_alloc_static_mm0,
    output t_ldq_static     e_static,

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
    LDQ_IDLE,
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
            LDQ_IDLE:     if ( e_alloc_mm0      ) fsm_nxt = LDQ_REQ_PIPE;
            LDQ_REQ_PIPE: if ( e_pipe_gnt_mm0   ) fsm_nxt = LDQ_PDG_PIPE;
            LDQ_PDG_PIPE: if ( e_complete_mm5   ) fsm_nxt = LDQ_IDLE;
                     else if ( e_recycle_mm5    ) fsm_nxt = LDQ_WAIT;
            LDQ_WAIT:     if ( 1'b1             ) fsm_nxt = LDQ_REQ_PIPE;
        endcase
    end
end
`DFF(fsm, fsm_nxt, clk)

assign e_valid        = (fsm != LDQ_IDLE);
assign e_pipe_req_mm0 = (fsm == LDQ_REQ_PIPE);

//
// Logic
//

`DFF_EN(e_static, q_alloc_static_mm0, clk, e_alloc_mm0)

assign e_action_valid_mm5 = pipe_valid_mm5 & pipe_req_pkt_mm5.arb_type == MEM_LOAD & pipe_req_pkt_mm5.id == id;
assign e_complete_mm5     = e_action_valid_mm5 & pipe_action_mm5.complete;
assign e_recycle_mm5      = e_action_valid_mm5 & pipe_action_mm5.recycle;

always_comb begin
    e_pipe_req_pkt_mm0          = '0;
    e_pipe_req_pkt_mm0.id       = id;
    e_pipe_req_pkt_mm0.arb_type = MEM_LOAD;
    e_pipe_req_pkt_mm0.addr     = e_static.vaddr;
    e_pipe_req_pkt_mm0.robid    = e_static.robid;
    e_pipe_req_pkt_mm0.pdst     = e_static.pdst;
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
`VASSERT(a_alloc_when_valid, e_alloc_mm0, ~e_valid, "Allocated loadq entry while valid")
`endif

endmodule

`endif // __LOADQ_ENTRY_SV


