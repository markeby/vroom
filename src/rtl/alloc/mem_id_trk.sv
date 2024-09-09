`ifndef __MEM_ID_TRK_SV
`define __MEM_ID_TRK_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "common.pkg"
`include "vroom_macros.sv"
`include "verif.pkg"

module mem_id_trk
   import instr::*, instr_decode::*, common::*, verif::*;
(
    input  logic         clk,
    input  logic         reset,

    input  logic         stq_alloc_ra0,
    output t_stq_id      stq_id_ra0,
    output logic         stq_full_ra0,

    input  logic         ldq_alloc_ra0,
    output t_ldq_id      ldq_id_ra0,
    output logic         ldq_full_ra0
);

//
// Nets
//

//
// Logic
//

gen_wrapped_id_trk #(.T(t_ldq_id), .NUM_ENTS(LDQ_NUM_ENTRIES)) gen_ldq_id (
    .clk,
    .reset,

    .alloc   ( ldq_alloc_ra0 ) ,
    .dealloc ( 1'b0          ) ,
    .head_id ( '0            ) ,
    .tail_id ( ldq_id_ra0    ) ,

    .empty   (               ) ,
    .full    ( ldq_full_ra0  )
);

gen_wrapped_id_trk #(.T(t_stq_id), .NUM_ENTS(STQ_NUM_ENTRIES)) gen_stq_id (
    .clk,
    .reset,

    .alloc   ( stq_alloc_ra0 ) ,
    .dealloc ( 1'b0          ) ,
    .head_id ( '0            ) ,
    .tail_id ( stq_id_ra0    ) ,

    .empty   (               ) ,
    .full    ( stq_full_ra0  )
);

//
// Debug
//

`ifdef SIMULATION
    // always @(posedge clk) begin
    //     if (disp_valid_rs0) begin
    //         `UINFO(disp_pkt_rs0.uinstr.SIMID, ("unit:RA robid:0x%0x pdst:0x%0x psrc1:0x%0x psrc2:0x%0x %s", 
    //             disp_pkt_rs0.robid, disp_pkt_rs0.rename.pdst, disp_pkt_rs0.rename.psrc1, disp_pkt_rs0.rename.psrc2, 
    //             describe_uinstr(disp_pkt_rs0.uinstr)))
    //     end
    // end
`endif

`ifdef ASSERT
//VASSERT(a_br_mispred, uinstr_rd1.valid & ibr_resvld_ex0, ~ibr_mispred_ex0, "Branch mispredictions not yet supported.")
`endif

endmodule

`endif // __MEM_ID_TRK_SV

