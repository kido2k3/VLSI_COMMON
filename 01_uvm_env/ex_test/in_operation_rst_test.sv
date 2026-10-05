class in_operation_rst_test extends base_test;
	`uvm_component_utils(in_operation_rst_test) 
	// COMPONENTS
	
	function new(string name = "in_operation_rst_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		`uvm_info("build_phase", "Entered...", UVM_LOW)
		
		super.build_phase(phase);

		// override factory here
		set_type_override_by_type(apb_simple_reset_sequence::get_type(), in_operation_rst_seq::get_type());
		//...

		// change configuration here
		//...

		`uvm_info("build_phase", "Exit...", UVM_LOW)
	endfunction
endclass

