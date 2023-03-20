`ifndef __GPRS_SV
`define __GPRS_SV

`include "instr.pkg"
`include "vroom_macros.sv"

module gprs 
    import instr::*;
#(parameter int NUMRD=2, NUMWR=1)
(
    input  logic         clk,
    input  logic         reset,

    input  logic         rden   [NUMRD-1:0],
    input  t_rv_reg_addr rdaddr [NUMRD-1:0],
    output t_rv_reg_data rddata [NUMRD-1:0],

    input  logic         wren   [NUMWR-1:0],
    input  t_rv_reg_addr wraddr [NUMWR-1:0],
    input  t_rv_reg_data wrdata [NUMWR-1:0]
);

//
// Nets
//

t_rv_reg_data REGS [RV_NUM_REGS-1:0];

//
// Logic
//

always_ff @(posedge clk) begin
    for (int rp=0; rp<NUMRD; rp++) begin
        if (rden[rp]) begin
            rddata[rp] <= REGS[rdaddr[rp]];
        end
    end
end

always_ff @(posedge clk) begin
    for (int wp=0; wp<NUMWR; wp++) begin
        if (wren[wp]) begin
            REGS[wraddr[wp]] <= wrdata[wp];
        end
    end
end

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    for (int p=0; p<NUMRD; p++) begin
        if (rden[p]) begin
            `INFO(("UNIT:RF op:read addr:%d data:%08h", rdaddr[p], REGS[rdaddr[p]]))
        end
    end
    for (int p=0; p<NUMRD; p++) begin
        if (wren[p]) begin
            `INFO(("UNIT:RF op:write addr:%d data:%08h->%08h", rdaddr[p], REGS[rdaddr[p]], wrdata[p]))
        end
    end
end
`endif

`ifdef ASSERT
    //VASSERT(a_illegal_rd0, rden[0], rdaddr[0] != 0, $sformatf("Illegal read to x0 from port%d", 0))
`endif

endmodule

`endif // __GPRS_SV


