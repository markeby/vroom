`ifndef __FE_CTL_SV
`define __FE_CTL_SV

`include "instr.pkg"
`include "verif.pkg"
`include "asm.pkg"
`include "mem_common.pkg"
`include "vroom_macros.sv"

module fe_ctl
    import instr::*, common::*, mem_common::*, verif::*;
(
    input  logic       clk,
    input  logic       reset,
    input  t_nuke_pkt  nuke_rb1,

    output t_fe_fb_req fe_fb_req_nnn,
    input  t_fb_fe_rsp fb_fe_rsp_nnn,

    input  t_br_mispred_pkt br_mispred_ex0,

    output logic       valid_fe1,
    output t_instr_pkt instr_fe1,
    input  logic       stall
);

typedef enum logic[2:0] {
    FE_IDLE,
    FE_REQ_IC,
    FE_PDG_IC,
    FE_PDG_STALL,
    FE_DRAIN,
    FE_HALT,
    FE_PDG_NUKE
} t_fsm_fe;

//
// Fake stuff
//

`ifdef SIMULATION
int instr_cnt_inst;
int instr_cnt_inst_nxt;
assign instr_cnt_inst_nxt = reset                ? '0                 :
                            (valid_fe1 & ~stall) ? instr_cnt_inst + 1 :
                                                   instr_cnt_inst;

`DFF(instr_cnt_inst, instr_cnt_inst_nxt, clk)
`endif

//
// Nets
//

logic    incr_pc_nnn;
t_paddr  PC;
t_fsm_fe state;
t_fsm_fe state_nxt;

//
// Logic
//

t_rv_instr fb_fe_rsp_nnn_instr;
assign fb_fe_rsp_nnn_instr = fb_fe_rsp_nnn.instr;

logic nuke_pdg;
`DFF(nuke_pdg, ~reset & (nuke_pdg & ~nuke_rb1.valid | br_mispred_ex0.valid), clk)

always_comb begin
    state_nxt = state;
    unique case(state)
        FE_IDLE:      if (1'b1                                   ) state_nxt = FE_REQ_IC;
        FE_REQ_IC:    if (1'b1                                   ) state_nxt = FE_PDG_IC;
        FE_PDG_IC:    if (fb_fe_rsp_nnn.valid &  nuke_pdg        ) state_nxt = FE_PDG_NUKE;  // wait for nuke
                 else if (fb_fe_rsp_nnn.valid &  stall           ) state_nxt = FE_PDG_STALL; // wait for stall to resolve
                 else if (fb_fe_rsp_nnn.valid & ~stall           ) state_nxt = FE_PDG_IC;    // no stall or nuke -> early send
        FE_PDG_STALL: if (~stall                                 ) state_nxt = FE_PDG_IC;
        FE_DRAIN:     if (~stall                                 ) state_nxt = FE_HALT;
        FE_PDG_NUKE:  if (nuke_rb1.valid                         ) state_nxt = FE_PDG_STALL; // after a nuke, head to FE_PDG_STALL state; we can request from thre
        default:                                                   state_nxt = state;
    endcase
    if (reset) state_nxt = FE_IDLE;
end
`DFF(state, state_nxt, clk)

// PC

assign incr_pc_nnn = fe_fb_req_nnn.valid;

t_paddr PCNxt;
always_comb PCNxt = reset          ? '0         :
                    br_mispred_ex0.valid ? br_mispred_ex0.target_addr :
                    incr_pc_nnn    ? PC + 4     :
                                     PC;
`DFF(PC, PCNxt, clk)

// Capture response

t_fb_fe_rsp fb_fe_capture_nnn;
`DFF_EN(fb_fe_capture_nnn, fb_fe_rsp_nnn, clk, fb_fe_rsp_nnn.valid)

// IC req

always_comb begin
    fe_fb_req_nnn = '0;
    fe_fb_req_nnn.valid = state == FE_REQ_IC
                        | state == FE_PDG_IC    & ~stall & fb_fe_rsp_nnn.valid
                        | state == FE_PDG_STALL & ~stall;
    fe_fb_req_nnn.addr  = PC;
    fe_fb_req_nnn.id    = 0;
end

// Outputs to decode

`ifdef SIMULATION
logic stall_after_n_instr_en;
int   stall_after_n_instr;
logic fake_stall_now;
initial begin
    stall_after_n_instr = '0;
    if ($value$plusargs("stall_after_n_instr:%d", stall_after_n_instr)) begin
        $display("Saw +stall_after_n_instr");
    end else begin
        $display("Did NOT see +stall_after_n_instr");
    end

    stall_after_n_instr_en = (stall_after_n_instr > 0);
end

`DFF_EN(stall_after_n_instr, (stall_after_n_instr - 1), clk, (valid_fe1 & (stall_after_n_instr > 0)))
assign fake_stall_now = stall_after_n_instr_en & (stall_after_n_instr == 0);
`endif

always_comb begin
    automatic t_fb_fe_rsp ic_rsp;
    ic_rsp = (state == FE_PDG_IC) ? fb_fe_rsp_nnn : fb_fe_capture_nnn;

    valid_fe1           = ( state == FE_PDG_IC & fb_fe_rsp_nnn.valid
                          | state == FE_PDG_STALL
                          | state == FE_DRAIN
                          ) & ~nuke_pdg & ~fake_stall_now;
    instr_fe1       = t_instr_pkt'('0);
    instr_fe1.instr = ic_rsp.instr;
    instr_fe1.pc    = ic_rsp.pc;
    `ifdef SIMULATION
    instr_fe1.SIMID = `SIMID_CREATE_RHS(FETCH,instr_cnt_inst,ic_rsp.pc);
    `endif //SIMULATION
end

//
// Displays
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (valid_fe1 & ~stall & ~reset) begin
        `UINFO(instr_fe1.SIMID, ("unit:FE pc:%h %s", PC, describe_instr(instr_fe1)))
    end
end
`endif

`ifdef ASSERT

    /*
logic valid_fe2_inst;

`DFF(instr_pkt_fe2,  instr_pkt_fe1, clk)
`DFF(valid_fe2_inst, valid_fe1,     clk)

`VASSERT(a_lost_instr, valid_fe1 & valid_fe2_inst & instr_pkt_fe1.SIMID != instr_pkt_fe2.SIMID, core.decode.uinstr_de1.SIMID == instr_pkt_fe2.SIMID, $sformatf("Lost an instruction with simid:%s", format_simid(instr_pkt_fe2.SIMID)))
*/

//chk_no_change #(.T(t_instr_pkt)) cnc ( .clk, .reset, .hold(stall & valid_fe1), .thing(instr_pkt_fe1) );
`endif


endmodule

`endif // __FE_CTL_SV

