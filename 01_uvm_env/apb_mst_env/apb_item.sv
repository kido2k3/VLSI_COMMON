//===========================================================================
//-- Author			: kido
//-- Name			: apb_item
//-- History		: ver.1.00 (26/10/5) 1st release
//--				:
//===========================================================================
class apb_item #(
	parameter ADDR_W = 32,
	parameter DATA_W = 32
) extends uvm_sequence_item;

	typedef enum bit {WRITE=1, READ=0} type_e;

	localparam STRB_W = DATA_W / 8;

	rand bit [ADDR_W - 1 : 0] addr;
	rand bit [DATA_W - 1 : 0] data;
	rand bit [STRB_W - 1 : 0] strb;
	rand type_e trans_type;
	bit slverr;
	uvm_tlm_response_status_e status;

	`uvm_object_utils_begin(apb_item)
		`uvm_field_int(addr, UVM_ALL_ON)
		`uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
		`uvm_field_int(strb, UVM_ALL_ON | UVM_BIN)
		`uvm_field_enum(type_e, trans_type, UVM_ALL_ON)
		`uvm_field_int(slverr, UVM_ALL_ON | UVM_BIN)
		`uvm_field_enum(uvm_tlm_response_status_e, status, UVM_ALL_ON)
	`uvm_object_utils_end

	function new(string name = "apb_item");
		super.new(name);
	endfunction

endclass
