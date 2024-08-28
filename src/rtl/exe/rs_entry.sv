`ifndef __RS_ENTRY_SV
`define __RS_ENTRY_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "common.pkg"
`include "vroom_macros.sv"

typedef struct packed {
   t_uinstr_disp uinstr_disp;
} t_rs_entry_static

module rs_entry
    import instr::*, instr_decode::*, common::*;
(
    input  logic          clk,
    input  logic          reset,

    input  logic          wb_valid_ro1,
    input  t_rob_id       wb_robid_ro1,
    input  t_rv_reg_data  wb_result_ro1,

    input  logic          e_alloc_rs0,
    input  t_uinstr_disp  q_alloc_static_rs0,
    input  t_rv_reg_data  rddatas_rs0 [1:0],

    output logic          e_static,
    output logic          issue_ready_rs1
);

localparam RS_ENTRY0 = 0;
localparam RS_ENTRY1 = 1;
localparam NUM_EX_STAGES = 1;

//
// Nets
//

//
// Logic
//

//
// Register tracking
//

localparam SRC1=0;
localparam SRC2=1;

t_rs_reg_trk_static    e_alloc_static_rs0[NUM_SOURCES-1:0];
t_rv_reg_data          regrd_data_rs0    [NUM_SOURCES-1:0];
t_rv_reg_data          src_data_rs1      [NUM_SOURCES-1:0];
logic[NUM_SOURCES-1:0] src_ready_rs1;

assign e_alloc_static_rs0[SRC1].from_rob = q_alloc_static_rs0.src1_rob_pdg;
assign e_alloc_static_rs0[SRC1].robid    = q_alloc_static_rs0.src1_robid;
assign e_alloc_static_rs0[SRC1].descr    = q_alloc_static_rs0.uinstr.src1;

assign e_alloc_static_rs0[SRC2].from_rob = q_alloc_static_rs0.src2_rob_pdg;
assign e_alloc_static_rs0[SRC2].robid    = q_alloc_static_rs0.src2_robid;
assign e_alloc_static_rs0[SRC2].descr    = q_alloc_static_rs0.uinstr.src2;

assign regrd_data_rs0[SRC1] = rddatas_rs0[0];
assign regrd_data_rs0[SRC2] = rddatas_rs0[1];

for (genvar srcx=0; srcx<NUM_SOURCES; srcx++) begin : g_src_trk
   rs_reg_trk rs_reg_trk (
      .clk,
      .reset,
      .e_alloc_rs0,
      .e_alloc_static_rs0 ( e_alloc_static_rs0[srcx] ) ,
      .regrd_data_rs0     ( regrd_data_rs0[srcx]     ) ,
      .e_static           (                          ) ,
      .wb_valid_ro1,
      .wb_robid_ro1,
      .wb_result_ro1,
      .ready_rs1          ( src_ready_rs1[srcx]      ) ,
      .src_data           ( src_data_rs1[srcx]       )
   );
end


//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (uinstr_rd1.valid) begin
        `INFO(("unit:EX %s result:%08h", describe_uinstr(uinstr_rd1), result_exx[RS_ENTRY0]))
    end
end
`endif

`ifdef ASSERT
//VASSERT(a_br_mispred, uinstr_rd1.valid & ibr_resvld_ex0, ~ibr_mispred_ex0, "Branch mispredictions not yet supported.")
`endif

endmodule

`endif // __RS_ENTRY_SV

