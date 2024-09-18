`ifndef __DECODE_SV
`define __DECODE_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "vroom_macros.sv"
`include "gen_funcs.pkg"
`include "common.pkg"
`include "verif.pkg"

module decode
    import instr::*, instr_decode::*, gen_funcs::*, common::*, verif::*;
(
    input  logic             clk,
    input  logic             reset,
    input  t_nuke_pkt        nuke_rb1,
    output logic             decode_ready_de0,
    input  logic             rename_ready_rn0,

    input  logic             valid_fe1,
    input  t_instr_pkt       instr_fe1,

    output t_uinstr          uinstr_de0,

    output logic             valid_de1,
    output t_uinstr          uinstr_de1
);

localparam DE0 = 0;
localparam DE1 = 1;
localparam NUM_DE_STAGES = 1;

`MKPIPE(logic,    valid_dex,  DE0, NUM_DE_STAGES)

//
// Nets
//

t_rv_instr        rv_instr_fe1;
t_rv_instr_format ifmt_de0;

`ifdef SIMULATION
int instr_cnt_inst;
`DFF(instr_cnt_inst, reset ? '0 : instr_cnt_inst + int'(valid_dex[DE0]), clk)
`endif

//
// Logic
//

always_comb rv_instr_fe1 = instr_fe1.instr;

//
// DE0
//

always_comb valid_dex[DE0] = valid_fe1 & ~reset;
always_comb ifmt_de0       = get_instr_format(rv_instr_fe1.opcode);

always_comb begin
    t_size tmp_osize;
    tmp_osize = SZ_INV;

    uinstr_de0 = '0;
    uinstr_de0.opcode = rv_instr_fe1.opcode;
    uinstr_de0.valid  = valid_dex[DE0];
    uinstr_de0.ifmt   = ifmt_de0;
    uinstr_de0.pc     = instr_fe1.pc;

    unique case (ifmt_de0)
        RV_FMT_R: begin
            uinstr_de0.funct7 = rv_instr_fe1.d.R.funct7;
            uinstr_de0.funct3 = rv_instr_fe1.d.R.funct3;
            if (~rv_instr_fe1.opcode[3]) begin
                // 64b version
                uinstr_de0.dst    = '{opreg: rv_instr_fe1.d.R.rd,  optype: OP_REG, opsize: SZ_8B};
                uinstr_de0.src1   = '{opreg: rv_instr_fe1.d.R.rs1, optype: OP_REG, opsize: SZ_8B};
                uinstr_de0.src2   = '{opreg: rv_instr_fe1.d.R.rs2, optype: OP_REG, opsize: SZ_8B};
            end else begin
                // 32b (W-suffix) version
                uinstr_de0.dst    = '{opreg: rv_instr_fe1.d.R.rd,  optype: OP_REG, opsize: SZ_4B};
                uinstr_de0.src1   = '{opreg: rv_instr_fe1.d.R.rs1, optype: OP_REG, opsize: SZ_4B};
                uinstr_de0.src2   = '{opreg: rv_instr_fe1.d.R.rs2, optype: OP_REG, opsize: SZ_4B};
            end
            uinstr_de0.imm64  = '0;
            uinstr_de0.uop    = rv_instr_to_uop(rv_instr_fe1);
        end
        RV_FMT_I: begin
            uinstr_de0.funct7 = '0;
            uinstr_de0.funct3 = rv_instr_fe1.d.I.funct3;
            if (rv_opcode_is_alu(rv_instr_fe1.opcode)) begin
                if (~rv_instr_fe1.opcode[3]) begin
                    // 64b version
                    uinstr_de0.dst    = '{opreg: rv_instr_fe1.d.I.rd,  optype: OP_REG, opsize: SZ_8B};
                    uinstr_de0.src1   = '{opreg: rv_instr_fe1.d.I.rs1, optype: OP_REG, opsize: SZ_8B};
                    uinstr_de0.src2   = '{opreg: '0,                   optype: OP_IMM, opsize: SZ_8B};
                end else begin
                    // 32b (W-suffix) version
                    uinstr_de0.dst    = '{opreg: rv_instr_fe1.d.I.rd,  optype: OP_REG, opsize: SZ_4B};
                    uinstr_de0.src1   = '{opreg: rv_instr_fe1.d.I.rs1, optype: OP_REG, opsize: SZ_4B};
                    uinstr_de0.src2   = '{opreg: '0,                   optype: OP_IMM, opsize: SZ_4B};
                end
            end else if (rv_opcode_is_ld(rv_instr_fe1.opcode)) begin
                uinstr_de0.dst    = '{opreg: rv_instr_fe1.d.I.rd,  optype: OP_REG, opsize: SZ_4B};
                uinstr_de0.src1   = '{opreg: rv_instr_fe1.d.I.rs1, optype: OP_REG, opsize: SZ_4B};
                uinstr_de0.src2   = '{opreg: '0,                   optype: OP_IMM, opsize: SZ_4B};
            end else if (rv_instr_fe1.opcode == RV_OP_JALR) begin
                uinstr_de0.dst    = '{opreg: rv_instr_fe1.d.I.rd,  optype: OP_REG, opsize: SZ_8B};
                uinstr_de0.src1   = '{opreg: rv_instr_fe1.d.I.rs1, optype: OP_REG, opsize: SZ_8B};
                uinstr_de0.src2   = '{opreg: '0,                   optype: OP_IMM, opsize: SZ_8B};
            end
            uinstr_de0.imm64  = sext_funcs#(.IWIDTH(12), .OWIDTH(64))::sext(rv_instr_fe1.d.I.imm_11_0);
            uinstr_de0.uop    = rv_instr_to_uop(rv_instr_fe1);
        end
        RV_FMT_S: begin
            uinstr_de0.funct7 = '0;
            uinstr_de0.funct3 = rv_instr_fe1.d.S.funct3;

            if (rv_opcode_is_st(rv_instr_fe1.opcode)) begin
                unique casez (t_rv_st_op_funct3'(rv_instr_fe1.d.S.funct3))
                    MEM_SB:  tmp_osize = SZ_1B;
                    MEM_SH:  tmp_osize = SZ_2B;
                    MEM_SW:  tmp_osize = SZ_4B;
                    MEM_SD:  tmp_osize = SZ_8B;
                    default: tmp_osize = SZ_INV;
                endcase
                uinstr_de0.dst    = '{opreg: '0,                   optype: OP_MEM, opsize: tmp_osize};
                uinstr_de0.src1   = '{opreg: rv_instr_fe1.d.S.rs1, optype: OP_REG, opsize: SZ_8B};
                uinstr_de0.src2   = '{opreg: rv_instr_fe1.d.S.rs2, optype: OP_REG, opsize: tmp_osize};
            end
            uinstr_de0.imm64  = sext_funcs#(.IWIDTH(12), .OWIDTH(64))::sext({rv_instr_fe1.d.S.imm_11_5, rv_instr_fe1.d.S.imm_4_0});
            uinstr_de0.uop    = rv_instr_to_uop(rv_instr_fe1);
        end
        RV_FMT_J: begin
            uinstr_de0.funct7 = '0;
            uinstr_de0.funct3 = '0;
            uinstr_de0.dst    = '{opreg: rv_instr_fe1.d.J.rd,  optype: OP_REG, opsize: SZ_4B};
            uinstr_de0.src1   = '{opreg: '0,                   optype: OP_INVD, opsize: SZ_4B};
            uinstr_de0.src2   = '{opreg: '0,                   optype: OP_IMM, opsize: SZ_4B};
            uinstr_de0.imm64  = sext_funcs#(.IWIDTH(21), .OWIDTH(64))::sext({rv_instr_fe1.d.J.imm_20,
                                                                             rv_instr_fe1.d.J.imm_19_12,
                                                                             rv_instr_fe1.d.J.imm_11,
                                                                             rv_instr_fe1.d.J.imm_10_1,
                                                                             1'b0});
            uinstr_de0.uop    = rv_instr_to_uop(rv_instr_fe1);
        end
        RV_FMT_B: begin
            uinstr_de0.funct7 = '0;
            uinstr_de0.funct3 = rv_instr_fe1.d.B.funct3;
            uinstr_de0.dst    = '{opreg: '0, optype: OP_INVD, opsize: SZ_4B};
            uinstr_de0.src1   = '{opreg: rv_instr_fe1.d.B.rs1, optype: OP_REG, opsize: SZ_4B};
            uinstr_de0.src2   = '{opreg: rv_instr_fe1.d.B.rs2, optype: OP_REG, opsize: SZ_4B};
            uinstr_de0.imm64  = sext_funcs#(.IWIDTH(13), .OWIDTH(64))::sext({rv_instr_fe1.d.B.imm_12,
                                                                             rv_instr_fe1.d.B.imm_11,
                                                                             rv_instr_fe1.d.B.imm_10_5,
                                                                             rv_instr_fe1.d.B.imm_4_1,
                                                                             1'b0});
            uinstr_de0.uop    = rv_instr_to_uop(rv_instr_fe1);
        end
        RV_FMT_U: begin
            uinstr_de0.funct7 = '0;
            uinstr_de0.funct3 = '0;
            uinstr_de0.dst    = '{opreg: rv_instr_fe1.d.U.rd,  optype: OP_REG, opsize: SZ_8B};
            uinstr_de0.src1   = '{opreg: '0, optype: OP_INVD, opsize: SZ_4B};
            uinstr_de0.src2   = '{opreg: '0, optype: OP_IMM,  opsize: SZ_8B};
            uinstr_de0.imm64  = sext_funcs#(.IWIDTH(32), .OWIDTH(64))::sext({rv_instr_fe1.d.U.imm_31_12, 12'd0});
            uinstr_de0.uop    = rv_instr_to_uop(rv_instr_fe1);
        end
        default: begin
        end
    endcase

    if (uinstr_de0.src1.optype == OP_REG & uinstr_de0.src1.opreg == '0) uinstr_de0.src1.optype = OP_ZERO;
    if (uinstr_de0.src2.optype == OP_REG & uinstr_de0.src2.opreg == '0) uinstr_de0.src2.optype = OP_ZERO;
    if (uinstr_de0.dst .optype == OP_REG & uinstr_de0.dst .opreg == '0) uinstr_de0.dst .optype = OP_INVD;

    `ifdef SIMULATION
    uinstr_de0.SIMID     = instr_fe1.SIMID;
    `endif

    if (reset) uinstr_de0 = '0;
end

//
// DE1/RD0
//

logic uopq_full;
logic uopq_pop_de1;
logic uopq_push_de0;
t_uinstr uinstr_nq_de1;

logic ebreak_seen;
`DFF(ebreak_seen, ~reset & ~nuke_rb1.valid & (ebreak_seen | uopq_push_de0 & uinstr_de0.uop == U_EBREAK), clk)

