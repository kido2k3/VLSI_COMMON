#===========================================================================
#-- Author  : kido
#-- Name    : sdc_ex.sdc (example for sdc)
#-- History : ver.1.00 (26/11/3) 1st release
#--         :
#===========================================================================

###############################################################################
# VARIABLES
###############################################################################
set SYS_CYCLE 5  #ns -> max freq = 200MHz
set APB_CYCLE 13.8888 #ns -> max freq = 72MHz


###############################################################################
# 1. SDC version (optional)
###############################################################################
set sdc_version 2.1

###############################################################################
# 2. Units (optional)
#    Should match the units in the Liberty file. Several can be set at once.
###############################################################################
set_units -time ns -capacitance pF -resistance kOhm -voltage V -current mA


###############################################################################
# A. Operating conditions (optional)
#    With separate .lib files per corner, the corner is chosen by which .lib
#    you read, so this is usually not needed.
###############################################################################
# set_operating_conditions <condition_name>


###############################################################################
# B. Wire load models (optional)
#    Only useful if the library defines wire load models.
###############################################################################
# set_wire_load_model -name <model_name>
# set_wire_load_mode <top|enclosed|segmented>


###############################################################################
# C. System interface
###############################################################################

# 3. Driving cell on input ports
#    Syntax:
#      set_driving_cell -lib_cell <cell> [-pin <out_pin>] [-from_pin <in_pin>]
#                       [-input_transition_rise <t>] [-input_transition_fall <t>]
#                       <port_list>
#    Example (do not apply it to the clock port if the clock is ideal):
# set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin Y [get_ports {rst_n i_data*}]

# 4. Load on output ports (value is in the capacitance unit, pF for sky130)
#    Syntax:
#      set_load <value> <objects>
#    Example:
# set_load 0.01 [all_outputs]


###############################################################################
# D. Design rule constraints
###############################################################################

# 5. Maximum fanout
#    Syntax:  set_max_fanout <value> <objects>
# set_max_fanout 5 [current_design]

# 6. Maximum transition (ns)
#    Syntax:  set_max_transition <value> [-data_path] [-clock_path] <objects>
# set_max_transition 1.5 [current_design]

# Maximum / minimum capacitance (pF)
# set_max_capacitance 0.2 [current_design]
# set_min_capacitance 0.0005 [current_design]


###############################################################################
# E. Timing constraints
###############################################################################

# 7. Clock definition
#    Syntax:
#      create_clock -name <name> -period <ns> [-waveform {<rise> <fall>}] <source>
#    Examples:
# create_clock -name clk -period 10 [get_ports clk]
create_clock -name sys_clk -period $SYS_CYCLE [get_ports sys_clk]
create_clock -name pclk -period $APB_CYCLE [get_ports pclk]

# 8. Generated clock (divided, multiplied or inverted from a master clock)
#    Syntax:
#      create_generated_clock -name <name> -source <master_pin_or_port>
#          [-master_clock <clk>] [-divide_by <n> | -multiply_by <n>]
#          [-duty_cycle <percent>] [-invert] [-edges {<list>}] [-add]
#          <source_objects>
#    Example:
create_generated_clock -name u_clk -source [get_ports sys_clk] -divide_by 2 [get_pins u_vsuart_prs/u_clk]

# 9. Group path (optional; options vary by tool)
#    Syntax:
#      group_path -name <group> [-weight <w>] [-from <list>] [-through <list>] [-to <list>]
#    Example:
# group_path -name rx_paths -from [get_ports i_rx] -to [get_pins u_rx/*/D]

# 10. Clock uncertainty (margin for skew and jitter, ns)
#     Syntax:
#       set_clock_uncertainty [-setup] [-hold] <value> <clocks_or_pins>
#       set_clock_uncertainty -from <clk> -to <clk> [-setup] [-hold] <value>   ;# inter-clock
# set_clock_uncertainty -setup 0.5 [get_clocks clk]
# set_clock_uncertainty -hold  0.2 [get_clocks clk]

# 11. Clock latency
#     Network latency (default) is the delay from the clock definition point to
#     the register clock pins. Source latency (-source) is the insertion delay
#     before the definition point.
#     Syntax:
#       set_clock_latency [-source] [-rise] [-fall] [-min] [-max] <delay> <clocks_or_pins>
# set_clock_latency 0.5 [get_clocks clk]
# set_clock_latency -source 0.3 [get_clocks clk]

# Clock transition (ns); applies to ideal clocks
# set_clock_transition 0.1 [get_clocks clk]

# Use real clock-tree delays instead of ideal clocks (after clock tree synthesis)
# set_propagated_clock [get_clocks clk]

# Clock groups (clocks that never interact, such as asynchronous domains)
set_clock_groups -asynchronous -group {pclk} -group {u_clk}

# 12. Input delay (relative to a clock edge; the default is 0)
#     Syntax:
#       set_input_delay <value> -clock <clk> [-max] [-min] [-rise] [-fall] [-add_delay] <ports>
# set_input_delay -clock clk -max 2.0 [get_ports i_data*]
# set_input_delay -clock clk -min 0.5 [get_ports i_data*]

# 13. Output delay (relative to a clock edge; the default is 0)
#     Syntax:
#       set_output_delay <value> -clock <clk> [-max] [-min] [-rise] [-fall] [-add_delay] <ports>
# set_output_delay -clock clk -max 2.0 [get_ports o_data*]
# set_output_delay -clock clk -min 0.5 [get_ports o_data*]
# set_output_delay -clock clk 1.7 [all_outputs]    ;# one value for min and max


###############################################################################
# F. Timing exceptions
###############################################################################

# 14. Multicycle path (the data may take more than one clock cycle)
#     Syntax:
#       set_multicycle_path <n> [-setup | -hold] [-start | -end]
#           [-from <list>] [-through <list>] [-to <list>]
#     A setup multicycle of n usually needs a hold multicycle of n-1.
# set_multicycle_path 2 -setup -from [get_pins u_a/*/Q] -to [get_pins u_b/*/D]
# set_multicycle_path 1 -hold  -from [get_pins u_a/*/Q] -to [get_pins u_b/*/D]

# 15. False path (excluded from timing analysis)
#     Syntax:
#       set_false_path [-setup] [-hold] [-from <list>] [-through <list>] [-to <list>]
# set_false_path -from [get_ports rst_n]
# set_false_path -from [get_pins ff12/CLK] -to [get_pins ff34/D]

# Maximum / minimum path delay (ns)
# set_max_delay 5.0 -from [get_ports i_data*] -to [get_ports o_data*]
# set_min_delay 0.5 -from [get_ports i_data*] -to [get_ports o_data*]

