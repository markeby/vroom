`ifndef __FETCH_SV
`define __FETCH_SV

`include "instr.pkg"
`include "asm.pkg"
`include "vroom_macros.sv"

module fetch
    import instr::*, asm::*;
(
    input  logic      clk,
    input  logic      reset,
    output logic      valid_de0,
    output t_rv_instr instr_de0,
    input  logic      stall_de1
);

//
// Fake stuff
//

int count;

initial begin
    count = '0;
end

`DFF(count, count+1, clk)

//
// Nets
//

logic      valid_fe0;
t_rv_instr instr_fe0;
`MKFLAT(instr_fe0)

logic      valid_fe1;
t_rv_instr instr_fe1;

//
// Logic
//

always_comb begin
    instr_fe0 = '0;
    valid_fe0 = 1'b0;
    if (count == 5) begin
        valid_fe0 = 1'b1;
        instr_fe0 = rvADDI(3, 4, 12'h123);
    end
    if (count == 7) begin
        valid_fe0 = 1'b1;
        instr_fe0 = rvADDI(1, 2, 12'h999);
    end
end

`DFF(valid_fe1, valid_fe0, clk)
`DFF(instr_fe1, instr_fe0, clk)
always_comb valid_de0 = valid_fe1;
always_comb instr_de0 = instr_fe1;

endmodule

`endif // __FETCH_SV

