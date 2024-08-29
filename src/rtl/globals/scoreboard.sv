`ifndef __SCOREBOARD_SV
`define __SCOREBOARD_SV

`include "instr.pkg"
`include "vroom_macros.sv"

module scoreboard
    import instr::*, instr_decode::*;
(
    input  logic             clk,
    input  logic             reset,

    output logic             stall
);

localparam DE0 = 0;
localparam DE1 = 1;
localparam NUM_DE_STAGES = 1;

//
// Nets
//

//
// Logic
//

// FIXME: I think we should stall whe any RS is full, or the ROB is full...
// but previously this was scoreboarding register writes which we no longer
// need to do.
always_comb stall = 1'b0;

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