assign uopq_push_de0 = uinstr_de0.valid & ~ebreak_seen & ~nuke_rb1.valid & decode_ready_de0;

logic uopq_valid_de1;
gen_fifo #(
    .NPUSH(1), .NPOP(1), .DEPTH(2), .T(t_uinstr), .NAME("UOP_QUEUE")
) uop_queue (
    .clk,
    .reset          ( reset | nuke_rb1.valid ) ,
    .full           ( uopq_full         ) ,
    .empty          (                   ) ,
    .push_front_xw0 ( '{uopq_push_de0}  ) ,
    .num_push_ok    (                   ) ,
    .din_xw0        ( '{uinstr_de0}     ) ,
    .pop_back_xr0   ( '{uopq_pop_de1}   ) ,
    .valid_xr0      ( '{uopq_valid_de1} ) ,
    .dout_xr0       ( '{uinstr_nq_de1}  )
);

assign uopq_pop_de1 = uopq_valid_de1 & rename_ready_rn0;
assign valid_de1 = uopq_pop_de1;

always_comb begin
    uinstr_de1 = uinstr_nq_de1;
    uinstr_de1.valid = valid_de1;
end

assign decode_ready_de0 = ~uopq_full;

`ifdef ASSERT
logic during_nuke_inst;
`DFF(during_nuke_inst, ~reset & ~core.resume_fetch_rbx & (during_nuke_inst | nuke_rb1.valid), clk)
    `VASSERT(a_push_during_nuke, uopq_push_de0, ~during_nuke_inst, "decode uopq pushed during branch correction window")
`endif

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (uinstr_de0.valid) begin
        `UINFO(uinstr_de0.SIMID, ("unit:DE func:uopq_push %s", describe_uinstr(uinstr_de0)))
    end
    if (uopq_valid_de1  & ~valid_de1) begin
        `UINFO(uinstr_nq_de1.SIMID, ("unit:DE func:uopq_stalled %s", describe_uinstr(uinstr_de1)))
    end
    if (valid_de1) begin
        `UINFO(uinstr_de1.SIMID, ("unit:DE func:uopq_pop %s", describe_uinstr(uinstr_de1)))
    end
end
`endif

`ifdef ASSERT
//chk_no_change #(.T(t_uinstr)) cnc ( .clk, .reset, .hold(stall & uinstr_de1.valid & ~br_mispred_rb1), .thing(uinstr_de1) );
`endif

endmodule

`endif // __DECODE_SV

