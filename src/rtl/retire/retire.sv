`ifndef __RETIRE_SV
`define __RETIRE_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "common.pkg"
`include "rob_defs.pkg"

module retire
    import instr::*, instr_decode::*, verif::*, common::*, rob_defs::*;
(
    input  logic             clk,
    input  logic             reset,
    input  t_uinstr          uinstr_de1,

    input  t_rv_reg_addr     src_addr_ra0          [NUM_SOURCES-1:0],
    output logic             rob_src_reg_pdg_ra0   [NUM_SOURCES-1:0],
    output t_rob_id          rob_src_reg_robid_ra0 [NUM_SOURCES-1:0],

    input  logic             ro_valid_rb0,
    input  rob_defs::t_rob_result
                             ro_result_rb0,

    output t_rob_id          next_robid_ra0,

    output t_uinstr          uinstr_rb1,
    output logic             wren_rb1,
    output t_rv_reg_addr     wraddr_rb1,
    output t_rv_reg_data     wrdata_rb1,

    output logic             br_mispred_rb1,
    output t_paddr           br_tgt_rb1
);

//
// Nets
//

//
// Logic
//

rob rob (
    .clk,
    .reset,
    .uinstr_de1,

    .src_addr_ra0,
    .rob_src_reg_pdg_ra0,
    .rob_src_reg_robid_ra0,

    .ro_valid_rb0,
    .ro_result_rb0,

    .next_robid_ra0,

    .uinstr_rb1,
    .wren_rb1,
    .wraddr_rb1,
    .wrdata_rb1,

    .br_mispred_rb1,
    .br_tgt_rb1
);

//
// Debug
//

`ifdef SIMULATION

localparam FAIL_DLY = 10;
logic[FAIL_DLY:0] boom_pipe;
`DFF(boom_pipe[FAIL_DLY:1], boom_pipe[FAIL_DLY-1:0], clk);

always @(posedge clk) begin
    boom_pipe[0] <= 1'b0;
    // if (uinstr_mm1.valid) begin
    //     `INFO(("unit:RB %s result:%08h", describe_uinstr(uinstr_mm1), result_mm1))
    //     print_retire_info(uinstr_mm1);
    // end

    if (wren_rb1 & wraddr_rb1 == 0 & wrdata_rb1 == 64'h666) begin
        `INFO(("Saw write of 666 to x0... goodbye, folks!"))
        boom_pipe[0] <= 1'b1;
    end

    if (boom_pipe[FAIL_DLY]) begin
        $finish();
        $finish();
        $finish();
    end
end
`endif

`ifdef ASSERT
// chk_always_increment #(.T(int)) fid_counting_up (
//     .clk,
//     .reset,
//     .valid ( uinstr_mm1.valid     ),
//     .count ( uinstr_mm1.SIMID.fid )
// );
`endif

endmodule

`endif // __RETIRE_SV

