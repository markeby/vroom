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

    input  t_rob_id         oldest_robid,

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
logic e_senior;

//
// FSM
//

typedef enum logic[3:0] {
    STQ_IDLE,
    STQ_REQ_PIPE,
    STQ_PDG_PIPE,
    STQ_WAIT,
    STQ_PEND_RET,
    STQ_REQ_PIPE_FINAL,
    STQ_PDG_PIPE_FINAL,
    STQ_WAIT_FINAL
} t_stq_fsm;
t_stq_fsm fsm, fsm_nxt;

always_comb begin
    fsm_nxt = fsm;
    if (reset) begin
        fsm_nxt = STQ_IDLE;
    end else begin
        unique casez(fsm)
            STQ_IDLE:           if ( e_alloc_mm0      ) fsm_nxt = STQ_REQ_PIPE;
            STQ_REQ_PIPE:       if ( e_pipe_gnt_mm0   ) fsm_nxt = STQ_PDG_PIPE;
            STQ_PDG_PIPE:       if ( e_complete_mm5   ) fsm_nxt = STQ_PEND_RET;
                           else if ( e_recycle_mm5    ) fsm_nxt = STQ_WAIT;
            STQ_WAIT:           if ( 1'b1             ) fsm_nxt = STQ_REQ_PIPE;

            STQ_PEND_RET:       if ( e_senior         ) fsm_nxt = STQ_REQ_PIPE_FINAL;
            STQ_REQ_PIPE_FINAL: if ( e_pipe_gnt_mm0   ) fsm_nxt = STQ_PDG_PIPE_FINAL;
            STQ_PDG_PIPE_FINAL: if ( e_complete_mm5   ) fsm_nxt = STQ_IDLE;
                           else if ( e_recycle_mm5    ) fsm_nxt = STQ_WAIT_FINAL;
            STQ_WAIT_FINAL:     if ( 1'b1             ) fsm_nxt = STQ_REQ_PIPE_FINAL;
        endcase
    end
end
`DFF(fsm, fsm_nxt, clk)

assign e_valid        = (fsm != STQ_IDLE);
assign e_pipe_req_mm0 = fsm inside {STQ_REQ_PIPE,STQ_REQ_PIPE_FINAL};

//
// Logic
//

// Senior calc

t_rob_id oldest_robid_dly;
`DFF(oldest_robid_dly, oldest_robid, clk)

logic e_retiring_now;
assign e_retiring_now = e_static.robid == oldest_robid_dly
                      & e_static.robid != oldest_robid;
`DFF(e_senior, ~e_alloc_mm0 & (e_senior | e_retiring_now), clk)

// Static storage

`DFF_EN(e_static, q_alloc_static_mm0, clk, e_alloc_mm0)

assign e_action_valid_mm5 = pipe_valid_mm5 & pipe_req_pkt_mm5.arb_type == MEM_STORE & pipe_req_pkt_mm5.id == id;
assign e_complete_mm5     = e_action_valid_mm5 & pipe_action_mm5.complete;
assign e_recycle_mm5      = e_action_valid_mm5 & pipe_action_mm5.recycle;

t_cl e_st_data_repl;
always_comb begin
    unique casez (e_static.osize)
        SZ_1B: e_st_data_repl = {(CL_SZ_BYTES/1){e_static.data[ 7:0]}};
        SZ_2B: e_st_data_repl = {(CL_SZ_BYTES/2){e_static.data[15:0]}};
        SZ_4B: e_st_data_repl = {(CL_SZ_BYTES/4){e_static.data[31:0]}};
        SZ_8B: e_st_data_repl = {(CL_SZ_BYTES/8){e_static.data[63:0]}};
        default: e_st_data_repl = {16{32'hDEADBEEF}};
    endcase
end

logic[CL_SZ_BYTES-1+7:0] e_byte_en_full;
always_comb begin
    logic[7:0] be_unshft;
    be_unshft = '0;
    unique casez (e_static.osize)
        SZ_1B: be_unshft = 8'h01;
        SZ_2B: be_unshft = 8'h03;
        SZ_4B: be_unshft = 8'h0f;
        SZ_8B: be_unshft = 8'hff;
        default: be_unshft = 8'h00;
    endcase
    e_byte_en_full = '0;
    for (logic[6:0] b=0; b<8; b++) begin
        e_byte_en_full[{1'b0,e_static.vaddr[5:0]} + b] = be_unshft[b[2:0]];
    end
end

`ifdef SIMULATION
    `VASSERT(alloc_at_align_1B, e_alloc_mm0 & q_alloc_static_mm0.vaddr[0], q_alloc_static_mm0.osize inside {SZ_1B            }, "MEM instr not naturally aligned")
    `VASSERT(alloc_at_align_2B, e_alloc_mm0 & q_alloc_static_mm0.vaddr[1], q_alloc_static_mm0.osize inside {SZ_1B,SZ_2B      }, "MEM instr not naturally aligned")
    `VASSERT(alloc_at_align_4B, e_alloc_mm0 & q_alloc_static_mm0.vaddr[2], q_alloc_static_mm0.osize inside {SZ_1B,SZ_2B,SZ_4B}, "MEM instr not naturally aligned")
`endif

always_comb begin
    e_pipe_req_pkt_mm0          = '0;
    `ifdef SIMULATION
    e_pipe_req_pkt_mm0.SIMID    = e_static.SIMID;
    `endif
    e_pipe_req_pkt_mm0.id       = id;
    e_pipe_req_pkt_mm0.arb_type = MEM_STORE;
    e_pipe_req_pkt_mm0.addr     = e_static.vaddr;
    e_pipe_req_pkt_mm0.robid    = e_static.robid;
    e_pipe_req_pkt_mm0.pdst     = '0;
    e_pipe_req_pkt_mm0.yost     = '0;
    e_pipe_req_pkt_mm0.phase.st = (fsm == STQ_REQ_PIPE_FINAL) ? MEM_ST_FINAL : MEM_ST_INITIAL;
    e_pipe_req_pkt_mm0.arb_data = e_st_data_repl;
    e_pipe_req_pkt_mm0.byte_en  = e_byte_en_full[63:0];
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


