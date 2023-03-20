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
    input  t_rv_reg_data rddatas_ex0 [1:0],
    output t_uinstr      uinstr_mm0,
    output t_rv_reg_data result_mm0
);

//
// Nets
//

t_rv_reg_data result_ex0;
t_rv_reg_data result_ex1;
t_uinstr      uinstr_ex1;

//
// Logic
//

always_comb begin
    result_ex0 = '0;
    unique case (uinstr_ex0.opcode)
        OP_ALU_I: result_ex0 = rddatas_ex0[0] + uinstr_ex0.imm32;
        OP_ALU_R: result_ex0 = rddatas_ex0[0] + rddatas_ex0[1];
        default:  result_ex0 = 32'hDEADBEEF;
    endcase
end

//
// EX1/MM0
//

`DFF(result_ex1, result_ex0, clk)
`DFF(uinstr_ex1, uinstr_ex0, clk)

// MM0 assign

always_comb uinstr_mm0 = uinstr_ex1;
always_comb result_mm0 = result_ex1;

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (uinstr_ex0.valid) begin
        `INFO(("unit:EX %s result:%08h", describe_uinstr(uinstr_ex0), result_ex0))
    end
end
`endif

/*
`ifdef ASSERT
`VASSERT(a_illegal_format, uinstr_de1.valid, uinstr_de1.ifmt inside {RV_FMT_I,RV_FMT_R}, $sformatf("Unsupported instr fmt: %s", uinstr_de1.ifmt.name()))
`endif
    */

endmodule

`endif // __EXE_SV

