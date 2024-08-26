`ifndef __FE_PF_SV
`define __FE_PF_SV

`include "instr.pkg"
`include "verif.pkg"
`include "asm.pkg"
`include "mem_common.pkg"
`include "vroom_macros.sv"
`include "gen_funcs.pkg"

module fe_pf
    import instr::*, common::*, mem_common::*, verif::*, gen_funcs::*;
(
    input  logic       clk,
    input  logic       reset,

    // FE inputs
    input  t_fe_fb_req fe_fb_req_fb0,

    // IC
    output logic       pf_fb_req_rq_pf0,
    output t_fe_fb_req pf_fb_req_pkt_pf0,
    input  logic       pf_fb_req_gn_pf0
);

typedef enum logic[2:0] {
    IDLE,
    REQ_PF
} t_fsm;

//
// Nets
//

t_fsm   state, state_nxt;
t_paddr next_line;

//
// Miss FSM
//

always_comb begin
    state_nxt = state;
    unique case(state)
        IDLE:      if (fe_fb_req_fb0.valid                     ) state_nxt = REQ_PF;
        REQ_PF:    if (pf_fb_req_gn_pf0 & ~fe_fb_req_fb0.valid ) state_nxt = IDLE;
              else if (pf_fb_req_gn_pf0 &  fe_fb_req_fb0.valid ) state_nxt = REQ_PF;
        default:                                                 state_nxt = state;
    endcase
    if (reset) state_nxt = IDLE;
end
`DFF(state, state_nxt, clk)

always_comb pf_fb_req_rq_pf0 = state == REQ_PF;

//
// Logic
//

`DFF_EN(next_line, fe_fb_req_fb0.addr + t_paddr'(CL_SZ_BYTES), clk, fe_fb_req_fb0.valid)

always_comb begin
    pf_fb_req_pkt_pf0 = '0;
    pf_fb_req_pkt_pf0.valid = 1'b1;
    pf_fb_req_pkt_pf0.addr  = next_line;
end

//
// Displays
//

`ifdef ASSERT
`endif



endmodule

`endif // __FE_PF_SV

