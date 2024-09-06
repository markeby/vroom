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
    input  t_mem_req  fb_ic_req_nnn,
    output t_mem_rsp  ic_fb_rsp_nnn
);

localparam IROM_SZ     = 128;
localparam IROM_SZ_LG2 = $clog2(IROM_SZ);

t_word IROM [IROM_SZ-1:0];

t_mem_rsp ic_fb_rsp_pipe_nnn [LATENCY-1:0];
for (genvar i=1; i<LATENCY; i++) begin : g_fbrsppipe
    `DFF(ic_fb_rsp_pipe_nnn[i], ic_fb_rsp_pipe_nnn[i-1], clk)
end
always_comb ic_fb_rsp_nnn = ic_fb_rsp_pipe_nnn[LATENCY-1];

//
// Lookup
//

always_ff @(posedge clk) begin
    ic_fb_rsp_pipe_nnn[0].valid <= fb_ic_req_nnn.valid;
    ic_fb_rsp_pipe_nnn[0].id    <= fb_ic_req_nnn.id;
    for (int w=0; w<CL_SZ_WORDS; w++) begin
        int waddr = int'(fb_ic_req_nnn.addr[2 +: IROM_SZ_LG2]) + int'(w);
        ic_fb_rsp_pipe_nnn[0].data.W[w]  <= IROM[waddr];
    end
    `ifdef SIMULATION
    ic_fb_rsp_pipe_nnn[0].__addr_inst <= fb_ic_req_nnn.addr;
    `endif
end

//
// ROM
//

initial begin
    automatic int a=0;
    for (int i=0; i<IROM_SZ; i++) begin
        IROM[i] = rvADDI(30,0,12'h666);
    end

    a=0;

    // `define TEST_ALL_DEPS
    // `define TEST_NO_DEPS
    // `define TEST_ARITH
    //`define TEST_LOGICAL
    //`define TEST_SLT
    //`define TEST_BR_NT
    `define TEST_BR_T
    //`define TEST_BEEF

    // IROM[a++] = rvADDI(1,1,12'h1);
    // IROM[a++] = rvADDI(8,8,12'h1);
    // IROM[a++] = rvADDI(8,8,12'h1);
    // IROM[a++] = rvADDI(4,4,12'h1);
    // IROM[a++] = rvADDI(2,2,12'h1);
    // IROM[a++] = rvADDI(8,8,12'h1);
    // IROM[a++] = rvADDI(4,4,12'h1);
    // IROM[a++] = rvADDI(4,4,12'h1);
    // IROM[a++] = rvADDI(8,8,12'h1);
    // IROM[a++] = rvADDI(8,8,12'h1);
    // IROM[a++] = rvADDI(8,8,12'h1);
    // IROM[a++] = rvADDI(4,4,12'h1);
    // IROM[a++] = rvADDI(8,8,12'h1);
    // IROM[a++] = rvADDI(2,2,12'h1);
    // IROM[a++] = rvADDI(8,8,12'h1);
    // IROM[a++] = rvBNE(0,1,8);
    // IROM[a++] = rvADDI(0,0,12'h42);
    // IROM[a++] = rvADDI(1,1,32);

    // IROM[a++] = rvXOR(1,1,1);
    // IROM[a++] = rvXOR(2,2,2);
    // IROM[a++] = rvXOR(3,3,3);
    // IROM[a++] = rvXOR(4,4,4);
    // IROM[a++] = rvXOR(5,5,5);

    // IROM[a++] = rvXOR(1,1,1);
    // IROM[a++] = rvXOR(2,1,1);
    // IROM[a++] = rvXOR(3,2,2);
    // IROM[a++] = rvXOR(4,3,3);
    // IROM[a++] = rvXOR(5,4,4);
    // IROM[a++] = rvXOR(6,5,5);
    // IROM[a++] = rvXOR(7,6,6);
    // IROM[a++] = rvXOR(8,7,7);
    // IROM[a++] = rvXOR(9,8,8);

    `ifdef TEST_BR_NT
        IROM[a++] = rvXOR(1,1,1);
        IROM[a++] = rvADDI(1,1,32);
        IROM[a++] = rvBEQ(0,1,8);
        IROM[a++] = rvADDI(0,0,12'h42);
        IROM[a++] = rvADDI(1,1,32);
    `endif
    `ifdef TEST_BR_T
        IROM[a++] = rvXOR(1,1,1);
        IROM[a++] = rvADDI(1,1,32);
        IROM[a++] = rvBNE(0,1,8);
        IROM[a++] = rvADDI(31,0,12'h666);
        IROM[a++] = rvADDI(1,1,32);
    `endif
    `ifdef TEST_BEEF
        IROM[a++] = rvXOR(1,1,1);
        IROM[a++] = rvADDI(1,1,12'hDE); IROM[a++] = rvSLLI(1,1,6'd8);
        IROM[a++] = rvADDI(1,1,12'hAD); IROM[a++] = rvSLLI(1,1,6'd8);
        IROM[a++] = rvADDI(1,1,12'hBE); IROM[a++] = rvSLLI(1,1,6'd8);
        IROM[a++] = rvADDI(1,1,12'hEF);
        IROM[a++] = rvADDI(2,2,12'hCA); IROM[a++] = rvSLLI(2,2,6'd8);
        IROM[a++] = rvADDI(2,2,12'hFE); IROM[a++] = rvSLLI(2,2,6'd8);
        IROM[a++] = rvADDI(2,2,12'hBA); IROM[a++] = rvSLLI(2,2,6'd8);
        IROM[a++] = rvADDI(2,2,12'hBE);
    `endif
    `ifdef TEST_ALL_DEPS
        IROM[a++] = rvADDI(1,1,1);
        IROM[a++] = rvADDI(1,1,1);
        IROM[a++] = rvADDI(1,1,1);
        IROM[a++] = rvADDI(1,1,1);
        IROM[a++] = rvADDI(1,1,1);
    `endif // TEST_ALL_DEPS
    `ifdef TEST_NO_DEPS
        IROM[a++] = rvADDI(1,1,1);
        IROM[a++] = rvXORI(2,1,1);
        IROM[a++] = rvXORI(3,1,1);
        IROM[a++] = rvXORI(4,1,1);
        IROM[a++] = rvXORI(5,1,1);
        IROM[a++] = rvXORI(6,1,1);
        IROM[a++] = rvXORI(7,1,1);
    `endif //TEST_NO_DEPS
    `ifdef TEST_ARITH
        IROM[a++] = rvADDI(1,1,12'h123);
        IROM[a++] = rvADDI(2,1,12'h123);
        IROM[a++] = rvADD(3,1,2);
        IROM[a++] = rvSUB(16,3,1);
    `endif //TEST_ARITH
    `ifdef TEST_LOGICAL
        IROM[a++] = rvXOR(2,2,2);
        IROM[a++] = rvADDI(1,0,12'h111);
        IROM[a++] = rvADDI(17,0,12'h654);
        IROM[a++] = rvXORI(18,16,12'hfff);
        IROM[a++] = rvSRAI(20,18,6'h1);
        IROM[a++] = rvSRLI(21,18,6'h1);
        IROM[a++] = rvXOR(22,20,21);
    `endif //TEST_LOGICAL
    `ifdef TEST_SLT
        IROM[a++] = rvXOR(1,1,1);
        IROM[a++] = rvADDI(2,1,12'h50);
        IROM[a++] = rvADDI(3,1,12'h4f);
        IROM[a++] = rvADDI(4,1,12'h50);
        IROM[a++] = rvADDI(5,1,12'h51);
        IROM[a++] = rvSUB(6,1,5);
        IROM[a++] = rvADDI(7,6,12'h1);
        IROM[a++] = rvADDI(8,6,12'hfff);

        IROM[a++] = rvSLT(12,1,2);
        IROM[a++] = rvSLT(13,1,3);
        IROM[a++] = rvSLT(14,1,4);
        IROM[a++] = rvSLT(15,1,5);
        IROM[a++] = rvSLT(16,1,6);
        IROM[a++] = rvSLT(17,1,7);
        IROM[a++] = rvSLT(18,1,8);

        IROM[a++] = rvSLTU(12,1,2);
        IROM[a++] = rvSLTU(13,1,3);
        IROM[a++] = rvSLTU(14,1,4);
        IROM[a++] = rvSLTU(15,1,5);
        IROM[a++] = rvSLTU(16,1,6);
        IROM[a++] = rvSLTU(17,1,7);
        IROM[a++] = rvSLTU(18,1,8);
    `endif //TEST_SLT

    // IROM[a++] = rvADDI(6,0,12'h666); // magic to end test
    // IROM[a++] = rvXOR(0,0,0);
    // IROM[a++] = rvXOR(0,0,0);
    // IROM[a++] = rvXOR(0,0,0);
    IROM[a++] = rvEBREAK();

end

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


