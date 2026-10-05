//===========================================================================
//-- Author			: kido
//-- Name			: apb_mst_seqr (apb master sequencer)
//-- History		: ver.1.00 (26/10/5) 1st release
//--				:
//===========================================================================
class apb_mst_seqr extends uvm_sequencer #(_apb_item);
	`uvm_component_utils(apb_mst_seqr)

	function new(string name = "apb_mst_seqr", uvm_component parent);
		super.new(name, parent);
	endfunction
endclass
