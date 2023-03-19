`ifndef __TOP_SV
`define __TOP_SV 

module top (
    input logic clk,
    input logic reset
);

int   cycle_count;

initial begin
    cycle_count = 0;
end

always @(posedge clk) begin
    cycle_count <= cycle_count + 1;
    if (cycle_count > 20) begin
        $finish();
    end
end

core core (
    .clk,
    .reset
);
endmodule

`endif // __TOP_SV 
