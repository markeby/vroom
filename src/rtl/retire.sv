`ifndef __RETIRE_SV
`define __RETIRE_SV

`include "instr.pkg"
`include "vroom_macros.sv"

module retire
    import instr::*, instr_decode::*, verif::*;
(
    input  logic             clk,
    input  logic             reset,
    input  t_uinstr          uinstr_rb0,
    input  t_rv_reg_data     result_rb0,

    output logic             wren_rb0,
    output t_rv_reg_addr     wraddr_rb0,
    output t_rv_reg_data     wrdata_rb0
);

localparam RB0 = 0;
localparam RB1 = 1;
localparam NUM_RB_STAGES = 1;

`MKPIPE_INIT(t_uinstr,       uinstr_rbx, uinstr_rb0, RB0, NUM_RB_STAGES)

//
// Nets
//

//
// Logic
//

//
// RB0
//

always_comb wren_rb0   = uinstr_rb0.dst.optype == OP_REG & uinstr_rb0.valid;
always_comb wraddr_rb0 = uinstr_rb0.dst.opreg;
always_comb wrdata_rb0 = result_rb0;

//
// RB1
//

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (uinstr_rb0.valid) begin
        `INFO(("unit:RB %s result:%08h", describe_uinstr(uinstr_rb0), result_rb0))
    end
end
`endif

`ifdef ASSERT
logic   last_ret_simid_valid;
t_simid last_ret_simid;

`DFF(last_ret_simid_valid, ~reset & (uinstr_rb0.valid | last_ret_simid_valid), clk)
`DFF_EN(last_ret_simid, uinstr_rb0.SIMID.fid, clk, uinstr_rb0.valid)
`VASSERT(a_mono_incr_fid, uinstr_rb0.valid & last_ret_simid_valid, uinstr_rb0.SIMID.fid > last_ret_simid, "RB: Fetch ID not mononotically increasing!")
`endif

endmodule

`endif // __RETIRE_SV

