`ifndef __CHK_INSTR_PROGRESS_SV
`define __CHK_INSTR_PROGRESS_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "verif.pkg"

module chk_instr_progress
    import verif::*;
    #(parameter string A="A", string B="B")
(
    input  logic     clk,
    input  logic     reset,
    input  logic     br_mispred_rb1,
    input  logic     valid_stgA_nn0,
    input  t_simid   simid_stgA_nn0,
    input  logic     valid_stgB_nn0,
    input  t_simid   simid_stgB_nn0
);

logic   valid_stgA_nn1;
t_simid simid_stgA_nn1;

`DFF(valid_stgA_nn1, valid_stgA_nn0, clk)
`DFF(simid_stgA_nn1, simid_stgA_nn0, clk)

// if instr left stage A, it must be in stage B
`VASSERT(a_lost_instr, valid_stgA_nn1 & (~valid_stgA_nn0 | simid_stgA_nn0.txid.fid != simid_stgA_nn1.txid.fid), br_mispred_rb1 | valid_stgB_nn0 & simid_stgA_nn1.txid.fid == simid_stgB_nn0.txid.fid, $sformatf("Instr left stg %s but is not in stg %s (simid:%s)", A, B, format_simid(simid_stgA_nn1)))
// if instr remains in stage A, it must not be in stage B
`VASSERT(a_grew_instr, valid_stgA_nn1 & valid_stgB_nn0, simid_stgA_nn0.txid.fid != simid_stgB_nn0.txid.fid, $sformatf("Instr still in stg %s propagated to stg %s (simid: %s)", A, B, format_simid(simid_stgA_nn1)))

endmodule

`endif // __CHK_INSTR_PROGRESS_SV

