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

    input  logic         iss_ex0,
    input  t_iss_pkt     iss_pkt_ex0,
    input  t_rv_reg_data src1val_ex0,
    input  t_rv_reg_data src2val_ex0,

    output logic         resvld_ex0,
    output t_rv_reg_data result_ex0,
    output t_br_mispred_pkt br_mispred_ex0
);

//
// Nets
//

t_uinstr uinstr_ex0;

t_paddr tkn_tgt_ex0;
t_paddr tru_tgt_ex0;

t_paddr    pcnxt_ex0;
t_rom_addr usnxt_ex0;
t_paddr    pc_or_us_nxt_ex0;

logic   tkn_ex0;
logic   ucbr_ex0;

//
// Logic
//

//
// EX0
//

assign uinstr_ex0 = iss_pkt_ex0.uinstr;
assign ucbr_ex0 = uinstr_ex0.from_ucrom & ~uinstr_ex0.eom;

always_comb begin
    resvld_ex0 = iss_ex0;
    unique case (uinstr_ex0.uop)
        U_BR_EQ:  resvld_ex0 &= 1'b1;
        U_BR_NE:  resvld_ex0 &= 1'b1;
        U_BR_LT:  resvld_ex0 &= 1'b1;
        U_BR_GE:  resvld_ex0 &= 1'b1;
        U_BR_LTU: resvld_ex0 &= 1'b1;
        U_BR_GEU: resvld_ex0 &= 1'b1;
        U_JAL:    resvld_ex0 &= 1'b1;
        U_JALR:   resvld_ex0 &= 1'b1;
        default:  resvld_ex0 &= 1'b0;
    endcase
end

assign pcnxt_ex0   = uinstr_ex0.pc + 4;
assign usnxt_ex0   = uinstr_ex0.rom_addr + 1;
assign pc_or_us_nxt_ex0 = ucbr_ex0 ? t_paddr'(usnxt_ex0) : pcnxt_ex0;
assign result_ex0  = pc_or_us_nxt_ex0;

always_comb begin
    unique casez (uinstr_ex0.uop)
        U_JALR:  tkn_tgt_ex0 = (src1val_ex0 + uinstr_ex0.imm64) & ~64'h1;
        default: tkn_tgt_ex0 = uinstr_ex0.pc + uinstr_ex0.imm64;
    endcase
end

always_comb begin
    tkn_ex0 = 1'b0;
    unique casez(uinstr_ex0.uop)
        U_BR_EQ:  tkn_ex0 = src1val_ex0 == src2val_ex0;
        U_BR_NE:  tkn_ex0 = src1val_ex0 != src2val_ex0;
        U_BR_LT:  tkn_ex0 = int'(src1val_ex0) <  int'(src2val_ex0);
        U_BR_GE:  tkn_ex0 = int'(src1val_ex0) >= int'(src2val_ex0);
        U_BR_LTU: tkn_ex0 = src1val_ex0 <  src2val_ex0;
        U_BR_GEU: tkn_ex0 = src1val_ex0 >= src2val_ex0;
        U_JAL:    tkn_ex0 = 1'b1;
        U_JALR:   tkn_ex0 = 1'b1;
        default:  tkn_ex0 = 1'b0;
    endcase
end

assign tru_tgt_ex0                = tkn_ex0 ? tkn_tgt_ex0 : pc_or_us_nxt_ex0;
assign br_mispred_ex0.valid       = tru_tgt_ex0 != pc_or_us_nxt_ex0 & resvld_ex0;
assign br_mispred_ex0.target_addr = tru_tgt_ex0;
assign br_mispred_ex0.robid       = iss_pkt_ex0.robid;
assign br_mispred_ex0.ucbr        = ucbr_ex0;

///
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (resvld_ex0) begin
        if (ucbr_ex0) begin
            `UINFO(uinstr_ex0.SIMID, ("unit:EX.IBR func:ubranch mispred:%-d tkn:%-d tru_tgt:%h usnxt:%h ", br_mispred_ex0.valid, tkn_ex0, tru_tgt_ex0, usnxt_ex0))
        end else begin
            `UINFO(uinstr_ex0.SIMID, ("unit:EX.IBR func:branch mispred:%-d tkn:%-d tru_tgt:%h pcnxt:%h ", br_mispred_ex0.valid, tkn_ex0, tru_tgt_ex0, pcnxt_ex0))
        end
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


