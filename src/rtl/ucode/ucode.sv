`ifndef __UCODE_SV
`define __UCODE_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "asm.pkg"
`include "uasm.pkg"
`include "vroom_macros.sv"
`include "gen_funcs.pkg"
`include "common.pkg"
`include "verif.pkg"

module ucode
    import instr::*, instr_decode::*, asm::*, uasm::*, gen_funcs::*, common::*, verif::*;
(
    input  logic             clk,
    input  logic             reset,
    input  t_nuke_pkt        nuke_rb1,
    input  logic             rename_ready_rn0,
    input  t_rob_id          oldest_robid,

    input  logic             resume_fetch_rbx,
    input  t_br_mispred_pkt  br_mispred_ex0,

    input  logic             valid_de1,
    input  t_uinstr          uinstr_de1,
    output logic             ucode_ready_uc0,

    output logic             valid_uc0,
    output t_uinstr          uinstr_uc0
);

//
// Types
//

typedef enum logic[1:0] {
    UC_IDLE,
    UC_FETCH,
    UC_PDG_RSM
} t_uc_fsm;
t_uc_fsm fsm, fsm_nxt;

//
// Nets
//

t_rom_addr useq_pc;
t_rom_addr useq_pc_nxt;
logic      trap_now_de1;
logic      ucrom_active_uc0;

logic    br_mispred_pdg;
logic    br_mispred_resume_to_ucrom;
t_rob_id br_mispred_robid;

logic    nuke_rb1_valid_ql;
logic    br_mispred_ql_ex0;

t_uinstr ROM [UCODE_ROM_ROWS-1:0];

//
// FSM
//

assign trap_now_de1 = fsm == UC_IDLE & valid_de1 & rename_ready_rn0 & uinstr_de1.trap_to_ucode;

always_comb begin
    fsm_nxt = fsm;
    if (reset) begin
        fsm_nxt = UC_IDLE;
    end else begin
        unique casez(fsm)
            UC_IDLE:     if (trap_now_de1                                           ) fsm_nxt = UC_FETCH;
                    else if (br_mispred_ql_ex0                                      ) fsm_nxt = UC_PDG_RSM;
            UC_FETCH:    if (br_mispred_ql_ex0                                      ) fsm_nxt = UC_PDG_RSM;
                    else if (valid_uc0 & rename_ready_rn0 & uinstr_uc0.eom          ) fsm_nxt = UC_IDLE;
            UC_PDG_RSM:  if (resume_fetch_rbx &  br_mispred_resume_to_ucrom         ) fsm_nxt = UC_FETCH;
                    else if (resume_fetch_rbx & ~br_mispred_resume_to_ucrom         ) fsm_nxt = UC_IDLE;
        endcase
    end
end
`DFF(fsm, fsm_nxt, clk)

assign ucrom_active_uc0 = fsm != UC_IDLE;

//
// Logic
//

// useq

always_comb begin
    useq_pc_nxt = useq_pc;
    if (br_mispred_ql_ex0) begin
        useq_pc_nxt = t_rom_addr'(br_mispred_ex0.restore_useq);
    end else if (fsm == UC_IDLE) begin
        useq_pc_nxt = uinstr_de1.rom_addr;
    end else begin
        useq_pc_nxt += (valid_uc0 & rename_ready_rn0) ? t_rom_addr'(1) : '0;
    end
end

`DFF(useq_pc, useq_pc_nxt, clk)

assign ucode_ready_uc0 = fsm == UC_IDLE & rename_ready_rn0;

assign valid_uc0  = fsm == UC_IDLE & valid_de1
                  | fsm == UC_FETCH;

t_uinstr trapped_uinstr;
`DFF_EN(trapped_uinstr, uinstr_de1, clk, trap_now_de1)

`ifdef SIMULATION
`SIMID_SPAWN_CNTR(SIMID_UROM, (fsm == UC_FETCH & rename_ready_rn0), clk, trapped_uinstr.SIMID, UCROM)
`endif

t_uinstr uc_uinstr_uc0;
always_comb begin
    uc_uinstr_uc0 = ROM[useq_pc];
    uc_uinstr_uc0.pc = trapped_uinstr.pc;

    // Source1
    if (uc_uinstr_uc0.src1.optype == OP_TRAP_SRC1) uc_uinstr_uc0.src1 = trapped_uinstr.src1;
    if (uc_uinstr_uc0.src1.optype == OP_TRAP_SRC2) uc_uinstr_uc0.src1 = trapped_uinstr.src2;
    if (uc_uinstr_uc0.src1.optype == OP_TRAP_DST ) uc_uinstr_uc0.src1 = trapped_uinstr.dst;

    // Source2
    if (uc_uinstr_uc0.src2.optype == OP_TRAP_SRC1) uc_uinstr_uc0.src2 = trapped_uinstr.src1;
    if (uc_uinstr_uc0.src2.optype == OP_TRAP_SRC2) uc_uinstr_uc0.src2 = trapped_uinstr.src2;
    if (uc_uinstr_uc0.src2.optype == OP_TRAP_DST ) uc_uinstr_uc0.src2 = trapped_uinstr.dst;

    // Dest
    if (uc_uinstr_uc0.dst .optype == OP_TRAP_SRC1) uc_uinstr_uc0.dst  = trapped_uinstr.src1;
    if (uc_uinstr_uc0.dst .optype == OP_TRAP_SRC2) uc_uinstr_uc0.dst  = trapped_uinstr.src2;
    if (uc_uinstr_uc0.dst .optype == OP_TRAP_DST ) uc_uinstr_uc0.dst  = trapped_uinstr.dst;
end

always_comb begin
    unique casez (fsm)
        UC_IDLE: begin
            uinstr_uc0 = uinstr_de1;
        end
        default: begin
            uinstr_uc0 = uc_uinstr_uc0;
            `ifdef SIMULATION
            uinstr_uc0.SIMID = SIMID_UROM;
            `endif
        end
    endcase
end

// Misprediction

assign nuke_rb1_valid_ql = nuke_rb1.valid & nuke_rb1.nuke_useq;
assign br_mispred_ql_ex0 = br_mispred_ex0.valid & (~br_mispred_pdg | f_robid_a_older_b(br_mispred_ex0.robid, br_mispred_robid, oldest_robid));

`DFF(br_mispred_pdg, ~reset & ~nuke_rb1_valid_ql & (br_mispred_pdg | br_mispred_ql_ex0), clk)
`DFF_EN(br_mispred_robid, br_mispred_ex0.robid, clk, br_mispred_ql_ex0)
`DFF_EN(br_mispred_resume_to_ucrom, br_mispred_ex0.ucbr, clk, br_mispred_ql_ex0)

