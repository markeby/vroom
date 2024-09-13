`ifndef __IALU_SV
`define __IALU_SV

`include "instr.pkg"
`include "vroom_macros.sv"

module ialu
    import instr::*, instr_decode::*;
(
    input  logic         clk,
    input  logic         reset,

    input  t_uinstr      uinstr_ex0,
    input  t_rv_reg_data src1val_ex0,
    input  t_rv_reg_data src2val_ex0,

    output logic         resvld_ex0,
    output t_rv_reg_data result_ex0
);

//
// Nets
//

//
// Logic
//

//
// EX0
//

logic signed [XLEN-1:0] src1val_signed_ex0; always_comb src1val_signed_ex0 = src1val_ex0;
logic signed [XLEN-1:0] src2val_signed_ex0; always_comb src2val_signed_ex0 = src2val_ex0;

always_comb begin
    result_ex0 = '0;
    resvld_ex0 = uinstr_ex0.valid;
    unique case (uinstr_ex0.uop)
        U_ADD:     result_ex0 = src1val_ex0 + src2val_ex0;
        U_SUB:     result_ex0 = src1val_ex0 - src2val_ex0;
        U_AND:     result_ex0 = src1val_ex0 & src2val_ex0;
        U_XOR:     result_ex0 = src1val_ex0 ^ src2val_ex0;
        U_OR:      result_ex0 = src1val_ex0 | src2val_ex0;
        U_SLL:     result_ex0 = src1val_ex0 << src2val_ex0[4:0];
        U_SRL:     result_ex0 = src1val_ex0 >> src2val_ex0[4:0];
        U_SRA:     result_ex0 = src1val_signed_ex0 >>> src2val_ex0[4:0];
        U_SLT:     result_ex0 = src1val_signed_ex0 < src2val_signed_ex0 ? t_rv_reg_data'(1) : t_rv_reg_data'(0);
        U_SLTU:    result_ex0 = src1val_ex0 < src2val_ex0 ? t_rv_reg_data'(1) : t_rv_reg_data'(0);
        U_LUI:     result_ex0 = src2val_ex0;
        U_AUIPC:   result_ex0 = src2val_ex0 + uinstr_ex0.pc;
        default: begin
            resvld_ex0 = 1'b0;
            result_ex0 = '0;
        end
    endcase
end

//
// EX1
//

//
// Debug
//

`ifdef SIMULATION
// always @(posedge clk) begin
//     if (resvld_ex0) begin
//         `INFO(("unit:EX.IALU %s result:%08h", describe_uinstr(uinstr_ex0), result_ex0))
//     end
// end
`endif

/*
`ifdef ASSERT
`VASSERT(a_illegal_format, uinstr_de1.valid, uinstr_de1.ifmt inside {RV_FMT_I,RV_FMT_R}, $sformatf("Unsupported instr fmt: %s", uinstr_de1.ifmt.name()))
`endif
    */

endmodule

`endif // __IALU_SV


