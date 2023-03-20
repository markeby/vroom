`ifndef __RETIRE_SV
`define __RETIRE_SV

`include "instr.pkg"
`include "vroom_macros.sv"

module retire
    import instr::*;
(
    input  logic      clk,
    input  logic      reset
);

//
// Nets
//

//
// Logic
//

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

`endif // __RETIRE_SV

