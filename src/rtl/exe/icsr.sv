`ifndef __ICSR_SV
`define __ICSR_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "csr.pkg"

module icsr
    import instr::*, instr_decode::*, csr::*;
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

always_comb begin
    result_ex0 = '0;
    resvld_ex0 = uinstr_ex0.valid;
    unique case (uinstr_ex0.uop)
        U_CSRRW: result_ex0 = src1val_ex0 + src2val_ex0;
        U_CSRRS: result_ex0 = src1val_ex0 + src2val_ex0;
        U_CSRRC: result_ex0 = src1val_ex0 + src2val_ex0;
        default: begin
            resvld_ex0 = 1'b0;
            result_ex0 = '0;
        end
    endcase
end

//
// CSRs
//

logic valid_ex0;
assign valid_ex0 = uinstr_ex0.valid;

t_gen_csr cntr_inst_ret;
assign cntr_inst_ret.data = 64'hDEAFBEEFB00BCAFE;

gen_csr_ro #(.T(t_gen_csr), .CSR_ADDR(CSRA_INSTRET)) csr_inst_ret (
    .clk,
    .reset,
    .csr_state    ( cntr_inst_ret      ) ,
    .valid_ex0,
    .uinstr_ex0,
    .wr_value_ex0 ( src1val_ex0        ) ,
    .rd_value_ex0 ( csr_rd_data_ex0[0] )
);

//
// Debug
//

`ifdef SIMULATION
// always @(posedge clk) begin
//     if (resvld_ex0) begin
//         `INFO(("unit:EX.ICSR %s result:%08h", describe_uinstr(uinstr_ex0), result_ex0))
//     end
// end
`endif

/*
`ifdef ASSERT
`VASSERT(a_illegal_format, uinstr_de1.valid, uinstr_de1.ifmt inside {RV_FMT_I,RV_FMT_R}, $sformatf("Unsupported instr fmt: %s", uinstr_de1.ifmt.name()))
`endif
    */

endmodule

typedef struct packed {
    logic[XLEN-1:0] data;
} t_gen_csr;

module gen_csr_ro
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

assign csr_addr_ex0 = t_csr_addr'(uinstr_ex0.imm_11_0);
assign valid_ql_ex0 = valid_ex0 & csr_addr_ex0 == CSR_ADDR;

always_comb begin
    unique casez (uinstr_ex0.src1.optype)
        OP_IMM:  wr_value_ql_ex0 = sext_funcs#(.IWIDTH($bits(t_rv_reg_addr)), .OWIDTH(XLEN))::zext(uinstr_ex0.src1.opreg);
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

`endif // __ICSR_SV


