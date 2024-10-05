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
    input  logic       resume_fetch_rbx,
    input  t_rob_id    oldest_robid,

    output t_fe_fb_req fe_fb_req_fb0,
    input  t_fb_fe_rsp fb_fe_rsp_fb0,

    input  t_br_mispred_pkt br_mispred_ex0,

    output logic       valid_fe1,
    output t_instr_pkt instr_fe1,
    input  logic       decode_ready_de0
);

typedef enum logic[2:0] {
    FE_IDLE,
    FE_REQ_IC,
    FE_PDG_NUKE
} t_fsm_fe;

//
// Fake stuff
//

`ifdef SIMULATION
int instr_cnt_inst;
int instr_cnt_inst_nxt;
assign instr_cnt_inst_nxt = reset                          ? '0                 :
                            (valid_fe1 & decode_ready_de0) ? instr_cnt_inst + 1 :
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
logic    nuke_rb1_valid_ql;
logic    br_mispred_ql_ex0;

//
// Logic
//

t_rv_instr fb_fe_rsp_fb0_instr;
assign fb_fe_rsp_fb0_instr = fb_fe_rsp_fb0.instr;

assign nuke_rb1_valid_ql = nuke_rb1.valid & nuke_rb1.nuke_fe;

logic nuke_pdg;
`DFF(nuke_pdg, ~reset & (nuke_pdg & ~nuke_rb1_valid_ql | br_mispred_ql_ex0), clk)

always_comb begin
    state_nxt = state;
    unique case(state)
        FE_IDLE:      if (1'b1                                   ) state_nxt = FE_REQ_IC;
        FE_REQ_IC:    if (nuke_pdg | nuke_rb1_valid_ql           ) state_nxt = FE_PDG_NUKE;
        FE_PDG_NUKE:  if (resume_fetch_rbx                       ) state_nxt = FE_REQ_IC; // after a nuke, start fetching again
        default:                                                   state_nxt = state;
    endcase
    if (reset) state_nxt = FE_IDLE;
end
`DFF(state, state_nxt, clk)

// Misprediction

logic    br_mispred_pdg;
t_rob_id br_mispred_robid;

assign br_mispred_ql_ex0 = br_mispred_ex0.valid & (~br_mispred_pdg | f_robid_a_older_b(br_mispred_ex0.robid, br_mispred_robid, oldest_robid));

`DFF(br_mispred_pdg, ~reset & ~nuke_rb1_valid_ql & (br_mispred_pdg | br_mispred_ql_ex0), clk)
`DFF_EN(br_mispred_robid, br_mispred_ex0.robid, clk, br_mispred_ql_ex0)

// PC

assign incr_pc_nnn = valid_fe1 & decode_ready_de0;

t_paddr PCNxt;
t_paddr PCRst;

initial begin
    PCRst = '0;
    $value$plusargs("boot_vector:%h", PCRst);
end
always_comb PCNxt = reset          ? PCRst      :
                    br_mispred_ql_ex0 ? br_mispred_ex0.restore_pc :
                    incr_pc_nnn    ? PC + 4     :
                                     PC;
`DFF(PC, PCNxt, clk)

// IC req

always_comb begin
    fe_fb_req_fb0 = '0;
    fe_fb_req_fb0.valid = state == FE_REQ_IC;
    fe_fb_req_fb0.addr  = PC;
    fe_fb_req_fb0.id    = 0;
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
    valid_fe1       = state == FE_REQ_IC & fb_fe_rsp_fb0.valid & ~nuke_pdg & ~fake_stall_now;
    instr_fe1       = t_instr_pkt'('0);
    instr_fe1.instr = fb_fe_rsp_fb0.instr;
    instr_fe1.pc    = fb_fe_rsp_fb0.pc;
    `ifdef SIMULATION
    instr_fe1.SIMID = `SIMID_CREATE_RHS(FETCH,instr_cnt_inst,fb_fe_rsp_fb0.pc);
    `endif //SIMULATION
end

//
// Displays
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (valid_fe1 & decode_ready_de0 & ~reset) begin
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

