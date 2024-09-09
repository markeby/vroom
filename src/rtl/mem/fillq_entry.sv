`ifndef __FILLQ_ENTRY_SV
`define __FILLQ_ENTRY_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"
`include "mem_common.pkg"
`include "mem_defs.pkg"
`include "gen_funcs.pkg"

module fillq_entry
    import instr::*, instr_decode::*, common::*, rob_defs::*, gen_funcs::*, mem_defs::*, mem_common::*;
(
    input  logic            clk,
    input  logic            reset,
    input  t_flq_id         id,

    output logic            e_valid,

    output logic            e_mem_req,
    output t_mem_req_pkt    e_mem_req_pkt,
    input  logic            e_mem_gnt,

    input  t_mem_rsp_pkt    q_mem_rsp_pkt,

    input  logic            e_alloc_mm5,
    input  t_flq_static     q_alloc_static_mm5,
    output t_flq_static     e_static,

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

logic e_mem_rsp_valid;

//
// FSM
//

typedef enum logic[2:0] {
    FLQ_IDLE,
    FLQ_PDG_EVQ,
    FLQ_REQ_MEM,
    FLQ_PDG_MEM,
    FLQ_REQ_PIPE,
    FLQ_PDG_PIPE,
    FLQ_WAIT
} t_flq_fsm;
t_flq_fsm fsm, fsm_nxt;

always_comb begin
    fsm_nxt = fsm;
    if (reset) begin
        fsm_nxt = FLQ_IDLE;
    end else begin
        unique casez(fsm)
            FLQ_IDLE:     if ( e_alloc_mm5      ) fsm_nxt = FLQ_PDG_EVQ;
            FLQ_PDG_EVQ:  if ( 1'b1             ) fsm_nxt = FLQ_REQ_MEM;
            FLQ_REQ_MEM:  if ( e_mem_gnt        ) fsm_nxt = FLQ_PDG_MEM;
            FLQ_PDG_MEM:  if ( e_mem_rsp_valid  ) fsm_nxt = FLQ_REQ_PIPE;
            FLQ_REQ_PIPE: if ( e_pipe_gnt_mm0   ) fsm_nxt = FLQ_PDG_PIPE;
            FLQ_PDG_PIPE: if ( e_complete_mm5   ) fsm_nxt = FLQ_IDLE;
                     else if ( e_recycle_mm5    ) fsm_nxt = FLQ_WAIT;
            FLQ_WAIT:     if ( 1'b1             ) fsm_nxt = FLQ_REQ_PIPE;
        endcase
    end
end
`DFF(fsm, fsm_nxt, clk)

assign e_valid        = (fsm != FLQ_IDLE);
assign e_pipe_req_mm0 = (fsm == FLQ_REQ_PIPE);
assign e_mem_req      = (fsm == FLQ_REQ_MEM);

//
// Logic
//

`DFF_EN(e_static, q_alloc_static_mm5, clk, e_alloc_mm5)

assign e_action_valid_mm5 = pipe_valid_mm5 & pipe_req_pkt_mm5.arb_type == MEM_FILL & pipe_req_pkt_mm5.id == id;
assign e_complete_mm5     = e_action_valid_mm5 & pipe_action_mm5.complete;
assign e_recycle_mm5      = e_action_valid_mm5 & pipe_action_mm5.recycle;

always_comb begin
    e_pipe_req_pkt_mm0          = '0;
    e_pipe_req_pkt_mm0.id       = id;
    e_pipe_req_pkt_mm0.arb_type = MEM_FILL;
    e_pipe_req_pkt_mm0.addr     = e_static.paddr;
    e_pipe_req_pkt_mm0.robid    = '0;
    e_pipe_req_pkt_mm0.pdst     = '0;
    e_pipe_req_pkt_mm0.yost     = '0;
    `ifdef SIMULATION
    e_pipe_req_pkt_mm0.SIMID    = e_static.SIMID;
    `endif
end

always_comb begin
    e_mem_req_pkt.valid = e_mem_req;
    e_mem_req_pkt.addr  = e_static.paddr;
    e_mem_req_pkt.id    = id;
end

assign e_mem_rsp_valid = q_mem_rsp_pkt.valid & q_mem_rsp_pkt.id == id;

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

`ifdef ASSERT
`VASSERT(a_alloc_when_valid, e_alloc_mm5, ~e_valid, "Allocated fillq entry while valid")
`endif

endmodule

`endif // __FILLQ_ENTRY_SV


