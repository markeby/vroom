`ifndef __L2_SV
`define __L2_SV

`include "vroom_macros.sv"
`include "mem_common.pkg"
`include "mem_defs.pkg"
`include "gen_funcs.pkg"

module l2
    import common::*, gen_funcs::*, mem_defs::*, mem_common::*;
(
    input  logic            clk,
    input  logic            reset,

    input  t_mem_req_pkt    dc_l2_req_pkt,
    output t_mem_rsp_pkt    l2_dc_rsp_pkt,

    input  t_mem_req_pkt    ic_l2_req_pkt,
    output t_mem_rsp_pkt    l2_ic_rsp_pkt
);

//
// Nets
//

logic[7:0] MEMORY [t_paddr];

localparam NUM_PORTS  = 2;
t_mem_req_pkt all_req_pkts [NUM_PORTS-1:0];
t_mem_rsp_pkt all_rsp_pkts [NUM_PORTS-1:0];

//
// Logic
//

assign all_req_pkts[0] = dc_l2_req_pkt;
assign l2_dc_rsp_pkt   = all_rsp_pkts[0];

assign all_req_pkts[1] = ic_l2_req_pkt;
assign l2_ic_rsp_pkt   = all_rsp_pkts[1];

/* verilator lint_off WIDTHTRUNC */
always @(posedge clk) begin
    for (int p=0; p<NUM_PORTS; p++) begin
        if(all_req_pkts[p].valid) begin
            if (all_req_pkts[p].op inside {MEM_OP_READ, MEM_OP_READ_INV}) begin
                all_rsp_pkts[p].valid <= 1'b1;
                all_rsp_pkts[p].id    <= all_req_pkts[p].id;
                for (t_paddr b=0; b<CL_SZ_BYTES; b++) begin
                    if (MEMORY.exists(t_paddr'(all_req_pkts[p].addr + b))) begin
                        all_rsp_pkts[p].data.B[b] <= MEMORY[t_paddr'(all_req_pkts[p].addr + b)];
                    end else begin
                        all_rsp_pkts[p].data.B[b] <= 8'hFF;
                    end
                end
            end else if (all_req_pkts[p].op inside {MEM_OP_WRITE}) begin
                for (t_paddr b=0; b<CL_SZ_BYTES; b++) begin
                    MEMORY[t_paddr'(all_req_pkts[p].addr + b)] <= all_req_pkts[p].data.B[b];
                end
            end
        end else begin
            all_rsp_pkts[p] <= '0;
        end
    end
end
/* verilator lint_on WIDTHTRUNC */

//
// Debug
//

`ifdef SIMULATION
// always @(posedge clk) begin
//     if (iss_mm0) begin
//         `INFO(("unit:MM %s", describe_uinstr(iss_pkt_mm0.uinstr)))
//     end
// end
`endif

`ifdef ASSERT
// `VASSERT(a_alloc_when_valid, e_alloc_mm0, ~e_valid, "Allocated loadq entry while valid")
`endif

endmodule

`endif // __L2_SV


