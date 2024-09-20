`ifndef __UCODE_SV
`define __UCODE_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "gen_funcs.pkg"
`include "common.pkg"
`include "verif.pkg"

module ucode
    import instr::*, gen_funcs::*, common::*, verif::*;
(
    input  logic             clk,
    input  logic             reset,
    input  t_nuke_pkt        nuke_rb1,
    output logic             ucode_ready_de0,
    input  logic             rename_ready_rn0,

    input  logic             valid_de1,
    input  t_uinstr          uinstr_de1,
    output logic             ucode_ready_uc0,

    output logic             valid_uc0,
    output t_uinstr          uinstr_uc0
);

//
// Types
//

typedef enum logic {
    UC_IDLE,
    UC_FETCH
} t_uc_fsm;
t_uc_fsm fsm, fsm_nxt;

//
// Nets
//

t_rom_addr useq_pc;
t_rom_addr useq_pc_nxt;

t_uinstr ROM [UCODE_ROM_ROWS-1:0];

//
// FSM
//

always_comb begin
    fsm_nxt = fsm;
    if (reset) begin
        fsm_nxt = UC_IDLE;
    end else begin
        unique casez(fsm)
            UC_IDLE:  if (valid_de1 & rename_ready_rn0 & uinstr_de1.trap_to_ucode) fsm_nxt = UC_FETCH;
            UC_FETCH: if (valid_uc0 & rename_ready_rn0 & uinstr_de1.eom          ) fsm_nxt = UC_IDLE;
        end
    end
end
`DFF(fsm, fsm_nxt, clk)

//
// Logic
//

always_comb begin
    useq_pc_nxt = useq_pc;
    if (fsm == UC_IDLE) begin
        useq_pc_nxt = uinstr_de1.rom_addr;
    end else begin
        useq_pc_nxt += valid_uc0 & rename_ready_rn0;
    end
end
`DFF(useq_pc, useq_pc_nxt, clk)

//
// DE0
//

`ifdef ASSERT
`endif

//
// Debug
//

`ifdef SIMULATION
// always @(posedge clk) begin
//     if (valid_dex[DE0]) begin
//         `UINFO(uinstr_de0.SIMID, ("unit:DE func:uopq_push %s", describe_uinstr(uinstr_de0)))
//     end
//     if (uopq_valid_de1 & ~valid_de1) begin
//         `UINFO(uinstr_fe_de1.SIMID, ("unit:DE func:uopq_stalled %s", describe_uinstr(uinstr_de1)))
//     end
//     if (valid_de1) begin
//         `UINFO(uinstr_de1.SIMID, ("unit:DE func:uopq_pop %s", describe_uinstr(uinstr_de1)))
//     end
// end
`endif

`ifdef ASSERT
//chk_no_change #(.T(t_uinstr)) cnc ( .clk, .reset, .hold(stall & uinstr_de1.valid & ~br_mispred_rb1), .thing(uinstr_de1) );
`endif

endmodule

`endif // __UCODE_SV

