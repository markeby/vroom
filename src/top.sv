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

always @(posedge clk) begin
    if (cclk_count > 100) begin
        $finish();
    end
end

core core (
    .clk,
    .reset
);
endmodule

`endif // __TOP_SV 
