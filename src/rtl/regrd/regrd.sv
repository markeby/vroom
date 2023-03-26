`ifndef __REGRD_SV
`define __REGRD_SV

`include "instr.pkg"
`include "vroom_macros.sv"

module regrd
    import instr::*, instr_decode::*;
(
    input  logic             clk,
    input  logic             reset,
    input  t_uinstr          uinstr_de1,
    input  logic             stall,
    input  logic             br_mispred_rb1,

    output logic             rdens_rd0   [1:0],
    output t_rv_reg_addr     rdaddrs_rd0 [1:0],
    input  t_rv_reg_data     rddatas_rd1 [1:0],

    output t_uinstr          uinstr_rd1
);

localparam RD0 = 0;
localparam RD1 = 1;
localparam NUM_RD_STAGES = 1;

//
// Nets
//

//
// Logic
//

//
// RD0
//

always_comb begin
    rdens_rd0[0]   = uinstr_de1.valid & uinstr_de1.src1.optype == OP_REG & ~stall;
    rdaddrs_rd0[0] = uinstr_de1.src1.opreg;
    rdens_rd0[1]   = uinstr_de1.valid & uinstr_de1.src2.optype == OP_REG & ~stall;
    rdaddrs_rd0[1] = uinstr_de1.src2.opreg;
end

//
// RD1
//

t_uinstr uinstr_ql_rd0;
always_comb begin
    uinstr_ql_rd0 = uinstr_de1;
    uinstr_ql_rd0.valid &= ~stall;
end
`DFF(uinstr_rd1, uinstr_ql_rd0, clk);

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (uinstr_de1.valid) begin
        `INFO(("unit:RD %s", describe_uinstr(uinstr_de1)))
    end
end
`endif

`ifdef ASSERT
//chk_no_change #(.T(t_uinstr)) cnc ( .clk, .reset, .hold(stall & uinstr_ex0.valid), .thing(uinstr_ex0) );
`endif

endmodule

`endif // __REGRD_SV

