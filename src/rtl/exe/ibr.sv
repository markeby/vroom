`ifndef __IBR_SV
`define __IBR_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "common.pkg"
`include "vroom_macros.sv"
`include "verif.pkg"

module ibr
    import instr::*, instr_decode::*, common::*, verif::*;
(
    input  logic         clk,
    input  logic         reset,

    input  t_iss_pkt  iss_pkt_ex0,
    input  t_rv_reg_data src1val_ex0,
    input  t_rv_reg_data src2val_ex0,

    output logic         resvld_ex0,
    output t_br_mispred_pkt br_mispred_ex0
);

//
// Nets
//

t_uinstr uinstr_ex0;

t_paddr tkn_tgt_ex0;
t_paddr tru_tgt_ex0;
t_paddr pcnxt_ex0;
logic   tkn_ex0;

//
// Logic
//

//
// EX0
//

assign uinstr_ex0 = iss_pkt_ex0.uinstr;

always_comb begin
    resvld_ex0 = uinstr_ex0.valid;
    unique case (uinstr_ex0.uop)
        U_BR:    resvld_ex0 = 1'b1;
        default: resvld_ex0 = 1'b0;
    endcase
end

always_comb pcnxt_ex0   = uinstr_ex0.pc + 4;
always_comb tkn_tgt_ex0 = uinstr_ex0.pc + uinstr_ex0.imm64;

always_comb begin
    tkn_ex0 = 1'b0;
    unique casez(uinstr_ex0.funct3.br)
        RV_BR_BEQ : tkn_ex0 = src1val_ex0 == src2val_ex0;
        RV_BR_BNE : tkn_ex0 = src1val_ex0 != src2val_ex0;
        RV_BR_BLT : tkn_ex0 = int'(src1val_ex0) <  int'(src2val_ex0);
        RV_BR_BGE : tkn_ex0 = int'(src1val_ex0) >= int'(src2val_ex0);
        RV_BR_BLTU: tkn_ex0 = src1val_ex0 <  src2val_ex0;
        RV_BR_BGEU: tkn_ex0 = src1val_ex0 >= src2val_ex0;
    endcase
end

assign tru_tgt_ex0                = tkn_ex0 ? tkn_tgt_ex0 : pcnxt_ex0;
assign br_mispred_ex0.valid       = tru_tgt_ex0 != pcnxt_ex0 & resvld_ex0;
assign br_mispred_ex0.target_addr = tru_tgt_ex0;
assign br_mispred_ex0.robid       = iss_pkt_ex0.robid;

///
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (resvld_ex0) begin
        `UINFO(uinstr_ex0.SIMID, ("unit:EX.IBR %s mispred:%-d tkn:%-d tru_tgt:%h pcnxt:%h ", describe_uinstr(uinstr_ex0), br_mispred_ex0.valid, tkn_ex0, tru_tgt_ex0, pcnxt_ex0))
    end
end
`endif

/*
`ifdef ASSERT
`VASSERT(a_illegal_format, uinstr_de1.valid, uinstr_de1.ifmt inside {RV_FMT_I,RV_FMT_R}, $sformatf("Unsupported instr fmt: %s", uinstr_de1.ifmt.name()))
`endif
    */

endmodule

`endif // __IBR_SV


