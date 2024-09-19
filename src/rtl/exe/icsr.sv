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

// always_comb begin
//     result_ex0 = '0;
//     resvld_ex0 = uinstr_ex0.valid;
//     unique case (uinstr_ex0.uop)
//         U_CSRRW: result_ex0 = src1val_ex0 + src2val_ex0;
//         U_CSRRS: result_ex0 = src1val_ex0 + src2val_ex0;
//         U_CSRRC: result_ex0 = src1val_ex0 + src2val_ex0;
//         default: begin
//             resvld_ex0 = 1'b0;
//             result_ex0 = '0;
//         end
//     endcase
// end

//
// CSRs
//

logic valid_ex0;
assign valid_ex0 = uinstr_ex0.valid;

t_gen_csr cntr_inst_ret;
assign cntr_inst_ret.data = 64'hDEAFBEEFB00BCAFE;

t_rv_reg_data csr_rd_data_ex0 [NUM_CSRS_DEFINED-1:0];

gen_csr_ro #(.T(t_gen_csr), .CSR_ADDR(CSRA_INSTRET)) csr_inst_ret (
    .clk,
    .reset,
    .csr_state    ( cntr_inst_ret      ) ,
    .valid_ex0,
    .uinstr_ex0,
    .wr_value_ex0 ( src1val_ex0        ) ,
    .rd_value_ex0 ( csr_rd_data_ex0[0] )
);

always_comb begin
    result_ex0 = '0;
    for (int i=0; i<NUM_CSRS_DEFINED; i++) begin
        result_ex0 |= csr_rd_data_ex0[i];
    end
end

assign resvld_ex0 = uinstr_ex0.uop inside {U_CSRRW, U_CSRRS, U_CSRRC};

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

`endif // __ICSR_SV


