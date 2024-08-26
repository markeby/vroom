`ifndef __TOP_SV
`define __TOP_SV

`include "vroom_macros.sv"

module top (
    input logic clk,
    input logic reset
);

int cclk_count;
initial cclk_count = '0;
`DFF(cclk_count, cclk_count+1, clk)
always @(posedge clk) begin
    `DEBUG(("Tick tock!"))
end

logic rst_dly;
`DFF(rst_dly, reset, clk);

core core (
    .clk,
    .reset ( rst_dly )
);
endmodule

`endif // __TOP_SV
