`ifndef __CHICKEN_BIT_SV
`define __CHICKEN_BIT_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "gen_funcs.pkg"

module chicken_bit #(parameter string NAME="gizzard_dis", parameter int WIDTH=1) (
    output logic[WIDTH-1:0] o
);

initial begin
    o = '0;
    if ($value$plusargs($sformatf("+ckn:%s:%%d",NAME),o)) begin
        $display("+ckn:%s:%d seen",NAME,o);
    end
end

endmodule

`endif // __CHICKEN_BIT_SV
