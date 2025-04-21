## Clock signal

set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clock]
create_clock -period 10.000 -name clock -waveform {0.000 5.000} -add [get_ports clock]

##Switches

set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports i_reset]

set_property PACKAGE_PIN K16 [get_ports i_enable]
set_property IOSTANDARD LVCMOS18 [get_ports i_enable]


set_property -dict { PACKAGE_PIN D17   IOSTANDARD LVCMOS18 } [get_ports {o_data_0[7]}];
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS18 } [get_ports {o_data_0[6]}]; 
set_property -dict { PACKAGE_PIN F16   IOSTANDARD LVCMOS18 } [get_ports {o_data_0[5]}]; 
set_property -dict { PACKAGE_PIN K13   IOSTANDARD LVCMOS18 } [get_ports {o_data_0[4]}]; 
set_property -dict { PACKAGE_PIN G18   IOSTANDARD LVCMOS18 } [get_ports {o_data_0[3]}]; 
set_property -dict { PACKAGE_PIN C16   IOSTANDARD LVCMOS18 } [get_ports {o_data_0[2]}]; 
set_property -dict { PACKAGE_PIN F15   IOSTANDARD LVCMOS18 } [get_ports {o_data_0[1]}]; 
set_property -dict { PACKAGE_PIN G16   IOSTANDARD LVCMOS18 } [get_ports {o_data_0[0]}]; 
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS18 } [get_ports {o_data_1[7]}]; 
set_property -dict { PACKAGE_PIN E17   IOSTANDARD LVCMOS18 } [get_ports {o_data_1[6]}]; 
set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS18 } [get_ports {o_data_1[5]}]; 
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS18 } [get_ports {o_data_1[4]}]; 
set_property -dict { PACKAGE_PIN C17   IOSTANDARD LVCMOS18 } [get_ports {o_data_1[3]}]; 
set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS18 } [get_ports {o_data_1[2]}]; 
set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS18 } [get_ports {o_data_1[1]}]; 
set_property -dict { PACKAGE_PIN H14   IOSTANDARD LVCMOS18 } [get_ports {o_data_1[0]}]; 
set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS18 } [get_ports {o_data_2[7]}]; 
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS18 } [get_ports {o_data_2[6]}]; 
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS18 } [get_ports {o_data_2[5]}]; 
set_property -dict { PACKAGE_PIN E15   IOSTANDARD LVCMOS18 } [get_ports {o_data_2[4]}];
set_property -dict { PACKAGE_PIN E16   IOSTANDARD LVCMOS18 } [get_ports {o_data_2[3]}];
set_property -dict { PACKAGE_PIN D15   IOSTANDARD LVCMOS18 } [get_ports {o_data_2[2]}];
set_property -dict { PACKAGE_PIN C15   IOSTANDARD LVCMOS18 } [get_ports {o_data_2[1]}];
set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS18 } [get_ports {o_data_2[0]}];
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS18 } [get_ports {o_data_3[7]}];
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS18 } [get_ports {o_data_3[6]}];
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS18 } [get_ports {o_data_3[5]}];
set_property -dict { PACKAGE_PIN F18   IOSTANDARD LVCMOS18 } [get_ports {o_data_3[4]}];
set_property -dict { PACKAGE_PIN D12   IOSTANDARD LVCMOS18 } [get_ports {o_data_3[3]}];
set_property -dict { PACKAGE_PIN D13   IOSTANDARD LVCMOS18 } [get_ports {o_data_3[2]}];
set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS18 } [get_ports {o_data_3[1]}];
set_property -dict { PACKAGE_PIN A18   IOSTANDARD LVCMOS18 } [get_ports {o_data_3[0]}];

