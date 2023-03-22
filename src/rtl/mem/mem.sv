`ifndef __MEM_SV
`define __MEM_SV

`include "instr.pkg"
`include "vroom_macros.sv"

module mem
    import instr::*, instr_decode::*;
(
    input  logic         clk,
    input  logic         reset,

    input  t_uinstr      uinstr_ex1,
    input  t_rv_reg_data result_ex1,

    output t_uinstr      uinstr_mm1,
    output t_rv_reg_data result_mm1
);

localparam MM0 = 0;
localparam MM1 = 1;
localparam NUM_MM_STAGES = 1;

`MKPIPE_INIT(t_uinstr,       uinstr_mmx, uinstr_ex1, MM0, NUM_MM_STAGES)
`MKPIPE_INIT(t_rv_reg_data,  result_mmx, result_ex1, MM0, NUM_MM_STAGES)

//
// Nets
//

//
// Logic
//

//
// MM0
//

//
// MM1/RB0
//

// RB0 assign

always_comb uinstr_mm1 = uinstr_mmx[MM1];
always_comb result_mm1 = result_mmx[MM1];

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (uinstr_ex1.valid) begin
        `INFO(("unit:MM %s", describe_uinstr(uinstr_ex1)))
    end
end
`endif

    /*
`ifdef ASSERT
`VASSERT(a_illegal_format, uinstr_de1.valid, uinstr_de1.ifmt inside {RV_FMT_I,RV_FMT_R}, $sformatf("Unsupported instr fmt: %s", uinstr_de1.ifmt.name()))
`endif
    */

endmodule

`endif // __MEM_SV


