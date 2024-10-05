`ifndef __BPU_SV
`define __BPU_SV

`include "instr.pkg"
`include "verif.pkg"
`include "asm.pkg"
`include "mem_common.pkg"
`include "vroom_macros.sv"

module bpu
    import instr::*, common::*, mem_common::*, verif::*, instr_decode::*;
(
    input  logic       clk,
    input  logic       reset,

    input  t_bpu_train_pkt
                       bpu_train_pkt_ex0,

    input  logic       valid_fe1,
    input  logic       decode_ready_de0,
    input  t_rv_instr  instr_fe1,
    input  t_paddr     pc,
    output t_paddr     pred_pc_nxt,
    output logic       pred_tkn
);

localparam BTB_ROWS = 32;
localparam BTB_ROWS_LG2 = $clog2(BTB_ROWS);

typedef struct packed {
    t_paddr target;
    t_paddr pc;
    logic   valid;
} t_btb_row;

//
// Nets
//

logic [1:0] cntr;
t_btb_row   btb [BTB_ROWS-1:0];

logic       btb_hit_fe1;
t_paddr     btb_tgt_fe1;
logic       pred_tkn_fe1;
logic       is_br_fe1;

//
// Logic
//

always_ff @(posedge clk) begin
    if (reset) begin
        for (int i=0; i<BTB_ROWS; i++) begin
            btb[i] <= t_btb_row'('0);
        end
    end else begin
        if (bpu_train_pkt_ex0.valid & bpu_train_pkt_ex0.taken) begin
            btb[bpu_train_pkt_ex0.pc[2 +: BTB_ROWS_LG2]] <= '{target: bpu_train_pkt_ex0.target, pc: bpu_train_pkt_ex0.pc, valid: 1'b1};
        end
    end
end

always_comb begin
    automatic t_btb_row btb_row;
    btb_row = btb[pc[2 +: BTB_ROWS_LG2]];
    btb_hit_fe1 = btb_row.valid & btb_row.pc == pc;
    btb_tgt_fe1 = btb_row.target;
end

assign is_br_fe1 = rv_opcode_is_br(instr_fe1.opcode) | rv_opcode_is_jalr(instr_fe1.opcode) | rv_opcode_is_jal(instr_fe1.opcode);

//
// 2b counter
//

logic[1:0] cntr_nxt;
if (1) begin : twobitcntr
    logic cntr_inc_ex0;
    logic cntr_dec_ex0;

    assign cntr_inc_ex0 = bpu_train_pkt_ex0.valid &  bpu_train_pkt_ex0.taken;
    assign cntr_dec_ex0 = bpu_train_pkt_ex0.valid & ~bpu_train_pkt_ex0.taken;
    assign cntr_nxt = reset                   ? 2'b01       :
                      cntr_inc_ex0 & (~&cntr) ? cntr + 1'b1 :
                      cntr_dec_ex0 & ( |cntr) ? cntr - 1'b1 :
                                                cntr;
end
`DFF(cntr, cntr_nxt, clk)

assign pred_tkn = cntr[1] & btb_hit_fe1 & is_br_fe1;
assign pred_pc_nxt = btb_tgt_fe1;

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (valid_fe1 & decode_ready_de0 & is_br_fe1 & ~reset) begin
        `UINFO(fe_ctl.instr_fe1.SIMID, ("unit:BPU pc:%h hit:%-1d pred_tkn:%-1d pred_pc_nxt:%h", pc, btb_hit_fe1, pred_tkn, pred_pc_nxt))
    end
end
`endif

endmodule

`endif // __BPU_SV

