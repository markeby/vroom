`ifndef __COREDEBUG_SV
`define __COREDEBUG_SV

`include "instr.pkg"
`include "instr_decode.pkg"
`include "mem_common.pkg"
`include "common.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"
`include "verif.pkg"

`ifdef SIMULATION

/* verilator lint_off BLKSEQ */
module coredebug
    import instr::*, instr_decode::*, mem_common::*, common::*, rob_defs::*, verif::*;
(
    input  logic clk,
    input  logic reset
);

typedef struct packed {
    logic       valid;
    int         clk;
    t_instr_pkt instr_fe1;
} t_cd_fetch;

typedef struct packed {
    logic       valid;
    int         clk;
    t_uinstr    uinstr_de1;
} t_cd_decode;

typedef struct packed {
    logic        valid;
    int          clk;
    t_rename_pkt rename_rn1;
} t_cd_rename;

typedef struct packed {
    logic         valid;
    int           clk;
    t_uinstr_disp disp_ra1;
} t_cd_alloc;

typedef struct packed {
    logic        valid;
    int          clk;
    t_uinstr_iss iss_pkt_rs2;
} t_cd_rs;

typedef struct packed {
    logic       valid;
    int         clk;
} t_cd_retire;

typedef struct packed {
    t_simid       SIMID;
    t_cd_fetch    FETCH;
    t_cd_decode   DECODE;
    t_cd_rename   RENAME;
    t_cd_retire   RETIRE;
} t_cd_inst;

t_cd_inst  INSTQ[$];

task cd_show_retire(t_cd_inst rec);
    `PMSG(CDBG, ("---------------------[ %d ]---------------------", top.cclk_count));
    `PMSG(CDBG, ("SIMID %s", format_simid(rec.FETCH.instr_fe1.SIMID)))
    `PMSG(CDBG, (describe_uinstr(rec.DECODE.uinstr_de1)))
    `PMSG(CDBG, ("PDST:0x%0h PSRC1:0x%0h PSRC2:0x%0h", rec.RENAME.rename_rn1.pdst, rec.RENAME.rename_rn1.psrc1, rec.RENAME.rename_rn1.psrc2))
    `PMSG(CDBG, ("FE1 Fetch  @ %-d", rec.FETCH.clk))
    `PMSG(CDBG, ("DE1 Decode @ %-d", rec.DECODE.clk))
    `PMSG(CDBG, ("RN1 Rename @ %-d", rec.RENAME.clk))
    `PMSG(CDBG, ("RB1 Retire @ %-d", rec.RETIRE.clk))
endtask

task cd_fetch();
    t_cd_inst new_inst;
    new_inst = '0;

    new_inst.SIMID = top.core.instr_fe1.SIMID;

    new_inst.FETCH.valid     = 1'b1;
    new_inst.FETCH.clk       = top.cclk_count;
    new_inst.FETCH.instr_fe1 = top.core.instr_fe1;

    INSTQ.push_back(new_inst);
endtask

task cd_decode();
    t_simid THIS_SIMID;

    THIS_SIMID = top.core.uinstr_de1.SIMID;
    for (int i=0; i<INSTQ.size(); i++) begin
        if (INSTQ[i].SIMID == THIS_SIMID) begin
            if (INSTQ[i].DECODE.valid) begin
                $error("Trying to add a decode to a record that is already valid!");
            end
            INSTQ[i].DECODE.valid = 1'b1;
            INSTQ[i].DECODE.clk = top.cclk_count;
            INSTQ[i].DECODE.uinstr_de1 = top.core.uinstr_de1;
        end
    end
endtask

task cd_rename();
    t_simid THIS_SIMID;

    THIS_SIMID = top.core.uinstr_rn1.SIMID;
    for (int i=0; i<INSTQ.size(); i++) begin
        if (INSTQ[i].SIMID == THIS_SIMID) begin
            if (INSTQ[i].RENAME.valid) begin
                $error("Trying to add a rename to a record that is already valid!");
            end
            INSTQ[i].RENAME.valid = 1'b1;
            INSTQ[i].RENAME.clk = top.cclk_count;
            INSTQ[i].RENAME.rename_rn1 = top.core.rename_rn1;
        end
    end
endtask

task cd_retire();
    t_simid THIS_SIMID;

    THIS_SIMID = top.core.retire.rob.head_entry.s.uinstr.SIMID;
    for (int i=0; i<INSTQ.size(); i++) begin
        if (INSTQ[i].SIMID == THIS_SIMID) begin
            if (INSTQ[i].RETIRE.valid) begin
                $error("Trying to retire a record that is already retired!");
            end
            INSTQ[i].RETIRE.valid = 1'b1;
            INSTQ[i].RETIRE.clk = top.cclk_count;
            cd_show_retire(INSTQ[i]);
        end
    end
endtask

always_ff @(posedge clk) begin
    if (core.valid_fe1) cd_fetch();
    if (core.valid_de1) cd_decode();
    if (core.valid_rn1) cd_rename();

    if (core.retire.rob.q_retire_rb1) cd_retire();
end

endmodule
/* verilator lint_on BLKSEQ */

`endif

`endif // __COREDEBUG_SV
