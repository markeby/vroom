`ifndef __EXE_SV
`define __EXE_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "common.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"
`include "verif.pkg"

module exe
    import instr::*, instr_decode::*, common::*, rob_defs::*, verif::*;
(
    input  logic         clk,
    input  logic         reset,
    input  t_nuke_pkt    nuke_rb1,

    input  logic         iss_ex0,
    input  t_iss_pkt  iss_pkt_ex0,

    output t_br_mispred_pkt br_mispred_ex0,

    output logic         iprf_wr_en_ex1,
    output t_prf_wr_pkt  iprf_wr_pkt_ex1,

    output t_rob_complete_pkt complete_ex1
);

localparam EX0 = 0;
localparam EX1 = 1;
localparam NUM_EX_STAGES = 1;

//
// Nets
//

t_rv_reg_data src1val_ex0;
t_rv_reg_data src2val_ex0;

t_uinstr uinstr_ex0;
t_uinstr uinstr_ql_ex0;

logic         ialu_resvld_ex0;
t_rv_reg_data ialu_result_ex0;

logic         ibr_resvld_ex0;
t_paddr       ibr_tgt_ex0;
t_br_mispred_pkt ibr_mispred_ex0;

`MKPIPE_INIT(logic,          iss_exx,    iss_ex0,            EX0, NUM_EX_STAGES)
`MKPIPE_INIT(t_uinstr,       uinstr_exx, uinstr_ql_ex0,      EX0, NUM_EX_STAGES)
`MKPIPE_INIT(t_rob_id,       robid_exx,  iss_pkt_ex0.robid,  EX0, NUM_EX_STAGES)
`MKPIPE_INIT(t_prf_id,       pdst_exx,   iss_pkt_ex0.pdst,   EX0, NUM_EX_STAGES)
`MKPIPE_INIT(t_br_mispred_pkt, ibr_mispred_exx, ibr_mispred_ex0, EX0, NUM_EX_STAGES)
`MKPIPE     (t_rv_reg_data,  result_exx,                     EX0, NUM_EX_STAGES)

//
// Logic
//

assign uinstr_ex0 = iss_pkt_ex0.uinstr;

always_comb begin
    uinstr_ql_ex0 = uinstr_ex0;
    uinstr_ql_ex0.mispred = ibr_mispred_ex0.valid;
end

//
// EX0
//

always_comb src1val_ex0 = iss_pkt_ex0.src1_val;
always_comb src2val_ex0 = (uinstr_ex0.src2.optype == OP_REG ? iss_pkt_ex0.src2_val : '0)
                        | (uinstr_ex0.src2.optype == OP_IMM ? uinstr_ex0.imm64     : '0);

// Execution units

ialu ialu (
    .clk,
    .reset,

    .uinstr_ex0,
    .src1val_ex0,
    .src2val_ex0,

    .resvld_ex0  ( ialu_resvld_ex0 ),
    .result_ex0  ( ialu_result_ex0 )
);

ibr ibr (
    .clk,
    .reset,

    .iss_pkt_ex0,
    .src1val_ex0,
    .src2val_ex0,

    .resvld_ex0     ( ibr_resvld_ex0  ),
    .br_mispred_ex0 ( ibr_mispred_ex0 )
);
assign br_mispred_ex0 = ibr_mispred_ex0;

// Combine outputs

always_comb begin
    result_exx[EX0]  = '0;
    result_exx[EX0] |= ialu_resvld_ex0 ? ialu_result_ex0 : '0;
end

`ifdef ASSERT
logic LOL;
always_comb LOL = uinstr_ex0.uop inside {U_INVALID, U_EBREAK, U_ECALL};

`CHK_ONEHOT(exe_rslt_valid, iss_ex0, {LOL,ialu_resvld_ex0,ibr_resvld_ex0})
`endif

//
// EX1
//

always_comb begin
    complete_ex1.valid = iss_exx[EX1];
    complete_ex1.mispred = ibr_mispred_exx[EX1].valid;
    complete_ex1.robid = robid_exx[EX1];

    iprf_wr_en_ex1 = iss_exx[EX1] & uinstr_exx[EX1].dst.optype == OP_REG;
    iprf_wr_pkt_ex1.pdst = pdst_exx[EX1];
    iprf_wr_pkt_ex1.data = result_exx[EX1];
    `ifdef SIMULATION
    iprf_wr_pkt_ex1.SIMID = uinstr_exx[EX1].SIMID;
    `endif
end

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (iss_exx[EX1]) begin
        `UINFO(uinstr_exx[EX1].SIMID, ("unit:EX pdst:%s result:%08h %s", f_describe_prf(pdst_exx[EX1]), result_exx[EX1], describe_uinstr(uinstr_exx[EX1])))
    end
end
`endif

`ifdef ASSERT
//VASSERT(a_br_mispred, uinstr_rd1.valid & ibr_resvld_ex0, ~ibr_mispred_ex0, "Branch mispredictions not yet supported.")
`endif

endmodule

`endif // __EXE_SV

