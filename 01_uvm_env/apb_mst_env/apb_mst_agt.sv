//===========================================================================
//-- Author			: kido
//-- Name			: apb_mst_agt (apb master agent)
//-- History		: ver.1.00 (26/10/5) 1st release
//--				:
//===========================================================================
class apb_mst_agt extends uvm_agent;
	`uvm_component_utils(apb_mst_agt)

	apb_mst_drv apb_mst_drv;
	apb_mst_seqr apb_mst_seqr;
	apb_mst_mon apb_mst_mon;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		`uvm_info("build_phase", "Entered...", UVM_LOW)
		super.build_phase(phase);

		apb_mst_drv  = apb_mst_drv::type_id::create("apb_mst_drv", this);
		apb_mst_seqr = apb_mst_seqr::type_id::create("apb_mst_seqr", this);
		apb_mst_mon  = apb_mst_mon::type_id::create("apb_mst_mon", this);
		`uvm_info("build_phase", "Exit...", UVM_LOW)
	endfunction

	function void connect_phase(uvm_phase phase);
		`uvm_info("connect_phase", "Entered...", UVM_LOW)
		apb_mst_drv.seq_item_port.connect(apb_mst_seqr.seq_item_export);
		`uvm_info("connect_phase", "Exit...", UVM_LOW)
	endfunction

endclass
