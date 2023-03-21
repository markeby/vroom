`ifndef __ICACHE_SV
`define __ICACHE_SV

`include "instr.pkg"
`include "asm.pkg"
`include "mem_common.pkg"
`include "vroom_macros.sv"

module icache
    import instr::*, asm::*, mem_common::*, common::*;
(
    input  logic      clk,
    input  logic      reset,
    input  t_mem_req  fe_ic_req_nnn,
    output t_mem_rsp  ic_fe_rsp_nnn
);

localparam IROM_SZ     = 128;
localparam IROM_SZ_LG2 = $clog2(IROM_SZ);

t_word IROM [IROM_SZ-1:0];


//
// Lookup
//

always_ff @(posedge clk) begin
    ic_fe_rsp_nnn.valid <= fe_ic_req_nnn.valid;
    ic_fe_rsp_nnn.id    <= fe_ic_req_nnn.id;
    ic_fe_rsp_nnn.data  <= IROM[fe_ic_req_nnn.addr[IROM_SZ_LG2:1]];
    `ifdef SIMULATION
    ic_fe_rsp_nnn.__addr_inst <= fe_ic_req_nnn.addr;
    `endif
end

//
// ROM
//

initial begin
    automatic int a=0;
    for (int i=0; i<IROM_SZ; i++) begin
        IROM[i] = rvSUB(0,0,0);
    end

    a=0;

    //define TEST_ALL_DEPS
    //define TEST_NO_DEPS
    //define TEST_ARITH
    //define TEST_LOGICAL
    //define TEST_SLT
    `define TEST_BEEF

    IROM[a++] = rvXOR(1,1,1);
    IROM[a++] = rvXOR(2,2,2);
    IROM[a++] = rvXOR(3,3,3);
    IROM[a++] = rvXOR(4,4,4);
    IROM[a++] = rvXOR(5,5,5);

    IROM[a++] = rvXOR(1,1,1);
    IROM[a++] = rvXOR(2,1,1);
    IROM[a++] = rvXOR(3,2,2);
    IROM[a++] = rvXOR(4,3,3);
    IROM[a++] = rvXOR(5,4,4);
    IROM[a++] = rvXOR(6,5,5);
    IROM[a++] = rvXOR(7,6,6);
    IROM[a++] = rvXOR(8,7,7);
    IROM[a++] = rvXOR(9,8,8);

    `ifdef TEST_BEEF
        IROM[a++] = rvXOR(1,1,1);
        IROM[a++] = rvADDI(1,1,12'hDE); IROM[a++] = rvSLLI(1,1,5'd8);
        IROM[a++] = rvADDI(1,1,12'hAD); IROM[a++] = rvSLLI(1,1,5'd8);
        IROM[a++] = rvADDI(1,1,12'hBE); IROM[a++] = rvSLLI(1,1,5'd8);
        IROM[a++] = rvADDI(1,1,12'hEF); 
        IROM[a++] = rvADDI(2,2,12'hCA); IROM[a++] = rvSLLI(2,2,5'd8);
        IROM[a++] = rvADDI(2,2,12'hFE); IROM[a++] = rvSLLI(2,2,5'd8);
        IROM[a++] = rvADDI(2,2,12'hBA); IROM[a++] = rvSLLI(2,2,5'd8);
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
        IROM[a++] = rvSRAI(20,18,5'h1);
        IROM[a++] = rvSRLI(21,18,5'h1);
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

    IROM[a++] = rvADDI(0,0,12'h666); // magic to end test
    IROM[a++] = rvHALT();

end

//
// Displays
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (~reset & fe_ic_req_nnn.valid) begin
        `MEMLOG(("unit:IC type:fe_ic_req_nnn id:%d addr:%h", fe_ic_req_nnn.id, fe_ic_req_nnn.addr))
    end
    if (~reset & ic_fe_rsp_nnn.valid) begin
        `MEMLOG(("unit:IC type:ic_fe_rsp_nnn id:%d data:%h", ic_fe_rsp_nnn.id, ic_fe_rsp_nnn.data))
    end
end
`endif

endmodule

`endif // __ICACHE_SV


