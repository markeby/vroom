`ifndef __GEN_WRAPPED_ID_TRK_SV
`define __GEN_WRAPPED_ID_TRK_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "common.pkg"
`include "vroom_macros.sv"
`include "verif.pkg"

module gen_wrapped_id_trk
   import instr::*, instr_decode::*, common::*, verif::*;
   #(parameter type T=t_rob_id, int NUM_ENTS=8)
(
    input  logic         clk,
    input  logic         reset,

    input  logic         alloc,
    input  logic         dealloc,
    output T             head_id,
    output T             tail_id,

    output logic         empty,
    output logic         full
);

localparam NUM_ENTS_LG2 = $clog2(NUM_ENTS);

function automatic T f_incr_id(T id);
    f_incr_id = id;
    if ({1'b0,f_incr_id.idx} == NUM_ENTS-1) begin
        f_incr_id.wrap ^= 1'b1;
        f_incr_id.idx   = '0;
    end else begin
        f_incr_id.idx  += 1'b1;
    end
endfunction

//
// Nets
//

T head_id_nxt;
T tail_id_nxt;

//
// Logic
//

assign head_id_nxt = reset   ? T'('0)             :
                     dealloc ? f_incr_id(head_id) :
                               head_id;
`DFF(head_id, head_id_nxt, clk)

assign tail_id_nxt = reset   ? T'('0)             :
                     alloc   ? f_incr_id(tail_id) :
                               tail_id;
`DFF(tail_id, tail_id_nxt, clk)

assign empty = head_id == tail_id;
assign full  = head_id.idx == tail_id.idx & ~empty;

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

`endif // __GEN_WRAPPED_ID_TRK_SV

