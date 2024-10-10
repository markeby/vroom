`ifndef __IALU_SV
`define __IALU_SV

`include "instr.pkg"
`include "vroom_macros.sv"

module ialu
    import instr::*, instr_decode::*, gen_funcs::*;
(
    input  logic         clk,
    input  logic         reset,

    input  logic         iss_ex0,
    input  t_uinstr      uinstr_ex0,
    input  t_rv_reg_data src1val_ex0,
    input  t_rv_reg_data src2val_ex0,

    output logic         resvld_ex0,
    output t_rv_reg_data result_ex0
);

//
// Nets
//

t_rv_reg_data result_nq_ex0;

//
// Logic
//

//
// EX0
//

logic signed [XLEN-1:0] src1val_signed_ex0; always_comb src1val_signed_ex0 = src1val_ex0;
logic signed [XLEN-1:0] src2val_signed_ex0; always_comb src2val_signed_ex0 = src2val_ex0;

always_comb begin
    result_nq_ex0 = '0;
    resvld_ex0 = iss_ex0;
    unique case (uinstr_ex0.uop)
        U_ADD:     result_nq_ex0 = src1val_ex0 + src2val_ex0;
        U_ADDW:    result_nq_ex0 = src1val_ex0 + src2val_ex0;
        U_SUB:     result_nq_ex0 = src1val_ex0 - src2val_ex0;
        U_AND:     result_nq_ex0 = src1val_ex0 & src2val_ex0;
        U_XOR:     result_nq_ex0 = src1val_ex0 ^ src2val_ex0;
        U_OR:      result_nq_ex0 = src1val_ex0 | src2val_ex0;
        U_SLL:     result_nq_ex0 = src1val_ex0 << src2val_ex0[4:0];
        U_SRL:     result_nq_ex0 = src1val_ex0 >> src2val_ex0[4:0];
        U_SRA:     result_nq_ex0 = src1val_signed_ex0 >>> src2val_ex0[4:0];
        U_SLT:     result_nq_ex0 = src1val_signed_ex0 < src2val_signed_ex0 ? t_rv_reg_data'(1) : t_rv_reg_data'(0);
        U_SLTU:    result_nq_ex0 = src1val_ex0 < src2val_ex0 ? t_rv_reg_data'(1) : t_rv_reg_data'(0);
        U_LUI:     result_nq_ex0 = src2val_ex0;
        U_AUIPC:   result_nq_ex0 = src2val_ex0 + uinstr_ex0.pc;
        default: begin
            resvld_ex0 = 1'b0;
            result_nq_ex0 = '0;
        end
    endcase
end

always_comb begin
    unique casez (uinstr_ex0.dst.opsize)
        SZ_1B:   result_ex0 = sext_funcs#(.IWIDTH( 8), .OWIDTH(XLEN))::sext(result_nq_ex0[ 7:0]);
        SZ_2B:   result_ex0 = sext_funcs#(.IWIDTH(16), .OWIDTH(XLEN))::sext(result_nq_ex0[15:0]);
        SZ_4B:   result_ex0 = sext_funcs#(.IWIDTH(32), .OWIDTH(XLEN))::sext(result_nq_ex0[31:0]);
        SZ_8B:   result_ex0 = sext_funcs#(.IWIDTH(64), .OWIDTH(XLEN))::sext(result_nq_ex0[63:0]);
        default: result_ex0 = result_nq_ex0;
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


