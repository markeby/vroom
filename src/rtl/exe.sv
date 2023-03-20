`ifndef __EX_SV
`define __EX_SV

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

localparam EX0 = 0;
localparam EX1 = 1;
localparam NUM_EX_STAGES = 1;

`MKPIPE_INIT(logic,          valid_exx,  valid_ex0,  EX0, NUM_EX_STAGES)
`MKPIPE_INIT(t_uinstr,       uinstr_exx, uinstr_ex0, EX0, NUM_EX_STAGES)
`MKPIPE     (t_rv_reg_data,  result_exx,             EX0, NUM_EX_STAGES)

//
// Nets
//

t_uinstr      uinstr_ex1;

//
// Logic
//

always_comb begin
    result_exx[EX0] = '0;
    unique case (uinstr_ex0.opcode)
        OP_ALU_I: result_exx[EX0] = rddatas_ex0[0] + uinstr_ex0.imm32;
        OP_ALU_R: result_exx[EX0] = rddatas_ex0[0] + rddatas_ex0[1];
        default:  result_exx[EX0] = 32'hDEADBEEF;
    endcase
end

//
// EX1/MM0
//

// MM0 assign

always_comb uinstr_mm0 = uinstr_exx[EX1];
always_comb result_mm0 = result_exx[EX1];

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (uinstr_ex0.valid) begin
        `INFO(("unit:EX %s result:%08h", describe_uinstr(uinstr_ex0), result_exx[EX0]))
    end
end
`endif

/*
`ifdef ASSERT
`VASSERT(a_illegal_format, uinstr_de1.valid, uinstr_de1.ifmt inside {RV_FMT_I,RV_FMT_R}, $sformatf("Unsupported instr fmt: %s", uinstr_de1.ifmt.name()))
`endif
    */

endmodule

`endif // __EX_SV

