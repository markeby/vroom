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
    int           port;
    t_uinstr_disp disp_ra1;
} t_cd_alloc;

typedef struct packed {
    logic        valid;
    int          clk;
    t_uinstr_iss iss_pkt_rs2;
} t_cd_rs;

typedef struct packed {
    logic        valid;
    int          clk;
    t_prf_wr_pkt iprf_wr_pkt_ro0;
} t_cd_result;

typedef struct packed {
    logic       valid;
    int         clk;
} t_cd_retire;

typedef struct packed {
    t_simid       SIMID;
    t_cd_fetch    FETCH;
    t_cd_decode   DECODE;
    t_cd_rename   RENAME;
    t_cd_alloc    ALLOC;
    t_cd_rs       RS;
    t_cd_result   RESULT;
    t_cd_retire   RETIRE;
} t_cd_inst;

t_cd_inst  INSTQ[$];

task cd_show_retire(t_cd_inst rec);
    `PMSG(CDBG, ("---------------------[ %4d @%-4t ]---------------------", top.cclk_count, $time()));
    `PMSG(CDBG, (describe_uinstr(rec.DECODE.uinstr_de1)))
    `PMSG(CDBG, ("ROBID 0x%0h -- %s", rec.ALLOC.disp_ra1.robid, format_simid(rec.FETCH.instr_fe1.SIMID)))
    `PMSG(CDBG, ("  psrc1:0x%02h src1:0x%08h", rec.RENAME.rename_rn1.psrc1, rec.RS.iss_pkt_rs2.src1_val))
    `PMSG(CDBG, ("  psrc2:0x%02h src2:0x%08h", rec.RENAME.rename_rn1.psrc2, rec.RS.iss_pkt_rs2.src2_val))
    `PMSG(CDBG, ("   pdst:0x%02h  dst:0x%08h", rec.RENAME.rename_rn1.pdst,  rec.RESULT.iprf_wr_pkt_ro0.data))
    `PMSG(CDBG, ("Fetch  -> Decode @ %-d", rec.FETCH.clk))
    `PMSG(CDBG, ("Decode -> Rename @ %-d", rec.DECODE.clk))
    `PMSG(CDBG, ("Rename -> Alloc  @ %-d", rec.RENAME.clk))
    `PMSG(CDBG, ("Alloc  -> RS.%0d   @ %-d", rec.ALLOC.port, rec.ALLOC.clk))
    `PMSG(CDBG, ("          Result @ %-d", rec.RESULT.clk))
    `PMSG(CDBG, ("          Retire @ %-d", rec.RETIRE.clk))
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

function automatic int f_instq_find_match(t_simid THIS_SIMID);
    for (int i=0; i<INSTQ.size(); i++) begin
        if (INSTQ[i].SIMID == THIS_SIMID) begin
            return i;
        end
    end
    $error("Could not find simid!");
    return -1;
endfunction

task cd_decode();
    int i; i = f_instq_find_match(top.core.uinstr_de1.SIMID);
    if (INSTQ[i].DECODE.valid) begin
        $error("Trying to add a decode to a record that is already valid!");
    end
    INSTQ[i].DECODE.valid = 1'b1;
    INSTQ[i].DECODE.clk = top.cclk_count;
    INSTQ[i].DECODE.uinstr_de1 = top.core.uinstr_de1;
endtask

task cd_rename();
    int i; i = f_instq_find_match(top.core.uinstr_rn1.SIMID);
    if (INSTQ[i].RENAME.valid) begin
        $error("Trying to add a rename to a record that is already valid!");
    end
    INSTQ[i].RENAME.valid = 1'b1;
    INSTQ[i].RENAME.clk = top.cclk_count;
    INSTQ[i].RENAME.rename_rn1 = top.core.rename_rn1;
endtask

task cd_alloc(int port);
    int i; i = f_instq_find_match(top.core.alloc.disp_ports_rs0[port].uinstr.SIMID);
    if (INSTQ[i].ALLOC.valid) begin
        $error("Trying to add an alloc to a record that is already valid!");
    end
    INSTQ[i].ALLOC.valid = 1'b1;
    INSTQ[i].ALLOC.clk = top.cclk_count;
    INSTQ[i].ALLOC.port = port;
    INSTQ[i].ALLOC.disp_ra1 = top.core.alloc.disp_ports_rs0[port];
endtask

task cd_rs_eint();
    int i; i = f_instq_find_match(top.core.eint_iss_pkt_rs2.uinstr.SIMID);

    if (INSTQ[i].RS.valid) begin
        $error("Trying to add an rs to a record that is already valid!");
    end
    INSTQ[i].RS.valid = 1'b1;
    INSTQ[i].RS.clk = top.cclk_count;
    INSTQ[i].RS.iss_pkt_rs2 = top.core.eint_iss_pkt_rs2;
endtask

task cd_result_eint();
    int i; i = f_instq_find_match(top.core.iprf_wr_pkt_ex1.SIMID);

    if (INSTQ[i].RESULT.valid) begin
        $error("Trying to add a result to a record that is already valid!");
    end
    INSTQ[i].RESULT.valid = 1'b1;
    INSTQ[i].RESULT.clk = top.cclk_count;
    INSTQ[i].RESULT.iprf_wr_pkt_ro0 = top.core.iprf_wr_pkt_ex1;
endtask

task cd_retire();
    int i; i = f_instq_find_match(top.core.retire.rob.head_entry.s.uinstr.SIMID);
    if (INSTQ[i].RETIRE.valid) begin
        $error("Trying to retire a record that is already retired!");
    end
    INSTQ[i].RETIRE.valid = 1'b1;
    INSTQ[i].RETIRE.clk = top.cclk_count;
    cd_show_retire(INSTQ[i]);
endtask

always_ff @(posedge clk) begin
    if (core.valid_fe1) cd_fetch();
    if (core.valid_de1) cd_decode();
    if (core.valid_rn1) cd_rename();

    for (int p=0; p<NUM_DISP_PORTS; p++) begin
        if (core.alloc.disp_valid_ports_rs0[p]) cd_alloc(p);
    end

    if (core.eint_iss_rs2  ) cd_rs_eint();
    if (core.iprf_wr_en_ex1) cd_result_eint();

    if (core.retire.rob.q_retire_rb1) cd_retire();
end

endmodule
/* verilator lint_on BLKSEQ */

`endif

`endif // __COREDEBUG_SV
