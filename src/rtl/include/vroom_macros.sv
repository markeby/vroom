`ifndef __VROOM_MACROS_SV
`define __VROOM_MACROS_SV 

`define DFF(Q,D,clk) \
    always_ff @(posedge clk) Q <= D;

`define DFF_EN(Q,D,clk,en) \
    always_ff @(posedge clk) if(en) Q <= D;

`endif // __VROOM_MACROS_SV 
