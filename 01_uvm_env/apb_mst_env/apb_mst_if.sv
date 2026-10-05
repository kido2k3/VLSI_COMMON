//===========================================================================
//-- Author			: kido
//-- Name			: apb_mst_if (apb master interface)
//-- History		: ver.1.00 (26/10/5) 1st release
//--				:
//===========================================================================
interface apb_mst_if#(
	parameter ADDR_W = 32,
	parameter DATA_W = 32
)(input clk);
	localparam STRB_W = DATA_W / 8;
	logic rst_n;
	logic [ADDR_W - 1 : 0] paddr;
	logic psel;
	logic penable;
	logic pwrite;
	logic [DATA_W - 1 : 0] pwdata;
	logic [STRB_W - 1 : 0] pstrb;
	logic pready;
	logic [DATA_W - 1 : 0] prdata;
	logic pslverr;

	task mst_if_rst;
		paddr <= 0;
		psel <= 0;
		penable <= 0;
		pwrite <= 0;
		pwdata <= 0;
		pstrb <= 0;
	endtask

	clocking drv_if @(posedge clk);
		default input #1 output #1;
		input pready, pslverr, prdata;
		output paddr, psel, penable, pwrite, pwdata, pstrb;
	endclocking

	clocking mon_if @(posedge clk);
		default input #1 output #1;
		input pready, pslverr, paddr, psel, penable, pwrite, pwdata, pstrb, prdata;
	endclocking

	// ASSERTION FOR APB

	sequence valid_s;
		psel && penable;
	endsequence

	property p_penable;
		@(posedge clk) disable iff (!rst_n)
			($rose(psel) |=> $rose(penable)) and
			(psel && !penable |=> penable) and
			(penable && pready |=> ~penable) and
			(~psel |-> ~penable);
	endproperty

	property p_stable;
		@(posedge clk) disable iff (!rst_n)
		(valid_s |-> $stable(paddr) && $stable(pwrite)) and
		(valid_s and pwrite |-> $stable(pwdata) && $stable(pstrb));
	endproperty

	property p_known;
		@(posedge clk) disable iff (!rst_n)
			(psel |-> not($isunknown(pwrite) || $isunknown(paddr) || $isunknown(pstrb) || $isunknown(pwdata))) and
			not($isunknown(psel) || $isunknown(penable) || $isunknown(pready)) and
			(valid_s and pready && ~pwrite |-> not($isunknown(prdata))) and
			(valid_s and pready |-> not($isunknown(pslverr)));
	endproperty

	property p_handshake;
		@(posedge clk) disable iff (!rst_n)
		($rose(psel) |-> psel throughout ##[0:$] pready) and
		($rose(penable) |-> penable throughout ##[0:$] pready);
	endproperty
	
	sva_penable: assert property (p_penable) else `uvm_error("SVA", $sformatf("%t: Failed in penable", $time));
	sva_stable: assert property (p_stable) else `uvm_error("SVA", $sformatf("%t: Failed in stable", $time));
	sva_known: assert property (p_known) else `uvm_error("SVA", $sformatf("%t: Failed in known", $time));
	sva_handshake: assert property (p_handshake) else `uvm_error("SVA", $sformatf("%t: Failed in handshake", $time));
	
endinterface