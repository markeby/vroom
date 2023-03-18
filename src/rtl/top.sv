module top ();

logic clk;
logic reset;
int   cycle_count;

initial begin
    clk = 1'b0;
    cycle_count = 0;
    reset = 1'b1;
end

always #500 clk <= ~clk;

always @(posedge clk) begin
    cycle_count += 1;
    if (cycle_count > 5) begin
        reset = 1'b0;
    end
    if (cycle_count > 20) begin
        $finish();
    end
end

core core (
    .clk,
    .reset
);
endmodule
