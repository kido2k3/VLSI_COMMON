#!/bin/bash

set -e

BASE="proj_dir"

# ================= INPUT =================
read -p "input dut name: " DUT
read -p "input number of agents: " N

AGENTS=()
for ((i=0;i<N;i++)); do
    read -p "input agent[$i] name: " A
    AGENTS+=("$A")
done

# special case
SINGLE_MODE=false
if [[ ${#AGENTS[@]} -eq 1 ]]; then
    SINGLE_MODE=true
fi

# ================= UTIL =================

get_prefix() {
    local agent=$1
    if $SINGLE_MODE; then
        echo "${DUT}"
    else
        echo "${DUT}_${agent}"
    fi
}

get_if_name() {
    local agent=$1
    if $SINGLE_MODE; then
        echo "${DUT}_if"
    else
        echo "${DUT}_${agent}_if"
    fi
}

write_file() {
    local path=$1
    mkdir -p "$(dirname "$path")"
    cat > "$path"
}

# ================= SRC =================

write_file "$BASE/1_src/top.sv" <<EOF
module top;
endmodule
EOF

# ================= TB =================
IF_DECL=""
IF_SET=""
IF_RST=""

for A in "${AGENTS[@]}"; do
    P=$(get_prefix "$A")
    IF_DECL="${IF_DECL}  ${P}_if ${A}_vif(clk);
"
    IF_SET="${IF_SET}   uvm_config_db#(virtual ${P}_if)::set(uvm_root::get(), \"uvm_test_top.env*\", \"${A}_vif\", ${A}_vif);
"
    IF_RST="${IF_RST}   ${A}_vif.rst_n = 1;
    #(sim_freq) ${A}_vif.rst_n = 0;
    #(sim_freq*4) ${A}_vif.rst_n = 1;
"
done

write_file "$BASE/2_tb/tb_top.sv" <<EOF
\`timescale 1ns/1ps

\`include "uvm_pkg.sv"

\`include "${DUT}_pkg.sv"
EOF

for A in "${AGENTS[@]}"; do
    IF_NAME=$(get_if_name "$A")
    echo " \`include \"${IF_NAME}.sv\"" >> "$BASE/2_tb/tb_top.sv"
done

cat >> "$BASE/2_tb/tb_top.sv" <<EOF

module tb_top;
  import uvm_pkg::*;
  import ${DUT}_pkg::*;
  
  \`include "test_list.sv"
  
  // clk gen
  parameter sim_freq = 10;
  logic clk;
  initial begin
    clk = 0;
    forever #(sim_freq/2) clk = ~clk;
  end

${IF_DECL}
  // rst gen
  initial begin
${IF_RST}
  end

  // module instantiation
  top u_top();

  initial begin
  \`ifdef WAVE
    // dve wave dump
    \$vcdpluson;
  \`endif
    // set interface
${IF_SET}
    run_test();
  end

endmodule
EOF

# ===========TEST LIST=================

write_file "$BASE/2_tb/test_list.sv" <<EOF
\`include "base_test.sv"
EOF

# ================= INTERFACES =================

for A in "${AGENTS[@]}"; do
    IF_NAME=$(get_if_name "$A")

    write_file "$BASE/2_tb/${IF_NAME}.sv" <<EOF
interface ${IF_NAME}(input clk);
  logic rst_n;
  logic valid;
  logic ready;
  logic [31:0] data;
  
  clocking drv_if @(posedge clk);
    default input #1 output #1;
    input ready;
    output valid, data;
  endclocking

  clocking mon_if @(posedge clk);
    default input #1 output #1;
    input ready, valid, data;
  endclocking
endinterface
EOF
done

# ================= ENV =================

AGENT_DECL=""
AGENT_CREATE=""

for A in "${AGENTS[@]}"; do
    P=$(get_prefix "$A")
    AGENT_DECL="${AGENT_DECL}  ${P}_agt _${A}_agt;
"
    AGENT_CREATE="${AGENT_CREATE}   _${A}_agt = ${P}_agt::type_id::create(\"_${A}_agt\", this);
"
done

write_file "$BASE/2_tb/uvm/env/${DUT}_env.sv" <<EOF
class ${DUT}_env extends uvm_env;
  \`uvm_component_utils(${DUT}_env)

${AGENT_DECL}

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    \`uvm_info("build_phase", "Enter...", UVM_LOW)
    super.build_phase(phase);
${AGENT_CREATE}
    \`uvm_info("build_phase", "Exit...", UVM_LOW)
  endfunction

endclass
EOF

# ================ ITEM ===============
write_file "$BASE/2_tb/uvm/env/base_item.sv" <<EOF
class base_item extends uvm_sequence_item;
  rand int        value;
  rand byte       data[4];
  rand bit [7:0]  addr;
  uvm_tlm_response_status_e status;
  
  \`uvm_object_utils_begin(base_item)
    \`uvm_field_int(value, UVM_ALL_ON)
    \`uvm_field_enum(uvm_tlm_response_status_e, status, UVM_ALL_ON)
    \`uvm_field_sarray_int(data, UVM_ALL_ON)
    \`uvm_field_int(addr, UVM_ALL_ON)
  \`uvm_object_utils_end
  
  function new(string name = "base_item");
    super.new(name);
  endfunction

endclass
EOF

# ================ SEQ ===============
write_file "$BASE/2_tb/uvm/seq/base_seq.sv" <<EOF
class base_seq extends uvm_sequence #(base_item);
  \`uvm_object_utils(base_seq)
  
  int seq_length = 10;
  uvm_tlm_response_status_e status;

  function new(string name = "base_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    req = base_item::type_id::create("req");
    \`uvm_info("body", "Entered...", UVM_LOW)
    for(int i = 0; i < seq_length; i = i + 1) begin
      start_item(req);
      req.randomize() with {};
      finish_item(req);
      status = req.status;
      if(status == UVM_TLM_INCOMPLETE_RESPONSE) begin
        \`uvm_warning("body", "Interface reset occured")
        return;
      end
    end
    \`uvm_info("body", "Exit...", UVM_LOW)
  endtask
endclass
EOF

# ================ TEST ==============
write_file "$BASE/2_tb/uvm/test/base_test.sv" <<EOF
class base_test extends uvm_test;
  \`uvm_component_utils(base_test) 
  // state machine for asynchronous reset
  typedef enum {INIT, CONFIG, TRAFFIC} state_e;
  // COMPONENTS
  ${DUT}_env env;
  ${DUT}_scb scb;
  state_e state;
  
  function new(string name = "base_test", uvm_component parent = null);
    super.new(name, parent);
    state = INIT;
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    \`uvm_info("build_phase", "Entered...", UVM_LOW)
    super.build_phase(phase);
    
    // override here
    //...
    
    // get configuration here
    //...
    
    // set configuration here
    //...

    // create here
    env = ${DUT}_env::type_id::create("env", this);
    scb = ${DUT}_scb::type_id::create("scb", this);

    \`uvm_info("build_phase", "Exit...", UVM_LOW)
  endfunction
    
  function void end_of_elaboration_phase(uvm_phase phase);
    \`uvm_info("end_of_elaboration_phase", "Entered...", UVM_LOW)

    uvm_top.print_topology();
    \`uvm_info("end_of_elaboration_phase", "Exiting...", UVM_LOW)
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    \`uvm_info("connect_phase", "Entered...", UVM_LOW)
    \`uvm_info("connect_phase", "Exit...", UVM_LOW)
  endfunction

  virtual task run_phase (uvm_phase phase);
    base_seq seq = base_seq::type_id::create("seq", this);

    phase.raise_objection(this);
    forever begin
      case(state)
        INIT: begin
          //seq.start();
          //if(seq.status == UVM_TLM_OK_RESPONSE) state = CONFIG;
        end
        CONFIG: begin
          //seq.start();
          //if(seq.status == UVM_TLM_OK_RESPONSE) state = TRAFFIC;
          //else state = INIT;
        end
        TRAFFIC: begin
          //seq.start();
          //if(seq.status == UVM_TLM_OK_RESPONSE) break;
          //else state = INIT;
        end
      endcase
    end
    phase.drop_objection(this);
  endtask

  function void final_phase(uvm_phase phase);
    uvm_report_server svr;
    \`uvm_info("final_phase", "Entered...",UVM_LOW)

    super.final_phase(phase);

    svr = uvm_report_server::get_server();
    if (svr.get_severity_count(UVM_ERROR) > 0) 
      \`uvm_error("Result", "Test Failed\n")
    else
      \`uvm_info("Result", "Test Passed\n", UVM_LOW)
    \`uvm_info("final_phase", "Exiting...", UVM_LOW)
  endfunction: final_phase
endclass

EOF

# ================= SCB =================

write_file "$BASE/2_tb/uvm/env/${DUT}_scb.sv" <<EOF
//\`uvm_analysis_imp_decl(_mst)
//\`uvm_analysis_imp_decl(_slv)
class ${DUT}_scb extends uvm_scoreboard;
  \`uvm_component_utils(${DUT}_scb)
  
  function new (string name = "${DUT}_scb", uvm_component parent = null);
    super.new (name, parent);
  endfunction

  // components
  //uvm_analysis_imp_mst #(base_item, ${DUT}_scb) as_imp_mst;
  
  virtual function void build_phase (uvm_phase phase);
    \`uvm_info("build_phase", "Entered...", UVM_LOW)
      super.build_phase(phase);
      //as_imp_mst = new("as_imp_mst", this);
    \`uvm_info("build_phase", "Exit...", UVM_LOW)
  endfunction

  function void write_mst(base_item item);
    //\$cast(scb_mst_item, mst_item.clone());
  endfunction
  
  task wait_for_scb(uvm_phase phase);
    forever begin
      //wait(mst_wr_mb.num > 0 || mst_rd_mb.num > 0);
      //phase.raise_objection(this);
      //wait(mst_wr_mb.num == 0 && mst_rd_mb.num == 0);
      //phase.drop_objection(this);
    end
  endtask

  virtual task run_phase(uvm_phase phase);
    fork
      // write channel
      //channel(mst_wr_mb, slv_wr_mb);
      // read channel
      //channel(mst_rd_mb, slv_rd_mb);
      // avoid test finishing before scb
      //wait_for_scb(phase);
    join
  endtask
endclass
EOF

# ================= AGENTS =================

for A in "${AGENTS[@]}"; do
    P=$(get_prefix "$A")
    IF_NAME=$(get_if_name "$A")

    # AGENT
    write_file "$BASE/2_tb/uvm/env/${P}_agt.sv" <<EOF
class ${P}_agt extends uvm_agent;
  \`uvm_component_utils(${P}_agt)

  ${P}_drv drv;
  ${P}_seqr seqr;
  ${P}_mon mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    \`uvm_info("build_phase", "Entered...", UVM_LOW)
    super.build_phase(phase);

    drv  = ${P}_drv::type_id::create("drv", this);
    seqr = ${P}_seqr::type_id::create("seqr", this);
    mon  = ${P}_mon::type_id::create("mon", this);
    \`uvm_info("build_phase", "Exit...", UVM_LOW)
  endfunction

  function void connect_phase(uvm_phase phase);
    \`uvm_info("connect_phase", "Entered...", UVM_LOW)
    drv.seq_item_port.connect(seqr.seq_item_export);
    \`uvm_info("connect_phase", "Exit...", UVM_LOW)
  endfunction

endclass
EOF

    # DRIVER
    write_file "$BASE/2_tb/uvm/env/${P}_drv.sv" <<EOF
class ${P}_drv extends uvm_driver #(base_item);
  \`uvm_component_utils(${P}_drv)
  typedef enum {IDLE, SETUP, ACCESS} state_e;

  virtual ${IF_NAME} ${A}_vif;
  function new (string name, uvm_component parent);
      super.new (name, parent);
  endfunction

  virtual function void build_phase (uvm_phase phase);
    \`uvm_info("build_phase", "Entered...", UVM_LOW)
    super.build_phase (phase);
    // get vif
    if (! uvm_config_db #(virtual ${IF_NAME}) :: get (this, "", "${A}_vif", ${A}_vif)) begin
        \`uvm_fatal ("NOT_IF", "DUT interface not found")
    end
    \`uvm_info("build_phase", "Exit...", UVM_LOW)
  endfunction

  virtual task run_phase (uvm_phase phase);
    base_item item;
    state_e state = IDLE;

    forever begin
      // interface is reset
      // driver signal when reset
      // ${A}_vif.data <= 0;
      // ${A}_vif.valid <= 0;
      wait(!${A}_vif.rst_n);
      wait(${A}_vif.rst_n);
      forever begin
        @(${A}_vif.drv_if or negedge ${A}_vif.rst_n);
        if(!${A}_vif.rst_n) begin
          ${A}_vif.data <= 0;
          ${A}_vif.valid <= 0;
          state = IDLE;
          if(item != null) begin
            item.status = UVM_TLM_INCOMPLETE_RESPONSE;
            seq_item_port.item_done();
            phase.drop_objection(this);
          end
          while (seq_item_port.has_do_available) begin
            seq_item_port.get_next_item(item);
            item.status = UVM_TLM_INCOMPLETE_RESPONSE;
            seq_item_port.item_done();
          end
          break;
        end else begin
          drive_item(phase, state, item);
        end
      end
    end
  endtask

  virtual task drive_item (
    ref uvm_phase phase, 
    ref state_e state, 
    ref base_item item
  );
    case(state)
      IDLE: begin
        ${A}_vif.drv_if.valid <= 0;
        if(seq_item_port.has_do_available)begin
          seq_item_port.get_next_item(item);
          state = SETUP;
          phase.raise_objection(this);
        end
      end
      SETUP: begin
        ${A}_vif.drv_if.valid <= 1;
        ${A}_vif.drv_if.data <= 3;
        state = ACCESS;
      end
      ACCESS: begin
        item.status = UVM_TLM_OK_RESPONSE;
        seq_item_port.item_done();
        item = null;
        state = IDLE;
        phase.drop_objection(this);
      end
    endcase
  endtask
endclass
EOF

    # SEQR
    write_file "$BASE/2_tb/uvm/env/${P}_seqr.sv" <<EOF
class ${P}_seqr extends uvm_sequencer #(base_item);
  \`uvm_component_utils(${P}_seqr)

    function new(string name = "led_roulette_sequencer", uvm_component parent);
      super.new(name, parent);
    endfunction
endclass
EOF

    # MON
    write_file "$BASE/2_tb/uvm/env/${P}_mon.sv" <<EOF
class ${P}_mon extends uvm_monitor;
  \`uvm_component_utils(${P}_mon)

  virtual ${IF_NAME} ${A}_vif;
  // port to scoreboard
  uvm_analysis_port #(base_item)   as_port;
  function new (string name, uvm_component parent);
    super.new (name, parent);
  endfunction

  virtual function void build_phase (uvm_phase phase);
    \`uvm_info("build_phase", "Entered...", UVM_LOW)
    super.build_phase (phase);
    
    // create here
    as_port = new ("as_port", this);
    
    // get vif
    if (! uvm_config_db #(virtual ${IF_NAME}) :: get (this, "", "${A}_vif", ${A}_vif)) begin
        \`uvm_fatal ("NOT_IF", "interface not found")
    end
    \`uvm_info("build_phase", "Exit...", UVM_LOW)
  endfunction

  virtual task run_phase (uvm_phase phase);
    base_item item;
    forever begin
      wait(!${A}_vif.rst_n);
      wait(${A}_vif.rst_n);
      if(item != null) begin
        item.status = UVM_TLM_INCOMPLETE_RESPONSE;
        as_port.write(item);
      end
      item = base_item::type_id::create("item");
      forever begin
        @(${A}_vif.mon_if or negedge ${A}_vif.rst_n);
        if(!${A}_vif.rst_n) begin
          break;
        end else begin
          // monitor
        end
      end
    end
  endtask
endclass
EOF
done

# =========== PACKAGE =================

PKG_FILE="$BASE/2_tb/uvm/env/${DUT}_pkg.sv"

write_file "$PKG_FILE" <<EOF
package ${DUT}_pkg;

  \`include "uvm_pkg.sv"
  import uvm_pkg::*;

  \`include "base_item.sv"
EOF

for A in "${AGENTS[@]}"; do
    P=$(get_prefix "$A")
    echo "  \`include \"${P}_drv.sv\"" >> "$PKG_FILE"
    echo "  \`include \"${P}_mon.sv\"" >> "$PKG_FILE"
    echo "  \`include \"${P}_seqr.sv\"" >> "$PKG_FILE"
    echo "  \`include \"${P}_agt.sv\"" >> "$PKG_FILE"
done

cat >> "$PKG_FILE" <<EOF
  \`include "${DUT}_env.sv"
  \`include "${DUT}_scb.sv"
  \`include "base_seq.sv"
endpackage
EOF

# ============ F FILE ===============
write_file "$BASE/3_script/src_file.f" <<EOF
+incdir+./../1_src
./../1_src/top.sv
EOF

write_file "$BASE/3_script/tb_file.f" <<EOF
//+incdir+./../design_dir/include/sverilog
//+incdir+./../design_dir/src/sverilog/vcs
+incdir+./../2_tb
+incdir+./../2_tb/uvm/env
+incdir+./../2_tb/uvm/test
+incdir+./../2_tb/uvm/seq
./../2_tb/tb_top.sv
EOF

echo "UVM project generated successfully!"
