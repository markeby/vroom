`include "instr.pkg"
`include "instr_decode.pkg"
`include "vroom_macros.sv"

module decode
    import instr::*, instr_decode::*;
(
    input  logic      clk,
    input  logic      reset,
    input  t_rv_instr instr_de0,
    output t_uinstr   uinstr_de1
);

//
// Nets
//

t_rv_instr_format ifmt_de0;
t_uinstr          uinstr_de0;

//
// Logic
//

assign ifmt_de0 = get_instr_format(instr_de0.opcode);

always_comb begin
    uinstr_de0 = '0;
    uinstr_de0.opcode = instr_de0.opcode;

    unique case (ifmt_de0)
        RV_FMT_R: begin
            uinstr_de0.dst.oreg  = instr_de0.d.R.rd;
            uinstr_de0.dst.otype = OP_REG;
            //dst   = {oreg: instr_de0.d.R.rd,  otype: OP_REG, default: 0};
            //src1  = {oreg: instr_de0.d.R.rs1, otype: OP_REG, default: 0};
            //src2  = {oreg: instr_de0.d.R.rs2, otype: OP_REG, default: 0};
        end
        RV_FMT_I: begin
            //dst.oreg   = {oreg: instr_de0.d.R.rd,  otype: OP_REG, default: 0};
            //src1.oreg  = {oreg: instr_de0.d.R.rs1, otype: OP_REG, default: 0};
            //src2.oreg  = {oreg: 'x,                otype: OP_IMM, default: 0};
        end
        default: begin
        end
    endcase

    if (reset) uinstr_de0 = '0;
end

`DFF(uinstr_de1, uinstr_de0, clk)

endmodule
