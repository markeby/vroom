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
    output logic      fe_valid_de0,
    output t_rv_instr instr_de0,
    input  logic      stall
);

//
// Fake stuff
//

`ifdef SIMULATION

int instr_cnt_inst;
`DFF(instr_cnt_inst, reset ? '0 : instr_cnt_inst + 32'(valid_no_stall), clk)
`endif


//
// Nets
//

logic      valid_fe0;
t_rv_instr instr_fe0;
`MKFLAT(instr_fe0)

logic      valid_fe1;
t_rv_instr instr_fe1;

logic valid_no_stall;
always_comb valid_no_stall = valid_fe0 & ~stall;

//
// Logic
//

localparam IROM_SZ = 128;
t_rv_instr IROM [IROM_SZ-1:0];

initial begin
    automatic int a=0;
    for (int i=0; i<IROM_SZ; i++) begin
        IROM[i] = t_rv_instr'('0); //rvADDI(0,0,12'h000);
    end

    a=5;
    IROM[a++] = rvXOR(1,1,1);
    IROM[a++] = rvADDI(1,1,12'h123);
    IROM[a++] = rvSLLI(1,1,5'd12);
    IROM[a++] = rvADDI(1,1,12'h456);
    IROM[a++] = rvSLLI(1,1,5'd8);
    IROM[a++] = rvADDI(9,1,12'h78);
    IROM[a++] = rvADDI(1,1,1);
    IROM[a++] = rvADDI(1,1,1);
    IROM[a++] = rvADDI(1,1,1);
    IROM[a++] = rvADDI(1,1,1);
    IROM[a++] = rvADDI(1,1,1);
    IROM[a++] = rvXORI(2,1,1);
    IROM[a++] = rvXORI(3,1,1);
    IROM[a++] = rvXORI(4,1,1);
    IROM[a++] = rvXORI(5,1,1);
    IROM[a++] = rvXORI(6,1,1);
    IROM[a++] = rvXORI(7,1,1);
    IROM[a++] = rvADDI(1,1,12'h123);
    IROM[a++] = rvADDI(2,1,12'h123);
    IROM[a++] = rvADD(3,1,2);
    IROM[a++] = rvXOR(2,2,2);
    IROM[a++] = rvADDI(1,0,12'h111);
    IROM[a++] = rvADDI(17,0,12'h654);
    IROM[a++] = rvSUB(16,17,1);
    IROM[a++] = rvXORI(18,16,12'hfff);
    IROM[a++] = rvSRAI(20,18,5'h1);
    IROM[a++] = rvSRLI(21,18,5'h1);
    IROM[a++] = rvXOR(22,20,21);
end

logic[$clog2(IROM_SZ)-1:0] PC;
logic[$clog2(IROM_SZ)-1:0] PCNxt;

always_comb PCNxt = reset  ? '0     :
                    ~stall ? PC + 1 :
                             PC;
`DFF(PC, PCNxt, clk)

always_comb begin
    instr_fe0 = IROM[PC];
    valid_fe0 = |instr_fe0;

    `ifdef SIMULATION
    instr_fe0.SIMID.fid       = instr_cnt_inst;
    instr_fe0.SIMID.pc        = 32'(PC);
    `endif
end

`DFF_EN(valid_fe1, valid_fe0, clk, ~stall)
`DFF_EN(instr_fe1, instr_fe0, clk, ~stall)
always_comb fe_valid_de0 = valid_fe1;
always_comb instr_de0    = instr_fe1;

//
// Displays
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (valid_no_stall & ~reset) begin
        `INFO(("unit:FE pc:%h %s", PC, describe_instr(instr_fe0)))
    end
end
`endif

`ifdef ASSERT
chk_no_change #(.T(t_rv_instr)) cnc ( .clk, .reset, .hold(stall & fe_valid_de0), .thing(instr_de0) );
`endif


endmodule

`endif // __FETCH_SV

