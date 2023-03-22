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
                       
    output t_fe_fb_req fe_fb_req_nnn,
    input  t_fb_fe_rsp fb_fe_rsp_nnn,
                       
    output logic       valid_fe1,
    output t_instr_pkt instr_fe1,
    input  logic       stall
);

typedef enum logic[2:0] {
    FE_IDLE,
    FE_REQ_IC,
    FE_PDG_IC,
    FE_PDG_STALL,
    FE_HALT
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

logic halt;
t_rv_instr fb_fe_rsp_nnn_instr;
always_comb fb_fe_rsp_nnn_instr = fb_fe_rsp_nnn.instr;
always_comb halt = fb_fe_rsp_nnn.valid & fb_fe_rsp_nnn_instr.opcode == RV_OP_MISC;

always_comb begin
    state_nxt = state;
    unique case(state) 
        FE_IDLE:      if (~halt                        ) state_nxt = FE_REQ_IC;
        FE_REQ_IC:    if (1'b1                         ) state_nxt = FE_PDG_IC;
        FE_PDG_IC:    if (fb_fe_rsp_nnn.valid & ~stall ) state_nxt = FE_PDG_IC;    // no stall -> early send
                 else if (fb_fe_rsp_nnn.valid &  stall ) state_nxt = FE_PDG_STALL; // wait for stall to resolve
        FE_PDG_STALL: if (~stall                       ) state_nxt = FE_PDG_IC;
        default:                                         state_nxt = state;
    endcase
    if (halt ) state_nxt = FE_HALT;
    if (reset) state_nxt = FE_IDLE;
end
`DFF(state, state_nxt, clk)

// PC

assign incr_pc_nnn = fe_fb_req_nnn.valid;

t_paddr PCNxt;
always_comb PCNxt = reset       ? '0     :
                    incr_pc_nnn ? PC + 4 :
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

always_comb begin
    automatic t_fb_fe_rsp ic_rsp;
    ic_rsp = (state == FE_PDG_IC) ? fb_fe_rsp_nnn : fb_fe_capture_nnn;

    valid_fe1           = state == FE_PDG_IC & fb_fe_rsp_nnn.valid
                        | state == FE_PDG_STALL;
    instr_fe1       = t_instr_pkt'('0);
    instr_fe1.instr = ic_rsp.instr;
    `ifdef SIMULATION
    instr_fe1.SIMID.fid = instr_cnt_inst;
    instr_fe1.SIMID.pc  = ic_rsp.__addr_inst;
    `endif //SIMULATION
end

//
// Displays
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (valid_fe1 & ~stall & ~reset) begin
        `INFO(("unit:FE pc:%h %s", PC, describe_instr(instr_fe1)))
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