//
// ROM
//

let GPR_8B(X)   = '{opreg: X,  optype: OP_REG,       opsize: SZ_8B};
let TRAP_SRC1() = '{opreg: '0, optype: OP_TRAP_SRC1, opsize: SZ_INV};
let TRAP_SRC2() = '{opreg: '0, optype: OP_TRAP_SRC2, opsize: SZ_INV};
let TRAP_DST()  = '{opreg: '0, optype: OP_TRAP_DST,  opsize: SZ_INV};

always_comb begin
    int r;

    for (r=0; r<UCODE_ROM_ROWS; r++) begin
        ROM[r] = f_decode_rv_instr(rvEBREAK());
    end

    // MUL algorithm
    // tmp0 := 0
    // tmp1 := tmp1
    // tmp2 := tmp2
    // while (tmp1 > 0) begin
    //    tmp3 = tmp1 & 1
    //    tmp3 = tmp3 - 1 // 1->0, 0->11111
    //    tmp3 = tmp3 ^ 111111 // 
    //    tmp4 = tmp3 & tmp2
    //    tmp0 += tmp2
    //    tmp2 <<= 1
    //    tmp1 >>= 1
    // end
    r = int'(ROM_ENT_MUL);
    ROM[r++] = uADDD_RRI(GPR_8B(REG_TMP0) , GPR_8B(REG_X0)  , 64'h0                , 1'b0);
    ROM[r++] = uADDD_RRI(GPR_8B(REG_TMP1) , TRAP_SRC1       , 64'h0                , 1'b0);
    ROM[r++] = uADDD_RRI(GPR_8B(REG_TMP2) , TRAP_SRC2       , 64'h0                , 1'b0);

    ROM[r++] = uBEQ_RR  (GPR_8B(REG_TMP1) , GPR_8B(REG_X0)  , 13'h9                , 1'b0);

    ROM[r++] = uANDD_RRI(GPR_8B(REG_TMP3) , GPR_8B(REG_TMP1), 64'h1                , 1'b0);
    ROM[r++] = uSUBD_RRI(GPR_8B(REG_TMP3) , GPR_8B(REG_TMP3), 64'h1                , 1'b0);
    ROM[r++] = uXORD_RRI(GPR_8B(REG_TMP3) , GPR_8B(REG_TMP3), 64'hFFFFFFFFFFFFFFFF , 1'b0);
    ROM[r++] = uANDD_RRR(GPR_8B(REG_TMP4) , GPR_8B(REG_TMP3), GPR_8B(REG_TMP2)     , 1'b0);
    ROM[r++] = uADDD_RRR(GPR_8B(REG_TMP0) , GPR_8B(REG_TMP0), GPR_8B(REG_TMP4)     , 1'b0);
    ROM[r++] = uSLLD_RRI(GPR_8B(REG_TMP2) , GPR_8B(REG_TMP2), 64'h1                , 1'b0);
    ROM[r++] = uSRLD_RRI(GPR_8B(REG_TMP1) , GPR_8B(REG_TMP1), 64'h1                , 1'b0);
    ROM[r++] = uBNE_RR  (GPR_8B(REG_TMP1) , GPR_8B(REG_X0)  , -7                   , 1'b0);

    ROM[r++] = uADDD_RRI(TRAP_DST         , GPR_8B(REG_TMP0), 64'h0                , 1'b1);

    r = int'(ROM_ENT_DIV);
    ROM[r++] = f_decode_rv_instr(rvADDI(23, 0, 12'hDEF));

    for (r=0; r<UCODE_ROM_ROWS; r++) begin
        ROM[r].rom_addr = t_rom_addr'(r);
        ROM[r].from_ucrom = 1'b1;
    end
end

//
// Debug
//

`ifdef ASSERT
`endif

`ifdef SIMULATION
always @(posedge clk) begin
    if (valid_uc0 & rename_ready_rn0) begin
        unique casez (fsm)
            UC_IDLE:  `UINFO(uinstr_uc0.SIMID, ("unit:UC func:decode_uop" ))
            UC_FETCH: `UINFO(uinstr_uc0.SIMID, ("unit:UC func:ucrom_uop" ))
            UC_PDG_RSM: `INFO(("unit:UC func:pdg_rsm"))
        endcase
    end
end
`endif

`ifdef ASSERT
//chk_no_change #(.T(t_uinstr)) cnc ( .clk, .reset, .hold(stall & uinstr_de1.valid & ~br_mispred_rb1), .thing(uinstr_de1) );
`endif

endmodule

`endif // __UCODE_SV

