`ifndef __DECODE_SV
`define __DECODE_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "vroom_macros.sv"

module decode
    import instr::*, instr_decode::*;
(
    input  logic      clk,
    input  logic      reset,
    input  logic      valid_de0,
    input  t_rv_instr instr_de0,
    output t_uinstr   uinstr_de1
);

//
// Nets
//

t_rv_instr_format ifmt_de0;
t_uinstr          uinstr_de0;

`ifdef SIMULATION
int instr_cnt_inst;
`DFF(instr_cnt_inst, reset ? '0 : instr_cnt_inst + 32'(valid_de0), clk)
`endif

//
// Logic
//

assign ifmt_de0 = get_instr_format(instr_de0.opcode);

always_comb begin
    uinstr_de0 = '0;
    uinstr_de0.opcode = instr_de0.opcode;
    uinstr_de0.valid  = valid_de0;

    unique case (ifmt_de0)
        RV_FMT_R: begin
        end
        RV_FMT_I: begin
            uinstr_de0.dst  = '{opreg: instr_de0.d.R.rd,  optype: OP_REG, opsize: SZ_INV};
            uinstr_de0.src1 = '{opreg: instr_de0.d.R.rs1, optype: OP_REG, opsize: SZ_INV};
            uinstr_de0.src2 = '{opreg: instr_de0.d.R.rs2, optype: OP_REG, opsize: SZ_INV};
        end
        RV_FMT_S: begin
        end
        RV_FMT_J: begin
        end
        RV_FMT_B: begin
        end
        RV_FMT_U: begin
        end
        default: begin
        end
    endcase

    `ifdef SIMULATION
    instr_fe0.SIMID.did = instr_cnt_inst;
    `endif

    if (reset) uinstr_de0 = '0;
end

`DFF(uinstr_de1, uinstr_de0, clk)

endmodule

`endif // __DECODE_SV

