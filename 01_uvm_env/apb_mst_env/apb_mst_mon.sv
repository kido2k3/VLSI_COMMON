//===========================================================================
//-- Author			: kido
//-- Name			: apb_mst_mon (apb master monitor)
//-- History		: ver.1.00 (26/10/5) 1st release
//--				:
//===========================================================================
class apb_mst_mon extends uvm_monitor;
	`uvm_component_utils(apb_mst_mon)

	virtual apb_mst_if vif;
	// port to scoreboard
	uvm_analysis_port #(_apb_item)   as_port;
	function new (string name, uvm_component parent);
		super.new (name, parent);
	endfunction
	// build phase: get vif
	virtual function void build_phase (uvm_phase phase);
		`uvm_info("build_phase", "Entered...", UVM_LOW)
		super.build_phase (phase);
		
		// create here
		as_port = new ("as_port", this);
		
		// get vif
		if (! uvm_config_db #(virtual apb_mst_if) :: get (this, "", "apb_mst_vif", vif)) begin	
			`uvm_fatal ("NOT_IF", "interface not found")
		end
		`uvm_info("build_phase", "Exit...", UVM_LOW)
	endfunction

	// run phase: support asynchronous reset
	virtual task run_phase (uvm_phase phase);
		_apb_item item;
		forever begin
			if(item != null) begin
				item.status = UVM_TLM_INCOMPLETE_RESPONSE;
				as_port.write(item);
			end
			item = _apb_item::type_id::create("item");
			forever begin
				@(vif.mon_if or negedge vif.rst_n);
				if(!vif.rst_n) begin
					break;
				end else begin
					monitor_item(item);
				end
			end
		end
	endtask

	// monitor item: create item via interface
	task monitor_item (ref _apb_item item);
		if(vif.mon_if.psel & vif.mon_if.penable & vif.mon_if.pready) begin
			item = _apb_item::type_id::create("item");
			item.addr = vif.mon_if.paddr;
			item.trans_type = _apb_item::type_e'(vif.mon_if.pwrite);
			if(item.trans_type == _apb_item::WRITE) begin
				item.data = vif.mon_if.pwdata;
				item.strb = vif.mon_if.pstrb;
			end else begin
				item.data = vif.mon_if.prdata;
			end
			item.slverr = vif.mon_if.pslverr;
			item.status = UVM_TLM_OK_RESPONSE;
			`uvm_info("apb mst mon", $sformatf("%s", item.sprint), UVM_LOW)
			as_port.write(item);
			item = null;
		end
	endtask
endclass
