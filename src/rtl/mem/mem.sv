`ifndef __MEM_SV
`define __MEM_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"
`include "mem_common.pkg"
`include "mem_defs.pkg"

module mem
    import instr::*, instr_decode::*, common::*, rob_defs::*, mem_defs::*, mem_common::*;
(
    input  logic              clk,
    input  logic              reset,
    input  t_nuke_pkt         nuke_rb1,
    input  t_rob_id           oldest_robid,

    output t_mem_req_pkt      flq_mem_req_pkt,
    input  t_mem_rsp_pkt      flq_mem_rsp_pkt,

    input  logic              disp_valid_rs0,
    input  t_disp_pkt         disp_pkt_rs0,

    input  logic              iss_mm0,
    input  t_iss_pkt          iss_pkt_mm0,

    output t_rob_complete_pkt complete_mm5,

    output logic              iprf_wr_en_mm5,
    output t_prf_wr_pkt       iprf_wr_pkt_mm5
);

//
// Nets
//

logic ld_req_mm0; t_mempipe_arb ld_req_pkt_mm0; logic ld_gnt_mm0;
logic st_req_mm0; t_mempipe_arb st_req_pkt_mm0; logic st_gnt_mm0;
logic fl_req_mm0; t_mempipe_arb fl_req_pkt_mm0; logic fl_gnt_mm0;

t_mempipe_arb    pipe_pkt_mm1;

t_l1_set_addr    set_addr_mm1;

logic            tag_rd_en_mm1;
logic            tag_wr_en_mm1;
t_l1_tag         tag_wr_tag_mm1;
t_l1_way         tag_wr_way_mm1;
t_l1_tag         tag_rd_ways_mm2[L1_NUM_WAYS-1:0];

logic            state_rd_en_mm1;
logic            state_wr_en_mm1;
t_mesi           state_wr_state_mm1;
t_l1_way         state_wr_way_mm1;
t_mesi           state_rd_ways_mm2[L1_NUM_WAYS-1:0];

logic            data_rd_en_mm1;
logic            data_wr_en_mm1;
t_cl             data_wr_data_mm1;
t_l1_way         data_wr_way_mm1;
t_cl             data_rd_ways_mm2[L1_NUM_WAYS-1:0];

logic            flq_addr_mat_mm2;

logic            flq_alloc_mm5;
logic            pipe_valid_mm5;
t_mempipe_arb    pipe_req_pkt_mm5;
t_mempipe_action pipe_action_mm5;

//
// Logic
//

// Loads

loadq loadq (
    .clk,
    .reset,
    .nuke_rb1,

    .disp_valid_rs0,
    .disp_pkt_rs0,

    .iss_mm0,
    .iss_pkt_mm0,

    .pipe_req_mm0     ( ld_req_mm0     ) ,
    .pipe_req_pkt_mm0 ( ld_req_pkt_mm0 ) ,
    .pipe_gnt_mm0     ( ld_gnt_mm0     ) ,

    .pipe_valid_mm5,
    .pipe_req_pkt_mm5,
    .pipe_action_mm5
);

// Stores

storeq storeq (
    .clk,
    .reset,
    .nuke_rb1,
    .oldest_robid,

    .disp_valid_rs0,
    .disp_pkt_rs0,

    .iss_mm0,
    .iss_pkt_mm0,

    .pipe_req_mm0     ( st_req_mm0     ) ,
    .pipe_req_pkt_mm0 ( st_req_pkt_mm0 ) ,
    .pipe_gnt_mm0     ( st_gnt_mm0     ) ,

    .pipe_valid_mm5,
    .pipe_req_pkt_mm5,
    .pipe_action_mm5
);

// Fills

fillq fillq (
    .clk,
    .reset,

    .flq_alloc_mm5,

    .flq_mem_req_pkt,
    .flq_mem_rsp_pkt,

    .pipe_req_mm0     ( fl_req_mm0     ) ,
    .pipe_req_pkt_mm0 ( fl_req_pkt_mm0 ) ,
    .pipe_gnt_mm0     ( fl_gnt_mm0     ) ,

    .pipe_pkt_mm1,
    .flq_addr_mat_mm2,

    .pipe_valid_mm5,
    .pipe_req_pkt_mm5,
    .pipe_action_mm5
);

// Arrays 

l1tag l1tag (
    .clk,
    .reset,

    .tag_rd_en_mm1,
    .tag_wr_en_mm1,
    .set_addr_mm1,
    .tag_wr_tag_mm1,
    .tag_wr_way_mm1,

    .tag_rd_ways_mm2
);

l1state l1state (
    .clk,
    .reset,

    .state_rd_en_mm1,
    .state_wr_en_mm1,
    .set_addr_mm1,
    .state_wr_state_mm1,
    .state_wr_way_mm1,

    .state_rd_ways_mm2
);

l1data l1data (
    .clk,
    .reset,

    .data_rd_en_mm1,
    .data_wr_en_mm1,
    .set_addr_mm1,
    .data_wr_data_mm1,
    .data_wr_way_mm1,

    .data_rd_ways_mm2
);

// Pipeline 

mempipe mempipe (
    .clk,
    .reset,
    .nuke_rb1,

    .ld_req_mm0, .ld_req_pkt_mm0, .ld_gnt_mm0,
    .st_req_mm0, .st_req_pkt_mm0, .st_gnt_mm0,
    .fl_req_mm0, .fl_req_pkt_mm0, .fl_gnt_mm0,

    .req_pkt_mm1 ( pipe_pkt_mm1 ) ,
    .set_addr_mm1,

    .tag_rd_en_mm1,
    .tag_wr_en_mm1,
    .tag_wr_tag_mm1,
    .tag_wr_way_mm1,
    .tag_rd_ways_mm2,

    .state_rd_en_mm1,
    .state_wr_en_mm1,
    .state_wr_state_mm1,
    .state_wr_way_mm1,
    .state_rd_ways_mm2,

    .data_rd_en_mm1,
    .data_wr_en_mm1,
    .data_wr_data_mm1,
    .data_wr_way_mm1,
    .data_rd_ways_mm2,

    .flq_addr_mat_mm2,

    .valid_mm5    ( pipe_valid_mm5   ) ,
    .req_pkt_mm5  ( pipe_req_pkt_mm5 ) ,
    .action_mm5   ( pipe_action_mm5  ) ,
    .flq_alloc_mm5,

    .iprf_wr_en_mm5,
    .iprf_wr_pkt_mm5,
    .complete_mm5
);

//
// Debug
//

`ifdef SIMULATION
always @(posedge clk) begin
    if (iss_mm0) begin
        `INFO(("unit:MM %s", describe_uinstr(iss_pkt_mm0.uinstr)))
    end
end
`endif

    /*
`ifdef ASSERT
`VASSERT(a_illegal_format, uinstr_de1.valid, uinstr_de1.ifmt inside {RV_FMT_I,RV_FMT_R}, $sformatf("Unsupported instr fmt: %s", uinstr_de1.ifmt.name()))
`endif
    */

endmodule

`endif // __MEM_SV


