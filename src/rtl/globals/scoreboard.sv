`ifndef __SCOREBOARD_SV
`define __SCOREBOARD_SV

`include "instr.pkg"
`include "vroom_macros.sv"

module scoreboard
    import instr::*, instr_decode::*;
(
    input  logic             clk,
    input  logic             reset,

    input  logic             valid_fe1,
    input  t_uinstr          uinstr_de0,
    input  t_uinstr          uinstr_de1,
    input  t_uinstr          uinstr_rd1,
    input  t_uinstr          uinstr_ex1,
    input  t_uinstr          uinstr_mm1,
    input  t_uinstr          uinstr_rb1,

    output logic             stall
);

localparam DE0 = 0;
localparam DE1 = 1;
localparam NUM_DE_STAGES = 1;

`MKPIPE(t_uinstr, uinstr_dex, DE0, NUM_DE_STAGES)

//
// Nets
//

t_rv_instr_format ifmt_de0;

logic[RV_NUM_REGS-1:0] regrd_mask_de0;
logic[RV_NUM_REGS-1:0] regwr_mask_de0;
logic[RV_NUM_REGS-1:0] regrd_mask_de1;
logic[RV_NUM_REGS-1:0] regwr_mask_de1;
logic[RV_NUM_REGS-1:0] regwr_mask_rd1;
logic[RV_NUM_REGS-1:0] regwr_mask_ex1;
logic[RV_NUM_REGS-1:0] regwr_mask_mm1;
logic[RV_NUM_REGS-1:0] regwr_mask_rb1;

//
// Logic
//

always_comb regrd_mask_de0 = uinstr_to_rdmask(uinstr_de0);
always_comb regwr_mask_de0 = uinstr_to_wrmask(uinstr_de0);

always_comb regrd_mask_de1 = uinstr_to_rdmask(uinstr_de1);
always_comb regwr_mask_de1 = uinstr_to_wrmask(uinstr_de1);

always_comb regwr_mask_rd1 = uinstr_to_wrmask(uinstr_rd1);
always_comb regwr_mask_ex1 = uinstr_to_wrmask(uinstr_ex1);
always_comb regwr_mask_mm1 = uinstr_to_wrmask(uinstr_mm1);
always_comb regwr_mask_rb1 = uinstr_to_wrmask(uinstr_rb1);

// stall asserts if there's anything valid in RD0 that collides with EX0, MM0, or RB0.
//
// When stall is asserted, a valid uop in FE, DE, or RD must stay in place!
always_comb stall = |( regrd_mask_de1
                     & ( regwr_mask_rd1 
                       | regwr_mask_ex1 
                       | regwr_mask_mm1 
                       | regwr_mask_rb1
                       ) 
                     );

//
// Debug
//

`ifdef SIMULATION
logic stall_dly;
`DFF(stall_dly, stall, clk)
always @(posedge clk) begin
    if (stall & ~stall_dly) begin
        `DEBUG(("Stalling..."))
    end else if (~stall & stall_dly) begin
        `DEBUG(("...Resuming"))
    end
end
`endif

`ifdef ASSERT
    //VASSERT(a_illegal_format, uinstr_dex[DE1].valid, uinstr_dex[DE1].ifmt inside {RV_FMT_I,RV_FMT_R}, $sformatf("Unsupported instr fmt: %s", uinstr_dex[DE1].ifmt.name()))
`endif

endmodule

`endif // __SCOREBOARD_SV

