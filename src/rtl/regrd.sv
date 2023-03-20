`ifndef __REGRD_SV
`define __REGRD_SV

`include "instr.pkg"
`include "vroom_macros.sv"

module regrd
    import instr::*;
(
    input  logic             clk,
    input  logic             reset,
    input  logic             valid_rd0,
    input  t_uinstr          uinstr_rd0,

    output logic             rdens_rd0   [1:0],
    output t_rv_reg_addr     rdaddrs_rd0 [1:0],
    input  t_rv_reg_data     rddatas_rd1 [1:0],

    output logic             valid_ex0,
    output t_uinstr          uinstr_ex0,
    output t_rv_reg_data     rddatas_ex0 [1:0]
);

localparam RD0 = 0;
localparam RD1 = 1;
localparam NUM_RD_STAGES = 1;

`MKPIPE_INIT(logic,          valid_rdx,  valid_rd0,  RD0, NUM_RD_STAGES)
`MKPIPE_INIT(t_uinstr,       uinstr_rdx, uinstr_rd0, RD0, NUM_RD_STAGES)

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
    rdens_rd0[0]   = valid_rdx[RD0] & uinstr_rdx[RD0].src1.optype == OP_REG;
    rdaddrs_rd0[0] = uinstr_rdx[RD0].src1.opreg;
    rdens_rd0[1]   = valid_rdx[RD0] & uinstr_rdx[RD0].src2.optype == OP_REG;
    rdaddrs_rd0[1] = uinstr_rdx[RD0].src2.opreg;
end

//
// RD1
//

// EX0 assigns

always_comb valid_ex0   = valid_rdx[RD1];
always_comb uinstr_ex0  = uinstr_rdx[RD1];
always_comb rddatas_ex0 = rddatas_rd1;

//
// Debug
//

    /*
`ifdef SIMULATION
always @(posedge clk) begin
    if (uinstr_de0.valid) begin
        `INFO(("unit:DE %s", describe_uinstr(uinstr_de0)))
    end
end
`endif

`ifdef ASSERT
`VASSERT(a_illegal_format, uinstr_de1.valid, uinstr_de1.ifmt inside {RV_FMT_I,RV_FMT_R}, $sformatf("Unsupported instr fmt: %s", uinstr_de1.ifmt.name()))
`endif
    */

endmodule

`endif // __REGRD_SV

