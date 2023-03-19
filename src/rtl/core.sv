`ifndef __CORE_SV
`define __CORE_SV

`include "instr.pkg"
`include "vroom_macros.sv"

module core
    import instr::*;
(
    input  logic clk,
    input  logic reset
);

t_rv_instr instr_de0;
int count;

initial begin
    instr_de0 = '0;
    instr_de0.opcode = OP_ALU_R;
    count = '0;
end

`DFF(count, count+1, clk)
always @(posedge clk) begin
    $display("Hello %d", count);
end

logic valid_de0;
assign valid_de0 = count == 4;

decode decode (
    .clk,
    .reset,
    .valid_de0,
    .instr_de0,
    .uinstr_de1 ( )
);

endmodule

`endif // __CORE_SV
