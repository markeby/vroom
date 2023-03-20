`ifndef __EXE_SV
`define __EXE_SV

`include "instr.pkg"
`include "vroom_macros.sv"

module exe
    import instr::*;
(
    input  logic         clk,
    input  logic         reset,
    input  logic         valid_ex0,
    input  t_uinstr      uinstr_ex0,
    input  t_rv_reg_data rddatas_ex0 [1:0]
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

`endif // __EXE_SV

