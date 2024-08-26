`ifndef __FE_BUF_ENTRY_SV
`define __FE_BUF_ENTRY_SV

`include "instr.pkg"
`include "verif.pkg"
`include "asm.pkg"
`include "mem_common.pkg"
`include "instr.pkg"
`include "vroom_macros.sv"

typedef struct packed {
    mem_common::t_fe_fb_req req;
    logic                   pf;
} t_fe_fb_static;

typedef struct packed {
    instr::t_rv_instr instr;
} t_fe_fb_active;

module fe_fb_entry
    import instr::*, common::*, mem_common::*, verif::*;
(
    input  logic           clk,
    input  logic           reset,

    // Entry state
    input  logic           e_push_fb0,
    input  t_fe_fb_static  c_push_static_fb0,

    output logic           e_valid_nnn,
    output t_fe_fb_static  e_static_nnn,
    output t_fe_fb_active  e_active_nnn,

    // IC req
    output logic           e_ic_req_rq_nnn,
    output t_mem_req       e_ic_req_pkt_nnn,
    input  logic           e_ic_req_gn_nnn,

    // IC rsp
    input  t_mem_rsp       e_ic_rsp_pkt_nnn,

    // FE req
    output logic           e_fe_rsp_rq_nnn,
    output t_fb_fe_rsp     e_fe_rsp_pkt_nnn,
    input  logic           e_fe_rsp_gn_nnn
);

typedef enum logic[2:0] {
    IDLE,
    REQ_IC,
    PDG_IC,
    REQ_FE
} t_fsm;

//
// Nets
//

t_fsm state, state_nxt;

//
// Miss FSM
//

always_comb begin
    state_nxt = state;
    unique case(state)
        IDLE:      if (e_push_fb0                                ) state_nxt = REQ_IC;
        REQ_IC:    if (e_ic_req_gn_nnn                           ) state_nxt = PDG_IC;
        PDG_IC:    if (e_ic_rsp_pkt_nnn.valid & ~e_static_nnn.pf ) state_nxt = REQ_FE;
              else if (e_ic_rsp_pkt_nnn.valid &  e_static_nnn.pf ) state_nxt = IDLE;
        REQ_FE:    if (e_fe_rsp_gn_nnn                           ) state_nxt = IDLE;
        default:                                                   state_nxt = state;
    endcase
    if (reset) state_nxt = IDLE;
end
`DFF(state, state_nxt, clk)

always_comb e_valid_nnn     = state != IDLE;
always_comb e_ic_req_rq_nnn = state == REQ_IC;

//
// Logic
//

`DFF_EN(e_static_nnn, c_push_static_fb0, clk, e_push_fb0)

always_comb begin
    e_ic_req_pkt_nnn       = '0;
    e_ic_req_pkt_nnn.valid = 1'b1;
    e_ic_req_pkt_nnn.addr  = e_static_nnn.req.addr;
end

`DFF_EN(e_active_nnn.instr, instr_from_cl(e_ic_rsp_pkt_nnn.data, get_cl_offset(e_static_nnn.req.addr)), clk, e_ic_rsp_pkt_nnn.valid)

always_comb begin
    e_fe_rsp_rq_nnn        = state == REQ_FE;

    e_fe_rsp_pkt_nnn       = '0;
    e_fe_rsp_pkt_nnn.valid = state == REQ_FE;
    e_fe_rsp_pkt_nnn.instr = e_active_nnn.instr;
    e_fe_rsp_pkt_nnn.pc    = e_static_nnn.req.addr;
end


//
// Displays
//

`ifdef ASSERT
`endif


endmodule

`endif // __FE_BUF_ENTRY_SV

