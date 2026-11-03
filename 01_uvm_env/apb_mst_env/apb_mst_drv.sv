//===========================================================================
//-- Author			: kido
//-- Name			: apb_mst_drv (apb master driver)
//-- History		: ver.1.00 (26/10/5) 1st release
//--				: ver.1.01 (26/11/3) fix drv sample data
//===========================================================================
class apb_mst_drv extends uvm_driver #(_apb_item);
	`uvm_component_utils(apb_mst_drv)
	typedef enum {IDLE, SETUP, ACCESS} state_e;

    state_e state = IDLE;
	_apb_item item;
	virtual apb_mst_if vif;
	function new (string name, uvm_component parent);
		super.new (name, parent);
	endfunction
	
	// build phase: get vif
	virtual function void build_phase (uvm_phase phase);
		`uvm_info("build_phase", "Entered...", UVM_LOW)
		super.build_phase (phase);
		// get vif
		if (! uvm_config_db #(virtual apb_mst_if) :: get (this, "", "apb_mst_vif", vif)) begin
			`uvm_fatal ("NOT_IF", "DUT interface not found")
		end
		`uvm_info("build_phase", "Exit...", UVM_LOW)
	endfunction

	//run phase: support asynchronous rst during apb transaction
	virtual task run_phase (uvm_phase phase);
		forever begin
			// interface is reset
			wait(!vif.rst_n);
			// driver signal when reset
			vif.mst_if_rst();
			wait(vif.rst_n);
			forever begin
				@(vif.drv_if or negedge vif.rst_n);
				if(!vif.rst_n) begin
					// reset assert: 
					// notify to sequence, 
					// clear fifo in sequencer
					`uvm_info("RST", "Found rst asserting", UVM_LOW)
                    set_state(IDLE);
					vif.mst_if_rst();
					if(item != null) begin
						item.status = UVM_TLM_INCOMPLETE_RESPONSE;
						seq_item_port.put(item);
						//seq_item_port.item_done();
					end
					while (seq_item_port.has_do_available) begin
						seq_item_port.get(item);
						//seq_item_port.get_next_item(item);
						//item.status = UVM_TLM_INCOMPLETE_RESPONSE;
						//seq_item_port.item_done();
					end
					break;
				end else begin
					drive_item(phase);
				end
			end
		end
	endtask
    
    // task: set a state with corresponding interface
    task set_state(state_e st);
        case(st)
            IDLE: begin
                vif.drv_if.psel <= 0;
                vif.drv_if.penable <= 0;
            end
            SETUP: begin
                vif.drv_if.psel <= 1;
                vif.drv_if.penable <= 0;
				vif.drv_if.paddr <= item.addr;
				vif.drv_if.pwrite <= int'(item.trans_type);
				vif.drv_if.pwdata <= item.data;
				vif.drv_if.pstrb <= item.strb;
            end
            ACCESS: begin
                vif.drv_if.psel <= 1;
                vif.drv_if.penable <= 1;
            end
        endcase
        state = st;
		`uvm_info("apb mst drv", $sformatf("drv_state = %s", state.name), UVM_DEBUG)
    endtask

	// drive item: drive interface via received item
	virtual task drive_item (ref uvm_phase phase);
		case(state)
			IDLE: begin
				if(phase.get_objection_count(this) > 0) begin
						phase.drop_objection(this);
				end
				if(seq_item_port.has_do_available)begin
					seq_item_port.get(item);
					//seq_item_port.get_next_item(item);
					`uvm_info("apb mst drv", $sformatf("%s", item.sprint), UVM_MEDIUM)
                    set_state(SETUP);
					phase.raise_objection(this);
				end
			end
			SETUP: begin
                set_state(ACCESS);
			end
			ACCESS: begin
				// check ready
				if (vif.drv_if.pready) begin
					// ready assert
					item.status = UVM_TLM_OK_RESPONSE;
					item.slverr = vif.drv_if.pslverr;
					if(item.trans_type == _apb_item::READ) begin
						item.data = vif.drv_if.prdata;
					end
					seq_item_port.put(item);
					item = null;
					if(seq_item_port.has_do_available)begin
						seq_item_port.get(item);
                        set_state(SETUP);
					end else begin
                        set_state(IDLE);
					end
				end
			end
		endcase
	endtask
endclass
