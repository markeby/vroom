`ifndef __VROOM_MACROS_SV
`define __VROOM_MACROS_SV 

`define DFF(Q,D,clk) \
    always_ff @(posedge clk) Q <= D;

`define DFF_EN(Q,D,clk,en) \
    always_ff @(posedge clk) if(en) Q <= D;

`define MKFLAT(sig) \
    logic[$bits(sig)-1:0] f__``sig``; assign f__``sig`` = sig;

`endif // __VROOM_MACROS_SV 
