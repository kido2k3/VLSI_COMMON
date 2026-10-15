//===========================================================================
//-- Author			: kido
//-- Name			: apb_mst_agt (apb master agent)
//-- History		: ver.1.00 (26/10/5) 1st release
//--				:
//===========================================================================
class apb_mst_agt extends uvm_agent;
	`uvm_component_utils(apb_mst_agt)

	apb_mst_drv drv;
	apb_mst_seqr seqr;
	apb_mst_mon mon;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		`uvm_info("build_phase", "Entered...", UVM_LOW)
		super.build_phase(phase);

		drv  = apb_mst_drv::type_id::create("drv", this);
		seqr = apb_mst_seqr::type_id::create("seqr", this);
		mon  = apb_mst_mon::type_id::create("mon", this);
		`uvm_info("build_phase", "Exit...", UVM_LOW)
	endfunction

	function void connect_phase(uvm_phase phase);
		`uvm_info("connect_phase", "Entered...", UVM_LOW)
		drv.seq_item_port.connect(seqr.seq_item_export);
		`uvm_info("connect_phase", "Exit...", UVM_LOW)
	endfunction

endclass
