`ifndef __DECODE_SV
`define __DECODE_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "vroom_macros.sv"
`include "gen_funcs.pkg"
`include "common.pkg"
`include "verif.pkg"

module decode
    import instr::*, instr_decode::*, gen_funcs::*, common::*, verif::*;
(
    input  logic             clk,
    input  logic             reset,
    input  t_nuke_pkt        nuke_rb1,
    output logic             decode_ready_de0,
    input  logic             ucode_ready_uc0,

    input  logic             valid_fe1,
    input  t_instr_pkt       instr_fe1,

    output logic             valid_de1,
    output t_uinstr          uinstr_de1
);

localparam DE0 = 0;
localparam DE1 = 1;
localparam NUM_DE_STAGES = 1;

`MKPIPE(logic,    valid_dex,  DE0, NUM_DE_STAGES)

//
// Nets
//

t_rv_instr        rv_instr_fe1;
t_uinstr          uinstr_de0;

`ifdef SIMULATION
int instr_cnt_inst;
`DFF(instr_cnt_inst, reset ? '0 : instr_cnt_inst + int'(valid_dex[DE0]), clk)
`endif

//
// Logic
//

always_comb rv_instr_fe1 = instr_fe1.instr;

//
// DE0
//

always_comb valid_dex[DE0] = valid_fe1 & ~reset;

always_comb begin
    if (reset) begin
        uinstr_de0 = '0;
    end else begin
        uinstr_de0 = f_decode_rv_instr(rv_instr_fe1);
        uinstr_de0.pc = instr_fe1.pc;
        `ifdef SIMULATION
        uinstr_de0.SIMID = instr_fe1.SIMID;
        `endif
    end
end

//
// DE1/RD0
//

logic uopq_full;
logic uopq_pop_de1;
logic uopq_push_de0;
t_uinstr uinstr_fe_de1;

logic ebreak_seen;
`DFF(ebreak_seen, ~reset & ~nuke_rb1.valid & (ebreak_seen | uopq_push_de0 & uinstr_de0.uop == U_EBREAK), clk)

assign uopq_push_de0 = valid_dex[DE0] & ~ebreak_seen & ~nuke_rb1.valid & decode_ready_de0;

logic uopq_valid_de1;
gen_fifo #(
    .NPUSH(1), .NPOP(1), .DEPTH(2), .T(t_uinstr), .NAME("UOP_QUEUE")
) uop_queue (
    .clk,
    .reset          ( reset | nuke_rb1.valid ) ,
    .full           ( uopq_full         ) ,
    .empty          (                   ) ,
    .push_front_xw0 ( '{uopq_push_de0}  ) ,
    .num_push_ok    (                   ) ,
    .din_xw0        ( '{uinstr_de0}     ) ,
    .pop_back_xr0   ( '{uopq_pop_de1}   ) ,
    .valid_xr0      ( '{uopq_valid_de1} ) ,
    .dout_xr0       ( '{uinstr_fe_de1}  )
);

assign uopq_pop_de1 = uopq_valid_de1 & ucode_ready_uc0;
assign valid_de1 = uopq_pop_de1;

always_comb begin
    uinstr_de1 = uinstr_fe_de1;
end

assign decode_ready_de0 = ~uopq_full;

`ifdef ASSERT
logic during_nuke_inst;
`DFF(during_nuke_inst, ~reset & ~core.resume_fetch_rbx & (during_nuke_inst | (nuke_rb1.valid & nuke_rb1.nuke_fe)), clk)
    `VASSERT(a_push_during_nuke, uopq_push_de0, ~during_nuke_inst, "decode uopq pushed during branch correction window")
`endif

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (valid_dex[DE0]) begin
        `UINFO(uinstr_de0.SIMID, ("unit:DE func:uopq_push %s", describe_uinstr(uinstr_de0)))
    end
    if (uopq_valid_de1 & ~valid_de1) begin
        `UINFO(uinstr_fe_de1.SIMID, ("unit:DE func:uopq_stalled %s", describe_uinstr(uinstr_de1)))
    end
    if (valid_de1) begin
        `UINFO(uinstr_de1.SIMID, ("unit:DE func:uopq_pop %s", describe_uinstr(uinstr_de1)))
    end
end
`endif

`ifdef ASSERT
//chk_no_change #(.T(t_uinstr)) cnc ( .clk, .reset, .hold(stall & uinstr_de1.valid & ~br_mispred_rb1), .thing(uinstr_de1) );
`endif

endmodule

`endif // __DECODE_SV

