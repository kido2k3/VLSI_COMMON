interface apb_if#(
  parameter PADDR_W = 32,
  parameter PDATA_W = 32
)(input clk);
  localparam PSTRB_W = PDATA_W / 8;
  logic rst_n;
  logic [PADDR_W - 1 : 0] paddr;
  logic psel;
  logic penable;
  logic pwrite;
  logic [PDATA_W - 1 : 0] pwdata;
  logic [PSTRB_W - 1 : 0] pstrb;
  logic pready;
  logic [PDATA_W - 1 : 0] prdata;
  logic pslverr;

  // ASSERTION FOR APB

  sequence valid_s;
    psel && penable;
  endsequence

  property penable_p;
    @(posedge clk) disable iff (!rst_n)
      ($rose(psel) |=> $rose(penable)) and
      (psel && !penable |=> penable) and
      (penable && pready |=> ~penable) and
      (~psel |-> ~penable);
  endproperty

  property stable_p;
    @(posedge clk) disable iff (!rst_n)
    (valid_s |-> $stable(paddr) && $stable(pwrite)) and
    (valid_s and pwrite |-> $stable(pwdata) && $stable(pstrb));
  endproperty

  property known_p;
    @(posedge clk) disable iff (!rst_n)
      (psel |-> not($isunknown(pwrite) || $isunknown(paddr) || $isunknown(pstrb) || $isunknown(pwdata))) and
      not($isunknown(psel) || $isunknown(penable) || $isunknown(pready)) and
      (valid_s and pready && ~pwrite |-> not($isunknown(prdata))) and
      (valid_s and pready |-> not($isunknown(pslverr)));
  endproperty

  property handshake_p;
    @(posedge clk) disable iff (!rst_n)
    ($rose(psel) |-> psel throughout ##[0:$] pready) and
    ($rose(penable) |-> penable throughout ##[0:$] pready);
  endproperty
  `include "uvm_pkg.sv"
  import uvm_pkg::*;
  sva_penable: assert property (penable_p) else `uvm_error("SVA", "Failed in penable");
  sva_stable: assert property (stable_p) else `uvm_error("SVA", "Failed in stable");
  sva_known: assert property (known_p) else `uvm_error("SVA", "Failed in known");
  sva_handshake: assert property (handshake_p) else `uvm_error("SVA", "Failed in handshake");
  
endinterface
