`ifndef __ICACHE_SV
`define __ICACHE_SV

`include "instr.pkg"
`include "asm.pkg"
`include "mem_common.pkg"
`include "vroom_macros.sv"

module icache
    import instr::*, asm::*, mem_common::*, common::*;
    #(parameter int LATENCY=1)
(
    input  logic      clk,
    input  logic      reset,
    input  t_mem_req_pkt  fb_ic_req_nnn,
    output t_mem_rsp_pkt  ic_fb_rsp_nnn,

    output t_mem_req_pkt  ic_l2_req_pkt,
    input  t_mem_rsp_pkt  l2_ic_rsp_pkt
);

assign ic_l2_req_pkt = fb_ic_req_nnn;
assign ic_fb_rsp_nnn = l2_ic_rsp_pkt;

//
// Displays
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (~reset & fb_ic_req_nnn.valid) begin
        `MEMLOG(("unit:IC type:fb_ic_req_nnn id:%d addr:%h", fb_ic_req_nnn.id, fb_ic_req_nnn.addr))
    end
    if (~reset & ic_fb_rsp_nnn.valid) begin
        `MEMLOG(("unit:IC type:ic_fb_rsp_nnn id:%d data:%h", ic_fb_rsp_nnn.id, ic_fb_rsp_nnn.data))
    end
end
`endif

endmodule

`endif // __ICACHE_SV


