`ifndef __ROB_SV
`define __ROB_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "rob.pkg"
`include "common.pkg"

module rob
    import instr::*, instr_decode::*, verif::*, common::*, rob::*;
(
    input  logic             clk,
    input  logic             reset,

    input  t_uinstr          uinstr_de1,

    input  t_uinstr          uinstr_mm1,
    input  t_rv_reg_data     result_mm1,

    output t_uinstr          uinstr_rb1,
    output logic             wren_rb1,
    output t_rv_reg_addr     wraddr_rb1,
    output t_rv_reg_data     wrdata_rb1,

    output logic             br_mispred_rb1,
    output t_paddr           br_tgt_rb1
);

    // typedef struct packed {
    //     `SIMID_STRUCT
    //     logic[63:0]       imm64;
    //     logic[6:0]        funct7;
    //     logic             mispred;
    //     t_rv_funct3       funct3;
    //     t_uopnd_descr     src2;
    //     t_uopnd_descr     src1;
    //     t_uopnd_descr     dst;
    //     t_rv_opcode       opcode;
    //     t_rv_instr_format ifmt;
    //     t_uop             uop;
    //     t_paddr           pc;
    //     logic             valid;
    // } t_uinstr;

    typedef struct packed {
       t_uinstr uinstr;
    } t_rob_ent_static;

    typedef struct packed {
       logic valid;
       logic ready;
    } t_rob_ent_dynamic;

    typedef struct packed {
       t_rob_ent_static  s;
       t_rob_ent_dynamic d;
    } t_rob_ent;

//
// Nets
//

   t_rob_ent ROB [RB_NUM_ENTS-1:0];
   t_rob_id head_id;
   t_rob_id tail_id;
   logic    retire_valid_rb1;

//
// Logic
//

   // ROB pointers

   if(1) begin : g_rob_head_ptr
      t_rob_id head_id_nxt;
      assign head_id_nxt = reset     ? '0                    :
                           alloc_de1 ? f_incr_robid(head_id) :
                                       head_id;
   end : g_rob_head_ptr

   if(1) begin : g_rob_tail_ptr
      t_rob_id tail_id_nxt;
      assign tail_id_nxt = reset            ? '0                    :
                           retire_valid_rb1 ? f_incr_robid(head_id) :
                                              head_id;
   end : g_rob_tail_ptr

   assign rob_empty_de1 = f_rob_empty(head_id, tail_id);
   assign rob_full_de1  = f_rob_full(head_id, tail_id);

   // ROB pointers

//
// Debug
//

`ifdef SIMULATION

localparam FAIL_DLY = 10;
logic[FAIL_DLY:0] boom_pipe;
`DFF(boom_pipe[FAIL_DLY:1], boom_pipe[FAIL_DLY-1:0], clk);

always @(posedge clk) begin
    boom_pipe[0] <= 1'b0;
    if (uinstr_mm1.valid) begin
        `INFO(("unit:RB %s result:%08h", describe_uinstr(uinstr_mm1), result_mm1))
        print_rob_info(uinstr_mm1);
    end

    if (wren_rb1 & wraddr_rb1 == 0 & wrdata_rb1 == 64'h666) begin
        `INFO(("Saw write of 666 to x0... goodbye, folks!"))
        boom_pipe[0] <= 1'b1;
    end

    if (boom_pipe[FAIL_DLY]) begin
        $finish();
        $finish();
        $finish();
    end
end
`endif

`ifdef ASSERT
chk_always_increment #(.T(int)) fid_counting_up (
    .clk,
    .reset,
    .valid ( uinstr_mm1.valid     ),
    .count ( uinstr_mm1.SIMID.fid )
);
`endif

endmodule

`endif // __ROB_SV


