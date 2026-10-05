//===========================================================================
//-- Author			: kido
//-- Name			: apb_mst_pkg (apb master sequencer)
//-- History		: ver.1.00 (26/10/5) 1st release
//--				:
//===========================================================================
package apb_mst_pkg;

	`include "uvm_pkg.sv"
	import uvm_pkg::*;

	// typedef
	typedef apb_item#(.ADDR_W(32), .ADDR_W(32)) _apb_item;

	`include "apb_if.sv"
	`include "apb_item.sv"
	`include "apb_mst_drv.sv"
	`include "apb_mst_mon.sv"
	`include "apb_mst_seqr.sv"
	`include "apb_mst_agt.sv"
	`include "apb_mst_base_seq.sv"

endpackage
