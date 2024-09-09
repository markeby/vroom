`ifndef __FE_BUF_SV
`define __FE_BUF_SV

`include "instr.pkg"
`include "verif.pkg"
`include "asm.pkg"
`include "mem_common.pkg"
`include "vroom_macros.sv"
`include "gen_funcs.pkg"

module fe_buf
    import instr::*, common::*, mem_common::*, verif::*, gen_funcs::*;
(
    input  logic       clk,
    input  logic       reset,

    // FE
    input  t_fe_fb_req fe_fb_req_fb0,
    output t_fb_fe_rsp fb_fe_rsp_nnn,

    // IC
    output t_mem_req_pkt   fb_ic_req_nnn,
    input  t_mem_rsp_pkt   ic_fb_rsp_nnn
);

localparam NUM_SETS = FE_FB_NUM_SETS;
localparam NUM_ENTS = FE_FB_NUM_ENTS;

//
// FE_BUF-specific types
//

typedef logic[FE_FB_SET_BITS-1:0] t_setid;
function t_setid get_setid(t_paddr pa);
    get_setid = pa[FE_FB_SET_MSB:FE_FB_SET_LSB];
endfunction

typedef struct packed {
    logic   valid;
    t_cl    data;
    t_paddr cl_addr;
} t_buf_cl;

//
// Nets
//

t_buf_cl            FBUF [NUM_SETS-1:0];
logic               fe_req_hit_fb0;
logic               fe_req_mis_fb0;
logic[NUM_SETS-1:0] fe_req_hitway_dec_fb0;

logic               c_push_fb0;
t_fe_fb_static      c_push_static_fb0;

logic[FE_FB_NUM_ENTS-1:0]     e_push_fb0;
logic[FE_FB_NUM_ENTS-1:0]     e_valid_nnn;
t_fe_fb_static                e_static_nnn        [FE_FB_NUM_ENTS-1:0];
t_fe_fb_active                e_active_nnn        [FE_FB_NUM_ENTS-1:0];

logic[FE_FB_NUM_ENTS-1:0]     e_ic_req_rq_nnn;
logic[FE_FB_NUM_ENTS-1:0]     e_ic_req_gn_nnn;
t_mem_req_pkt                     e_ic_req_pkt_nnn    [FE_FB_NUM_ENTS-1:0];
t_mem_rsp_pkt                     e_ic_rsp_pkt_nnn    [FE_FB_NUM_ENTS-1:0];
logic[FE_FB_NUM_ENTS_LG2-1:0] c_ic_req_sl_nnn;

logic[FE_FB_NUM_ENTS-1:0]     e_fe_rsp_rq_nnn;
t_fb_fe_rsp                   e_fe_rsp_pkt_nnn    [FE_FB_NUM_ENTS-1:0];
logic[FE_FB_NUM_ENTS-1:0]     e_fe_rsp_gn_nnn;
logic[FE_FB_NUM_ENTS_LG2-1:0] c_fe_rsp_sl_nnn;

t_fe_fb_req                   pf_fb_req_pkt_pf0;
logic                         pf_fb_req_rq_pf0;
logic                         pf_fb_req_gn_pf0;

//
// Logic
//

//
// FBUF management
//

// Mux out selected entry

t_buf_cl ent_sel_fb0;
always_comb ent_sel_fb0 = FBUF[get_setid(fe_fb_req_fb0.addr)];

// Calculate hit and miss

always_comb fe_req_hit_fb0 = fe_fb_req_fb0.valid & ent_sel_fb0.valid & cl_match(fe_fb_req_fb0.addr, ent_sel_fb0.cl_addr);
always_comb fe_req_mis_fb0 = fe_fb_req_fb0.valid & ~fe_req_hit_fb0;

// Update FBUF on IC rsp

