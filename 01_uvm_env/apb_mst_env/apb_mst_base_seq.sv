//===========================================================================
//-- Author			: kido
//-- Name			: apb_mst_base_seq (apb master base sequence)
//-- History		: ver.1.00 (26/10/5) 1st release
//--				:
//===========================================================================
class apb_mst_base_seq extends uvm_sequence #(base_item);
	`uvm_object_utils(apb_mst_base_seq)
	
	int seq_length = 10;
	uvm_tlm_response_status_e status = UVM_TLM_OK_RESPONSE;

	function new(string name = "apb_mst_base_seq");
		super.new(name);
		set_response_queue_depth(seq_length + 1);
	endfunction
	
	virtual task body();
		`uvm_info("body", "Entered...", UVM_LOW)
		for(int i = 0; i < seq_length; i = i + 1) begin
			req = base_item::type_id::create("req");
			start_item(req);
			req.randomize() with {};
			req.status = UVM_TLM_INCOMPLETE_RESPONSE;
			finish_item(req);

			get_response(rsp);
			//`uvm_info("seq", $sformatf("%s", rsp.sprint), UVM_LOW)
			status = rsp.status;
			if(status == UVM_TLM_INCOMPLETE_RESPONSE) begin
				`uvm_warning("body", "Interface reset occured")
				return;
			end

		end
		`uvm_info("body", "Exit...", UVM_LOW)
	endtask
endclass
