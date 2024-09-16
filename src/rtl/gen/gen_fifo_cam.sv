`ifndef __GEN_FIFO_CAM_SV
`define __GEN_FIFO_CAM_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "gen_funcs.pkg"
`include "common.pkg"
`include "verif.pkg"

typedef logic[3:0]  t_gen_fifo_cam_tag;
typedef logic[63:0] t_gen_fifo_cam_data;

module gen_fifo_cam
    import gen_funcs::*, common::*, verif::*;
#(parameter int DEPTH=8, type T_TAG=t_gen_fifo_cam_tag, type T_DATA=t_gen_fifo_cam_data,string NAME = "GENERIC_FIFO_CAM")
(
    input  logic             clk,
    input  logic             reset,

    input  logic             push_xw0,
    input  T_TAG             push_tag_xw0,
    input  T_DATA            push_data_xw0,

    input  T_TAG             cam_in_xr0,
    output T_DATA            cam_mat_data_xr0,
    output logic             cam_hit_xr0
);

localparam DEPTH_LG2=$clog2(DEPTH);

//
// Nets
//

logic[DEPTH_LG2-1:0] push_ptr;

T_TAG  tags [DEPTH-1:0];
T_DATA data [DEPTH-1:0];

logic[DEPTH-1:0] valids;

//
// Logic
//

if(1) begin : g_push_ptr
    logic[DEPTH_LG2:0] push_ptr_nxt;
    assign push_ptr_nxt = reset ? '0 : (push_ptr == (DEPTH-1)) ? '0 : push_ptr + 1'b1;
    `DFF(push_ptr, push_ptr_nxt, clk)
end

logic[DEPTH-1:0] push_mats;
logic[DEPTH_LG2-1:0] push_mat_enc;
for (genvar i=0; i<DEPTH; i++) begin : g_push_mats
    assign push_mats[i] = valids[i] & push_tag_xw0 == tags[i];
end
assign push_mat_enc = gen_lg2_funcs#(.IWIDTH(DEPTH))::oh_encode(push_mats);

always_ff @(posedge clk) begin
    if (reset) begin
        valids = '0;
    end else if (push_xw0) begin
        if (|push_mats) begin
            data[push_mat_enc] <= push_data_xw0;
        end else begin
            tags[push_ptr] <= push_tag_xw0;
            data[push_ptr] <= push_data_xw0;
            valids[push_ptr] <= 1'b1;
        end
    end
end

logic[DEPTH-1:0] cam_hits_xr0;
for (genvar i=0; i<DEPTH; i++) begin : g_cam_hits
    assign cam_hits_xr0[i] = valids[i] & tags[i] == cam_in_xr0;
end
assign cam_hit_xr0 = |cam_hits_xr0;
assign cam_mat_data_xr0 = mux_funcs#(.IWIDTH(DEPTH), .T(T_DATA))::uaomux(data, cam_hits_xr0);

//
// Debug
//

`ifdef SIMULATION
`endif

`ifdef ASSERT
    // `VASSERT(push_when_full, push_front_xw0[0], ~full,  "Illegal FIFO push when full")
    // `VASSERT(pop_when_empty, pop_back_xr0[0],   ~empty, "Illegal FIFO pop when empty")
`endif

endmodule

`endif // __GEN_FIFO_CAM_SV