always_ff @(posedge clk) begin
    t_fe_fb_static rsp_ent = e_static_nnn[ic_fb_rsp_nnn.id[FE_FB_NUM_ENTS_LG2-1:0]];
    automatic t_setid setid_fb1 = get_setid(rsp_ent.req.addr);
    if (ic_fb_rsp_nnn.valid & ~rsp_ent.pf) begin
        FBUF[setid_fb1].data    <= ic_fb_rsp_nnn.data.flat;
        FBUF[setid_fb1].valid   <= 1'b1;
        FBUF[setid_fb1].cl_addr <= get_cl_addr(rsp_ent.req.addr);
    end
end

//
// Entries
//

logic pf_fb_req_rq_ql_pf0;
always_comb begin
    pf_fb_req_rq_ql_pf0 = pf_fb_req_rq_pf0;
    for (int i=0; i<FE_FB_NUM_ENTS; i++) begin
        pf_fb_req_rq_ql_pf0 &= ~(e_valid_nnn[i] & cl_match(e_static_nnn[i].req.addr, pf_fb_req_pkt_pf0.addr));
    end
end

always_comb c_push_fb0 = fe_req_mis_fb0
                       | pf_fb_req_rq_ql_pf0;
always_comb e_push_fb0 = c_push_fb0 ? gen_funcs#(FE_FB_NUM_ENTS)::find_first0(e_valid_nnn) : '0;
always_comb begin
    c_push_static_fb0 = '0;
    c_push_static_fb0.req = fe_req_mis_fb0 ? fe_fb_req_fb0 : pf_fb_req_pkt_pf0;
    c_push_static_fb0.pf  = fe_req_mis_fb0 ? 1'b0          : 1'b1;
end
always_comb pf_fb_req_gn_pf0 = pf_fb_req_rq_pf0 & ~fe_req_mis_fb0;

for (genvar i=0; i<FE_FB_NUM_ENTS; i++) begin : g_fbent
    fe_fb_entry fe_fb_entry (
        .clk,
        .reset,
        .e_push_fb0       ( e_push_fb0[i]       ) ,
        .c_push_static_fb0,
        .e_valid_nnn      ( e_valid_nnn[i]      ) ,
        .e_static_nnn     ( e_static_nnn[i]     ) ,
        .e_active_nnn     ( e_active_nnn[i]     ) ,
        .e_ic_req_rq_nnn  ( e_ic_req_rq_nnn[i]  ) ,
        .e_ic_req_pkt_nnn ( e_ic_req_pkt_nnn[i] ) ,
        .e_ic_req_gn_nnn  ( e_ic_req_gn_nnn[i]  ) ,
        .e_ic_rsp_pkt_nnn ( e_ic_rsp_pkt_nnn[i] ) ,
        .e_fe_rsp_rq_nnn  ( e_fe_rsp_rq_nnn[i]  ) ,
        .e_fe_rsp_pkt_nnn ( e_fe_rsp_pkt_nnn[i] ) ,
        .e_fe_rsp_gn_nnn  ( e_fe_rsp_gn_nnn[i]  )
    );
end

//
// FB -> FE interface
//

// FE rsp

always_comb e_fe_rsp_gn_nnn = gen_funcs#(FE_FB_NUM_ENTS)::find_first1(e_fe_rsp_rq_nnn);
always_comb c_fe_rsp_sl_nnn = gen_lg2_funcs#(FE_FB_NUM_ENTS)::oh_encode(e_fe_rsp_gn_nnn);

t_fb_fe_rsp fb_fe_rsp_nxt_nnn;
always_comb begin
    fb_fe_rsp_nxt_nnn = '0;
    if (fe_req_hit_fb0) begin
        fb_fe_rsp_nxt_nnn.valid = 1'b1;
        fb_fe_rsp_nxt_nnn.instr = instr_from_cl(ent_sel_fb0.data, get_cl_offset(fe_fb_req_fb0.addr));
        fb_fe_rsp_nxt_nnn.id    = fe_fb_req_fb0.id;
        fb_fe_rsp_nxt_nnn.pc    = fe_fb_req_fb0.addr;
    end else begin
        for (int i=0; i<FE_FB_NUM_ENTS; i++) begin
            fb_fe_rsp_nxt_nnn    |= e_fe_rsp_gn_nnn[i] ? e_fe_rsp_pkt_nnn[i] : '0;
            fb_fe_rsp_nxt_nnn.id |= e_fe_rsp_gn_nnn[i] ? t_mem_id'(i)        : '0;
        end
    end
