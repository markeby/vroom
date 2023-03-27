`ifndef __RETIRE_SV
`define __RETIRE_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "common.pkg"

module retire
    import instr::*, instr_decode::*, verif::*, common::*;
(
    input  logic             clk,
    input  logic             reset,
    input  t_uinstr          uinstr_mm1,
    input  t_rv_reg_data     result_mm1,

    output t_uinstr          uinstr_rb1,
    output logic             wren_rb1,
    output t_rv_reg_addr     wraddr_rb1,
    output t_rv_reg_data     wrdata_rb1,

    output logic             br_mispred_rb1,
    output t_paddr           br_tgt_rb1
);

localparam RB0 = 0;
localparam RB1 = 1;
localparam NUM_RB_STAGES = 1;

`MKPIPE_INIT(t_rv_reg_data,  result_rbx, result_mm1, RB0, NUM_RB_STAGES)

t_uinstr uinstr_rb0;

//
// Nets
//

//
// Logic
//

//
// RB0
//

always_comb uinstr_rb0 = uinstr_mm1;
always_comb wren_rb1   = uinstr_rb1.dst.optype == OP_REG & uinstr_rb1.valid;
always_comb wraddr_rb1 = uinstr_rb1.dst.opreg;
always_comb wrdata_rb1 = result_rbx[RB1];

//
// RB1
//

`DFF(uinstr_rb1, uinstr_rb0, clk)

always_comb br_mispred_rb1 = uinstr_rb1.valid
                           & uinstr_rb1.mispred;
always_comb br_tgt_rb1     = result_rbx[RB1];

//
// Debug
//

`ifdef SIMULATION

localparam FAIL_DLY = 10;
logic[FAIL_DLY:0] boom_pipe;
`DFF(boom_pipe[FAIL_DLY:1], boom_pipe[FAIL_DLY-1:0], clk);

always @(posedge clk) begin
    boom_pipe[0] <= 1'b0;
    if (uinstr_mm1.valid) begin
        `INFO(("unit:RB %s result:%08h", describe_uinstr(uinstr_mm1), result_mm1))
        print_retire_info(uinstr_mm1);
    end

    if (wren_rb1 & wraddr_rb1 == 0 & wrdata_rb1 == 32'h666) begin
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
chk_always_increment #(.T(int)) fid_counting_up (
    .clk,
    .reset,
    .valid ( uinstr_mm1.valid     ),
    .count ( uinstr_mm1.SIMID.fid )
);
`endif

endmodule

`endif // __RETIRE_SV

