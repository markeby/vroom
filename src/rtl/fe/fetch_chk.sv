`ifndef __FETCH_CHK_SV
`define __FETCH_CHK_SV

`include "instr.pkg"
`include "verif.pkg"
`include "asm.pkg"
`include "mem_common.pkg"
`include "vroom_macros.sv"

module fetch_chk
    import instr::*, common::*, mem_common::*, verif::*;
(
    input  logic       clk,
    input  logic       reset,
    input  logic       decode_ready_de0,

    input  logic       valid_fe1,
    input  t_instr_pkt instr_fe1,

    input  t_br_mispred_pkt br_mispred_ex0,
    input  t_nuke_pkt       nuke_rb1
);

typedef enum logic[2:0] {
    IDLE,
    PDG_NXT_SEQ,
    PDG_BRANCH
} t_fsm;

//
// Fake stuff
//

//
// Nets
//

t_paddr  PC;
t_fsm state;
t_fsm state_nxt;

logic br_mispred_ql_ex0;
assign br_mispred_ql_ex0 = fe.fe_ctl.br_mispred_ql_ex0;

//
// Logic
//

always_comb begin
    state_nxt = state;
    unique case(state)
        IDLE:         if (valid_fe1 & decode_ready_de0 ) state_nxt = PDG_NXT_SEQ;
        PDG_NXT_SEQ:  if (br_mispred_ql_ex0            ) state_nxt = PDG_BRANCH;
        PDG_BRANCH:   if (valid_fe1 & decode_ready_de0 ) state_nxt = PDG_NXT_SEQ;
        default:                                         state_nxt = PDG_NXT_SEQ;
    endcase
    if (reset) state_nxt = IDLE;
end
`DFF(state, state_nxt, clk)

// PC

t_paddr PCNxt;
always_comb begin
    PCNxt = PC;
    if (valid_fe1 & decode_ready_de0 & state == IDLE) begin
        PCNxt = instr_fe1.pc + t_paddr'(4);;
    end else if(br_mispred_ql_ex0) begin
        PCNxt = br_mispred_ex0.restore_pc;
    end else if(valid_fe1 & decode_ready_de0) begin
        PCNxt = PC + t_paddr'(4);;
    end else begin
        PCNxt = PC;
    end
end
`DFF(PC, PCNxt, clk)

//
// Displays
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (valid_fe1 & decode_ready_de0 & ~reset) begin
        `INFO(("unit:FE pc:%h %s", PC, describe_instr(instr_fe1)))
    end
end
`endif

`ifdef ASSERT
    `VASSERT(a_bad_fetch_addr, state != IDLE & valid_fe1 & decode_ready_de0, valid_fe1 & instr_fe1.pc == PC, $sformatf("Incorrect PC fetched (%s): exp(%h) != act(%h)", state.name(), PC, instr_fe1.pc))
`endif


endmodule

`endif // __FETCH_CHK_SV

