`ifndef __GEN_FIFO_SV
`define __GEN_FIFO_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "gen_funcs.pkg"
`include "common.pkg"
`include "verif.pkg"

module gen_fifo
    import gen_funcs::*, common::*, verif::*;
#(parameter int DEPTH=8, type T=logic, string NAME = "GENERIC_FIFO")
(
    input  logic             clk,
    input  logic             reset,

    output logic             full,
    output logic             empty,

    input  logic             push_front_xw0,
    input  T                 din_xw0,

    input  logic             pop_back_xr0,
    output T                 dout_xr0
);

localparam DEPTH_LG2=$clog2(DEPTH);

//
// Nets
//

logic[DEPTH_LG2:0] push_ptr;
logic[DEPTH_LG2:0] pop_ptr;

T entries [DEPTH-1:0];

//
// Logic
//

function automatic logic[DEPTH_LG2:0] f_incr_ptr ( logic[DEPTH_LG2:0] ptr );
    if (ptr[DEPTH_LG2-1:0] == DEPTH_LG2'(DEPTH-1)) begin
        f_incr_ptr[DEPTH_LG2]     = ptr[DEPTH_LG2] ^ 1'b1;
        f_incr_ptr[DEPTH_LG2-1:0] = '0;
    end else begin
        f_incr_ptr = ptr + 1;
    end
endfunction

if(1) begin : g_push_ptr
    logic[DEPTH_LG2:0] push_ptr_nxt;
    assign push_ptr_nxt = reset          ? '0                    :
                          push_front_xw0 ? f_incr_ptr (push_ptr) :
                                           push_ptr;
    `DFF(push_ptr, push_ptr_nxt, clk)
end

if(1) begin : g_pop_ptr
    logic[DEPTH_LG2:0] pop_ptr_nxt;
    assign pop_ptr_nxt = reset        ? '0                   :
                         pop_back_xr0 ? f_incr_ptr (pop_ptr) :
                                        pop_ptr;
    `DFF(pop_ptr, pop_ptr_nxt, clk)
end

assign empty = push_ptr == pop_ptr;
assign full  = push_ptr == {pop_ptr[DEPTH_LG2] ^ 1'b1, pop_ptr[DEPTH_LG2-1:0]};

always_ff @(posedge clk) begin
    if (push_front_xw0) begin
        entries[push_ptr[DEPTH_LG2-1:0]] <= din_xw0;
    end
end

assign dout_xr0 = entries[pop_ptr[DEPTH_LG2-1:0]];

//
// Debug
//

`ifdef SIMULATION
`endif

`ifdef ASSERT
    `VASSERT(push_when_full, push_front_xw0, ~full,  "Illegal FIFO push when full")
    `VASSERT(pop_when_empty, pop_back_xr0,   ~empty, "Illegal FIFO pop when empty")
`endif

endmodule

`endif // __GEN_FIFO_SV


