# Basys 3 constraints for top module: full_datapath
#
# Expected top-level ports:
#   input  i_clk_100mhz
#   input  i_rst
#   input  i_rx
#   output o_tx
#   output [2:0] o_top_state
#   output [3:0] o_load_state
#   output [2:0] o_snap_state
#   output [1:0] o_tx_state
#   output o_diag_clk_locked
#   output o_diag_rst_sync

# 100 MHz onboard clock
set_property PACKAGE_PIN W5 [get_ports i_clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports i_clk_100mhz]
create_clock -name sys_clk -period 10.000 [get_ports i_clk_100mhz]

# Center button as reset
set_property PACKAGE_PIN U18 [get_ports i_rst]
set_property IOSTANDARD LVCMOS33 [get_ports i_rst]

# USB-UART bridge
# i_rx: data from host PC into FPGA
set_property PACKAGE_PIN B18 [get_ports i_rx]
set_property IOSTANDARD LVCMOS33 [get_ports i_rx]

# o_tx: data from FPGA to host PC
set_property PACKAGE_PIN A18 [get_ports o_tx]
set_property IOSTANDARD LVCMOS33 [get_ports o_tx]

# LEDs
# o_top_state[2:0] -> LD0..LD2
set_property PACKAGE_PIN U16 [get_ports {o_top_state[0]}]
set_property PACKAGE_PIN E19 [get_ports {o_top_state[1]}]
set_property PACKAGE_PIN U19 [get_ports {o_top_state[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_top_state[*]}]

# o_load_state[3:0] -> LD3..LD6
set_property PACKAGE_PIN V19 [get_ports {o_load_state[0]}]
set_property PACKAGE_PIN W18 [get_ports {o_load_state[1]}]
set_property PACKAGE_PIN U15 [get_ports {o_load_state[2]}]
set_property PACKAGE_PIN U14 [get_ports {o_load_state[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_load_state[*]}]

# o_snap_state[2:0] -> LD7..LD9
set_property PACKAGE_PIN V14 [get_ports {o_snap_state[0]}]
set_property PACKAGE_PIN V13 [get_ports {o_snap_state[1]}]
set_property PACKAGE_PIN V3  [get_ports {o_snap_state[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_snap_state[*]}]

# o_tx_state[1:0] -> LD10..LD11
set_property PACKAGE_PIN W3 [get_ports {o_tx_state[0]}]
set_property PACKAGE_PIN U3 [get_ports {o_tx_state[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_tx_state[*]}]

# Diagnostics
# o_diag_clk_locked -> LD14
# o_diag_rst_sync   -> LD15
set_property PACKAGE_PIN P1 [get_ports o_diag_clk_locked]
set_property PACKAGE_PIN L1 [get_ports o_diag_rst_sync]
set_property IOSTANDARD LVCMOS33 [get_ports o_diag_clk_locked]
set_property IOSTANDARD LVCMOS33 [get_ports o_diag_rst_sync]
