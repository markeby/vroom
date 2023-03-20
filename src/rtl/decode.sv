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

// `SIMID_STRUCT
// logic[31:0]       imm32;
// logic[6:0]        funct7;
// logic[2:0]        funct3;
// t_uopnd           src2;
// t_uopnd           src1;
// t_uopnd           dst;
// t_rv_opcode       opcode;
// t_rv_instr_format ifmt;
// logic             valid;
always_comb begin
    uinstr_de0 = '0;
    uinstr_de0.opcode = instr_de0.opcode;
    uinstr_de0.valid  = valid_de0;
    uinstr_de0.ifmt   = ifmt_de0;

    unique case (ifmt_de0)
        RV_FMT_R: begin
            uinstr_de0.funct7 = instr_de0.d.R.funct7;
            uinstr_de0.funct3 = instr_de0.d.R.funct3;
            uinstr_de0.dst    = '{opreg: instr_de0.d.R.rd,  optype: OP_REG, opsize: SZ_4B};
            uinstr_de0.src1   = '{opreg: instr_de0.d.R.rs1, optype: OP_REG, opsize: SZ_4B};
            uinstr_de0.src2   = '{opreg: instr_de0.d.R.rs2, optype: OP_REG, opsize: SZ_4B};
            uinstr_de0.imm32  = '0;
        end
        RV_FMT_I: begin
            uinstr_de0.funct7 = '0;
            uinstr_de0.funct3 = instr_de0.d.I.funct3;
            uinstr_de0.dst    = '{opreg: instr_de0.d.I.rd,  optype: OP_REG, opsize: SZ_4B};
            uinstr_de0.src1   = '{opreg: instr_de0.d.I.rs1, optype: OP_REG, opsize: SZ_4B};
            uinstr_de0.src2   = '{opreg: '0,                optype: OP_IMM, opsize: SZ_4B};
            uinstr_de0.imm32  = { {(32-12){instr_de0.d.I.imm_11_0[11]}}, instr_de0.d.I.imm_11_0[11:0] };
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
    uinstr_de0.SIMID     = instr_de0.SIMID;
    //uinstr_de0.SIMID.did = instr_cnt_inst;
    `endif

    if (reset) uinstr_de0 = '0;
end

`DFF(uinstr_de1, uinstr_de0, clk)

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (uinstr_de0.valid) begin
        `INFO(("unit:DE %s", describe_uinstr(uinstr_de0)))
    end
end
`endif

`ifdef ASSERT
`VASSERT(a_illegal_format, uinstr_de1.valid, uinstr_de1.ifmt inside {RV_FMT_I,RV_FMT_R}, $sformatf("Unsupported instr fmt: %s", uinstr_de1.ifmt.name()))
`endif

endmodule

`endif // __DECODE_SV

