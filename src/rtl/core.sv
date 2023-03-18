`include "instr.pkg"

module core
    import core_instr::*;
(
    input  logic clk,
    input  logic reset
);

t_uinstr try_me;
int count;

initial begin
    try_me = '0;
    try_me.opcode = OP_ALU_R;
    count = '0;
end

always @(posedge clk) begin
    count += 1;
    $display("Hello %d", count);
end

endmodule
