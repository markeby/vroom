`ifndef __RS_SV
`define __RS_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "common.pkg"
`include "vroom_macros.sv"

module rs #( parameter int NUM_RS_ENTS = 8 )
    import instr::*, instr_decode::*, common::*;
(
    input  logic          clk,
    input  logic          reset,

    input  logic          wb_valid_ro1,
    input  t_rob_id       wb_robid_ro1,
    input  t_rv_reg_data  wb_result_ro1,

    output logic          rs_stall_rs0,
    input  t_uinstr_disp  uinstr_rs0,
    input  t_rv_reg_data  rddatas_rs0 [1:0],

    output logic          issue_rs1,
    output t_uinstr       uinstr_rs1
);

localparam RS0 = 0;
localparam RS1 = 1;
localparam NUM_EX_STAGES = 1;

//
// Nets
//

//
// Logic
//

//
// RS0
//

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (uinstr_rd1.valid) begin
        `INFO(("unit:EX %s result:%08h", describe_uinstr(uinstr_rd1), result_exx[RS0]))
    end
end
`endif

`ifdef ASSERT
//VASSERT(a_br_mispred, uinstr_rd1.valid & ibr_resvld_ex0, ~ibr_mispred_ex0, "Branch mispredictions not yet supported.")
`endif

endmodule

`endif // __RS_SV

