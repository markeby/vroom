`ifndef __EX_SV
`define __EX_SV

`include "instr.pkg"
`include "vroom_macros.sv"

module exe
    import instr::*, instr_decode::*;
(
    input  logic         clk,
    input  logic         reset,
    input  logic         stall,

    input  t_uinstr      uinstr_ex0,
    input  t_rv_reg_data rddatas_ex0 [1:0],

    output t_uinstr      uinstr_mm0,
    output t_rv_reg_data result_mm0
);

localparam EX0 = 0;
localparam EX1 = 1;
localparam NUM_EX_STAGES = 1;

//
// Nets
//

t_uinstr      uinstr_ex1;

t_rv_reg_data src1val_ex0;
t_rv_reg_data src2val_ex0;

t_uinstr uinstr_ql_ex0;

`MKPIPE_INIT(t_uinstr,       uinstr_exx, uinstr_ql_ex0, EX0, NUM_EX_STAGES)
`MKPIPE     (t_rv_reg_data,  result_exx,                EX0, NUM_EX_STAGES)

//
// Logic
//

always_comb begin
    uinstr_ql_ex0 = uinstr_ex0;
    `ifdef SIMULATION
    uinstr_ql_ex0.SIMID.src1_val   = src1val_ex0;
    uinstr_ql_ex0.SIMID.src2_val   = src2val_ex0;
    uinstr_ql_ex0.SIMID.result_val = result_exx[EX0];
    `endif
end

//
// EX0
//

always_comb src1val_ex0 = rddatas_ex0[0];
always_comb src2val_ex0 = (uinstr_ex0.src2.optype == OP_REG ? rddatas_ex0[1]   : '0)
                        | (uinstr_ex0.src2.optype == OP_IMM ? uinstr_ex0.imm32 : '0);

always_comb begin
    result_exx[EX0] = '0;
    unique case (uinstr_ex0.uop)
        U_ADD:     result_exx[EX0] = src1val_ex0 + src2val_ex0;
        U_SUB:     result_exx[EX0] = src1val_ex0 - src2val_ex0;
        U_AND:     result_exx[EX0] = src1val_ex0 & src2val_ex0;
        U_XOR:     result_exx[EX0] = src1val_ex0 ^ src2val_ex0;
        U_OR:      result_exx[EX0] = src1val_ex0 | src2val_ex0;
        U_SLL:     result_exx[EX0] = src1val_ex0 << src2val_ex0[4:0];
        U_SRL:     result_exx[EX0] = src1val_ex0 >> src2val_ex0[4:0];
        U_SRA:     result_exx[EX0] = int'(src1val_ex0) >>> src2val_ex0[4:0]; 
        //U_SLL,
        //U_SRL,
        //U_SRA,
        //U_SLT,
        //U_SLTU,
        default:  result_exx[EX0] = 32'hDEADBEEF;
    endcase
end

//
// EX1/MM0
//

// MM0 assign

always_comb uinstr_mm0 = uinstr_exx[EX1];
always_comb result_mm0 = result_exx[EX1];

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (uinstr_ex0.valid) begin
        `INFO(("unit:EX %s result:%08h", describe_uinstr(uinstr_ex0), result_exx[EX0]))
    end
end
`endif

/*
`ifdef ASSERT
`VASSERT(a_illegal_format, uinstr_de1.valid, uinstr_de1.ifmt inside {RV_FMT_I,RV_FMT_R}, $sformatf("Unsupported instr fmt: %s", uinstr_de1.ifmt.name()))
`endif
    */

endmodule

`endif // __EX_SV

