`ifndef __VROOM_MACROS_SV
`define __VROOM_MACROS_SV 

`define DFF(Q,D,clk) \
    always_ff @(posedge clk) Q <= D;

`define DFF_EN(Q,D,clk,en) \
    always_ff @(posedge clk) if(en) Q <= D;

`define MKFLAT(sig) \
    logic[$bits(sig)-1:0] f__``sig``; assign f__``sig`` = sig;

`define MKPIPE(tp, sigx, fr, to) \
    tp sigx [``to``:``fr``]; \
    for (genvar stg=``fr``+1; stg<=``to``; stg++) `DFF(``sigx``[stg], ``sigx``[stg-1], clk)

`define MKPIPE_INIT(tp, sigx, sig0, fr, to) \
    `MKPIPE(tp,sigx,fr,to) \
    always_comb sigx[fr]=sig0; 

`define PMSG(tag, msg) \
    $display("@[%-d] %-d tag: %s", $time(), top.cclk_count, $sformatf msg);

`define INFO(msg) \
    `PMSG(I, msg)

`ifdef DEBUGON
    `define DEBUG(msg) \
        `PMSG(D, msg)
`else
    `define DEBUG(msg) 
`endif

`define VASSERT(name, antecedent, consequent, msg) \
    name: assert property (@(posedge clk) (antecedent) |-> (consequent)) else $error(msg);

`endif // __VROOM_MACROS_SV 
