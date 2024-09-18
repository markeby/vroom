`ifndef __GEN_FIFO_SV
`define __GEN_FIFO_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "gen_funcs.pkg"
`include "common.pkg"
`include "verif.pkg"

module gen_fifo
    import gen_funcs::*, common::*, verif::*;
#(parameter int DEPTH=8, int NPUSH=2, int NPOP=2, type T=logic, string NAME = "GENERIC_FIFO")
(
    input  logic             clk,
    input  logic             reset,

    output logic             full,
    output logic             empty,

    output logic[$clog2(NPUSH):0] num_push_ok,

    input  logic             push_front_xw0 [NPUSH-1:0],
    input  T                 din_xw0        [NPUSH-1:0],

    input  logic             pop_back_xr0   [NPOP-1:0],
    output logic             valid_xr0      [NPOP-1:0],
    output T                 dout_xr0       [NPOP-1:0]
);

localparam DEPTH_LG2=$clog2(DEPTH);

//
// Nets
//

logic[DEPTH_LG2:0] push_ptr;
logic[DEPTH_LG2:0] pop_ptr;

logic[DEPTH_LG2:0] push_ptr_port [NPUSH-1:0];
logic[DEPTH_LG2:0] pop_ptr_port  [NPOP-1:0];

T entries [DEPTH-1:0];

logic[DEPTH_LG2:0] num_valid;
logic[$clog2(NPOP):0] num_pop_ok;

//
// Helper functions
//

function automatic logic[DEPTH_LG2:0] f_incr_ptr ( logic[DEPTH_LG2:0] ptr, int num );
    if (num == 0) begin
        return ptr;
    end

    if (num > 1) begin
        f_incr_ptr = f_incr_ptr(ptr, num-1);
    end

    if (ptr[DEPTH_LG2-1:0] == DEPTH_LG2'(DEPTH-1)) begin
        f_incr_ptr[DEPTH_LG2]     = ptr[DEPTH_LG2] ^ 1'b1;
        f_incr_ptr[DEPTH_LG2-1:0] = '0;
    end else begin
        f_incr_ptr = ptr + 1;
    end
endfunction

//
// Logic
//

localparam NPUSH_LG2    = $clog2(NPUSH);
localparam NPOP_LG2     = $clog2(NPOP);
localparam NPUSH_LG2_P1 = 1 + NPUSH_LG2;
localparam NPOP_LG2_P1  = 1 + NPOP_LG2;

logic[NPUSH_LG2:0] num_push_xw0;
assign num_push_xw0 = counter_funcs#(.IWIDTH(NPUSH))::ucountones(push_front_xw0);

logic[NPUSH_LG2:0] num_pop_xr0;
assign num_pop_xr0 = counter_funcs#(.IWIDTH(NPOP))::ucountones(pop_back_xr0);

// Pointers are always the "port 0" case
if(1) begin : g_push_ptr
    logic[DEPTH_LG2:0] push_ptr_nxt;
    assign push_ptr_nxt = reset ? '0 : f_incr_ptr(push_ptr, int'(num_push_xw0));
    `DFF(push_ptr, push_ptr_nxt, clk)
end

if(1) begin : g_pop_ptr
    logic[DEPTH_LG2:0] pop_ptr_nxt;
    assign pop_ptr_nxt = reset ? '0 : f_incr_ptr(pop_ptr, int'(num_pop_xr0));
    `DFF(pop_ptr, pop_ptr_nxt, clk)
end

// Generate _port versions of the pointers for individual push and pop ports
assign push_ptr_port[0] = push_ptr;
for (genvar p=1; p<NPUSH; p++) begin : g_push_ptr_port
    assign push_ptr_port[p] = push_front_xw0[p-1] ? f_incr_ptr(push_ptr_port[p-1],1) : push_ptr_port[p-1];
end

assign pop_ptr_port[0] = pop_ptr;
for (genvar p=1; p<NPUSH; p++) begin : g_pop_ptr_port
    assign pop_ptr_port[p] = pop_back_xr0[p-1] ? f_incr_ptr(pop_ptr_port[p-1],1) : pop_ptr_port[p-1];
end

assign empty = push_ptr == pop_ptr;
assign full  = push_ptr == {pop_ptr[DEPTH_LG2] ^ 1'b1, pop_ptr[DEPTH_LG2-1:0]};

always_ff @(posedge clk) begin
    for (int p=0; p<NPUSH; p++) begin : g_ent_wr
        if (push_front_xw0[p]) begin
            entries[push_ptr_port[p][DEPTH_LG2-1:0]] <= din_xw0[p];
        end
    end
end

always_comb begin
    for (int p=0; p<NPOP; p++) begin : g_ent_rd
        assign dout_xr0[p] = entries[pop_ptr_port[p][DEPTH_LG2-1:0]];
    end
end

//
// push_ok / pop_ok
//

assign num_valid   = (push_ptr[DEPTH_LG2] == pop_ptr[DEPTH_LG2]) ? (push_ptr - pop_ptr) : ({1'b1, push_ptr[DEPTH_LG2-1:0]} - {1'b0, pop_ptr[DEPTH_LG2-1:0]});
assign num_push_ok = NPUSH_LG2_P1'(((DEPTH - int'(num_valid)) > NPUSH) ? int'(NPUSH) : DEPTH - int'(num_valid));
assign num_pop_ok  = NPOP_LG2_P1 '(((        int'(num_valid)) > NPOP ) ? int'(NPOP ) :         int'(num_valid));

for (genvar p=0; p<NPOP; p++) begin : g_valids
    assign valid_xr0[p] = (num_pop_ok > p);
end

//
// Debug
//

`ifdef SIMULATION
`endif

`ifdef ASSERT
    `VASSERT(a_push_when_full, push_front_xw0[0], ~full,  "Illegal FIFO push when full")
    // `VASSERT(pop_when_empty, pop_back_xr0[0],   ~empty, "Illegal FIFO pop when empty")
`endif

endmodule

`endif // __GEN_FIFO_SV


