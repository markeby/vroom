`ifndef __L1DATA_SV
`define __L1DATA_SV

`include "instr.pkg"
`include "vroom_macros.sv"
`include "rob_defs.pkg"
`include "mem_common.pkg"
`include "mem_defs.pkg"

module l1data
    import instr::*, instr_decode::*, common::*, rob_defs::*, mem_defs::*, mem_common::*;
(
    input  logic              clk,
    input  logic              reset,

    input  logic              data_rd_en_mm1,
    input  t_l1_set_addr      set_addr_mm1,

    input  logic              data_wr_en_mm3,
    input  t_cl               data_wr_data_mm3,
    input  t_cl_be            data_wr_be_mm3,
    input  t_l1_way           data_wr_way_mm3,
    input  t_l1_set_addr      set_addr_mm3,

    output t_cl               data_rd_ways_mm2[L1_NUM_WAYS-1:0]
);

//
// Nets
//

t_cl data_array [L1_NUM_SETS-1:0][L1_NUM_WAYS-1:0];

//
// Logic
//

always_ff @(posedge clk) begin
    if (data_wr_en_mm3) begin
        for (int i=0; i<CL_SZ_BYTES; i++) begin
            if (data_wr_be_mm3[i[5:0]]) begin
                data_array[set_addr_mm3][data_wr_way_mm3].B[i] <= data_wr_data_mm3.B[i];
            end
        end
    end
end

`DFF(data_rd_ways_mm2, data_array[set_addr_mm1], clk)

//
// Debug
//

`ifdef SIMULATION
// always @(posedge clk) begin
//     if (iss_mm0) begin
//         `INFO(("unit:MM %s", describe_uinstr(iss_pkt_mm0.uinstr)))
//     end
// end
`endif

    /*
`ifdef ASSERT
`VASSERT(a_illegal_format, uinstr_de1.valid, uinstr_de1.ifmt inside {RV_FMT_I,RV_FMT_R}, $sformatf("Unsupported instr fmt: %s", uinstr_de1.ifmt.name()))
`endif
    */

endmodule

`endif // __L1DATA_SV


