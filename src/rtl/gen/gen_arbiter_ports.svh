input  logic             clk,
input  logic             reset,

input  logic[NREQS-1:0]  int_req_valids,
input  T                 int_req_pkts   [NREQS-1:0],
output logic[NREQS-1:0]  int_gnts,

output logic             ext_req_valid,
output T                 ext_req_pkt,
input  logic             ext_gnt
