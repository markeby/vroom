`ifndef __EXE_SV
`define __EXE_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "common.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"

module exe
    import instr::*, instr_decode::*, common::*, rob_defs::*;
(
    input  logic         clk,
    input  logic         reset,
    input  logic         stall,

    input  logic         iss_ex0,
    input  t_uinstr_iss  iss_pkt_ex0,

    input  logic         br_mispred_rb1,

    output logic         iprf_wr_en_ex1,
    output t_prf_wr_pkt  iprf_wr_pkt_ex1,

    output logic         ro_valid_ex1,
    output t_rob_result  ro_result_ex1
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
logic         ibr_mispred_ex0;

`MKPIPE_INIT(t_uinstr,       uinstr_exx, uinstr_ql_ex0,      EX0, NUM_EX_STAGES)
`MKPIPE_INIT(t_rob_id,       robid_exx,  iss_pkt_ex0.robid,  EX0, NUM_EX_STAGES)
`MKPIPE_INIT(t_prf_id,       pdst_exx,   iss_pkt_ex0.pdst,   EX0, NUM_EX_STAGES)
`MKPIPE_INIT(logic,          ibr_mispred_exx, ibr_mispred_ex0, EX0, NUM_EX_STAGES)
`MKPIPE     (t_rv_reg_data,  result_exx,                     EX0, NUM_EX_STAGES)

//
// Logic
//

assign uinstr_ex0 = iss_pkt_ex0.uinstr;

always_comb begin
    uinstr_ql_ex0 = uinstr_ex0;
    uinstr_ql_ex0.mispred = ibr_mispred_ex0;
    `ifdef SIMULATION
    uinstr_ql_ex0.SIMID.src1_val   = src1val_ex0;
    uinstr_ql_ex0.SIMID.src2_val   = src2val_ex0;
    uinstr_ql_ex0.SIMID.result_val = result_exx[EX0];
    `endif
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

    .uinstr_ex0,
    .src1val_ex0,
    .src2val_ex0,

    .resvld_ex0     ( ibr_resvld_ex0  ),
    .br_tgt_ex0     ( ibr_tgt_ex0     ),
    .br_mispred_ex0 ( ibr_mispred_ex0 )
);

// Combine outputs

always_comb begin
    result_exx[EX0]  = '0;
    result_exx[EX0] |= ialu_resvld_ex0 ? ialu_result_ex0 : '0;
    result_exx[EX0] |= ibr_resvld_ex0  ? ibr_tgt_ex0     : '0;
end

`ifdef ASSERT
logic LOL;
always_comb LOL = uinstr_ex0.uop == U_INVALID;

`CHK_ONEHOT(exe_rslt_valid, uinstr_ex0.valid, {LOL,ialu_resvld_ex0,ibr_resvld_ex0})
`endif

//
// EX1
//

always_comb begin
    ro_valid_ex1 = uinstr_exx[EX1].valid;
    ro_result_ex1.mispred = ibr_mispred_exx[EX1];
    ro_result_ex1.robid = robid_exx[EX1];

    iprf_wr_en_ex1 = ro_valid_ex1;
    iprf_wr_pkt_ex1.pdst = pdst_exx[EX1];
    iprf_wr_pkt_ex1.data = result_exx[EX1];
end

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (uinstr_ex0.valid) begin
        `INFO(("unit:EX %s result:%08h", describe_uinstr(uinstr_ex0), result_exx[EX0]))
    end
end
`endif

`ifdef ASSERT
//VASSERT(a_br_mispred, uinstr_rd1.valid & ibr_resvld_ex0, ~ibr_mispred_ex0, "Branch mispredictions not yet supported.")
`endif

endmodule

`endif // __EXE_SV