end
`DFF(fb_fe_rsp_nnn, fb_fe_rsp_nxt_nnn, clk)

`ifdef SIMULATION
logic[RV_INSTR_WIDTH-1:0] f__fb_fe_rsp_nnn_data;
assign f__fb_fe_rsp_nnn_data = fb_fe_rsp_nnn.instr;
`endif

//
// FB <-> IC interface
//

// IC req

always_comb e_ic_req_gn_nnn = gen_funcs#(FE_FB_NUM_ENTS)::find_first1(e_ic_req_rq_nnn);
always_comb c_ic_req_sl_nnn = gen_lg2_funcs#(FE_FB_NUM_ENTS)::oh_encode(e_ic_req_gn_nnn);

always_comb begin
    fb_ic_req_nnn = '0;
    fb_ic_req_nnn.valid = |e_ic_req_rq_nnn;
    fb_ic_req_nnn.addr  = e_static_nnn[c_ic_req_sl_nnn].req.addr;
    fb_ic_req_nnn.id    = t_mem_id'(c_ic_req_sl_nnn);
end

// IC rsp

always_comb begin
    for (int i=0; i<FE_FB_NUM_ENTS; i++) begin
        e_ic_rsp_pkt_nnn[i]        = ic_fb_rsp_nnn;
        e_ic_rsp_pkt_nnn[i].valid &= ic_fb_rsp_nnn.id == t_mem_id'(i);
    end
end

//
// Prefetcher
//

fe_pf fe_pf (
    .clk,
    .reset,
    .fe_fb_req_fb0,
    .pf_fb_req_rq_pf0,
    .pf_fb_req_pkt_pf0,
    .pf_fb_req_gn_pf0
);

//
// Displays
//

/*
`ifdef SIMULATION
always @(posedge clk) begin
    if (valid_fe1 & ~stall & ~reset) begin
        `INFO(("unit:FE pc:%h %s", PC, describe_instr(instr_fe1)))
    end
end
`endif
*/

`ifdef SIMULATION
always @(posedge clk) begin
    if (~reset & fe_fb_req_fb0.valid) begin
        `GENLOG(FE, ("type:fe_fb_req id:%d addr:%h", fe_fb_req_fb0.id, fe_fb_req_fb0.addr))
    end
    if (~reset & pf_fb_req_rq_pf0) begin
        `GENLOG(FE, ("type:pf_fb_req addr:%h", pf_fb_req_pkt_pf0.addr))
    end
    if (~reset & fb_fe_rsp_nnn.valid) begin
        `GENLOG(FE, ("type:fb_fe_rsp id:%d data:%0h", fb_fe_rsp_nnn.id, fb_fe_rsp_nnn.instr))
    end
end
`endif


`ifdef ASSERT
    /*
logic valid_fe2_inst;

`DFF(instr_pkt_fe2,  instr_pkt_fe1, clk)
`DFF(valid_fe2_inst, valid_fe1,     clk)

`VASSERT(a_lost_instr, valid_fe1 & valid_fe2_inst & instr_pkt_fe1.SIMID != instr_pkt_fe2.SIMID, core.decode.uinstr_de1.SIMID == instr_pkt_fe2.SIMID, $sformatf("Lost an instruction with simid:%s", format_simid(instr_pkt_fe2.SIMID)))
*/

//chk_no_change #(.T(t_instr_pkt)) cnc ( .clk, .reset, .hold(stall & valid_fe1), .thing(instr_pkt_fe1) );
`endif


endmodule

`endif // __FE_BUF_SV

