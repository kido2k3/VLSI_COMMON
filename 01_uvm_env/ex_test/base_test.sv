class base_test extends uvm_test;
	`uvm_component_utils(base_test) 
	// state machine for asynchronous reset
	typedef enum {INIT, CONFIGURE, TRAFFIC} state_e;
	// COMPONENTS
	top_env env;
	top_scb scb;
	state_e state;
	
	/** Customized configuration */
	apb_shared_cfg cfg;
	
	function new(string name = "base_test", uvm_component parent = null);
		super.new(name, parent);
		state = INIT;
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		`uvm_info("build_phase", "Entered...", UVM_LOW)
		super.build_phase(phase);
		
		/** Create the configuration object */
		cfg = apb_shared_cfg::type_id::create("cfg", this);

		// override here
		//...
		
		// get configuration here
		//...
		
		// set configuration here
		uvm_config_db#(apb_shared_cfg)::set(this, "env", "cfg", this.cfg);
		//...

		// create here
		env = top_env::type_id::create("env", this);
		scb = top_scb::type_id::create("scb", this);

		uvm_config_db#(uvm_object_wrapper)::set(this, "env.apb_slave_env.slave*.sequencer.run_phase", "default_sequence", svt_apb_slave_memory_sequence::type_id::get());

		/** Apply the default reset sequence */
		uvm_config_db#(uvm_object_wrapper)::set(this, "env.sequencer.reset_phase", "default_sequence", apb_simple_reset_sequence::type_id::get());

		`uvm_info("build_phase", "Exit...", UVM_LOW)
	endfunction
		
	function void end_of_elaboration_phase(uvm_phase phase);
		`uvm_info("end_of_elaboration_phase", "Entered...", UVM_LOW)
		
		uvm_top.print_topology();
		`uvm_info("sys_cfg", $sformatf("%s", cfg.sprint), UVM_LOW)

		`uvm_info("end_of_elaboration_phase", "Exiting...", UVM_LOW)
	endfunction

	virtual function void connect_phase(uvm_phase phase);
		`uvm_info("connect_phase", "Entered...", UVM_LOW)
		`uvm_info("connect_phase", "Exit...", UVM_LOW)
	endfunction

	virtual task run_phase (uvm_phase phase);
		base_seq seq = base_seq::type_id::create("seq", this);
		//svt_apb_slave_memory_sequence slv_seq = svt_apb_slave_memory_sequence::type_id:create("slv_seq");
		phase.raise_objection(this);
		//fork
		//  slv_seq.start(env.apb_slave_env.slave.sequencer);
		//join_none
		forever begin
			case(state)
				INIT: begin
					seq.start(env.apb_mst_agt.apb_mst_seqr);
					if(seq.status == UVM_TLM_OK_RESPONSE) state = CONFIGURE;
				end
				CONFIGURE: begin
					//seq.start();
					if(seq.status == UVM_TLM_OK_RESPONSE) state = TRAFFIC;
					else state = INIT;
				end
				TRAFFIC: begin
					//seq.start();
					if(seq.status == UVM_TLM_OK_RESPONSE) break;
					else state = INIT;
				end
			endcase
			`uvm_info("test run phase",$sformatf("state: %s", state.name), UVM_LOW)
		end
		phase.drop_objection(this);
	endtask

	function void final_phase(uvm_phase phase);
		uvm_report_server svr;
		`uvm_info("final_phase", "Entered...",UVM_LOW)

		super.final_phase(phase);

		svr = uvm_report_server::get_server();
		if (svr.get_severity_count(UVM_ERROR) > 0) 
			`uvm_error("Result", "Test Failed\n")
		else
			`uvm_info("Result", "Test Passed\n", UVM_LOW)
		`uvm_info("final_phase", "Exiting...", UVM_LOW)
	endfunction: final_phase
endclass

