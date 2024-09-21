`ifndef __GEN_CSR_RO_SV
`define __GEN_CSR_RO_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "csr.pkg"
`include "gen_funcs.pkg"
`include "instr.pkg"
`include "instr_decode.pkg"

module gen_csr_ro
    import csr::*, gen_funcs::*, instr::*, instr_decode::*, common::*;
#(parameter type T=t_gen_csr, t_csr_addr CSR_ADDR)
(
    input  logic         clk,
    input  logic         reset,

    input  T             csr_state,

    input  logic         valid_ex0,
    input  t_uinstr      uinstr_ex0,
    input  t_rv_reg_data wr_value_ex0,
    output t_rv_reg_data rd_value_ex0
);

t_rv_reg_data wr_value_ql_ex0;
logic         valid_ql_ex0;
t_csr_addr    csr_addr_ex0;

assign csr_addr_ex0 = t_csr_addr'(uinstr_ex0.imm64[11:0]);
assign valid_ql_ex0 = valid_ex0 & csr_addr_ex0 == CSR_ADDR;

always_comb begin
    unique casez (uinstr_ex0.src1.optype)
        OP_IMM:  wr_value_ql_ex0 = sext_funcs#(.IWIDTH($bits(t_gpr_id)), .OWIDTH(XLEN))::zext(uinstr_ex0.src1.opreg);
        default: wr_value_ql_ex0 = wr_value_ex0;
    endcase
end

always_comb begin
    unique casez (uinstr_ex0.uop)
        U_CSRRW: rd_value_ex0 = t_rv_reg_data'(sext_funcs#(.IWIDTH($bits(T)), .OWIDTH(XLEN))::zext(csr_state));
        U_CSRRS: rd_value_ex0 = t_rv_reg_data'(sext_funcs#(.IWIDTH($bits(T)), .OWIDTH(XLEN))::zext(csr_state));
        U_CSRRC: rd_value_ex0 = t_rv_reg_data'(sext_funcs#(.IWIDTH($bits(T)), .OWIDTH(XLEN))::zext(csr_state));
        default: rd_value_ex0 = t_rv_reg_data'('0);
    endcase
    if (~valid_ql_ex0) begin
        rd_value_ex0 = t_rv_reg_data'('0);
    end
end

endmodule

`endif // __GEN_CSR_RO_SV


