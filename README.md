# FPGA-LogicAnalyzer
A VHDL implementation of a logic analyzer. Tested on a Spartan 6 FPGA.

This logic analyzer is part of a larger implementation done for a course. The entire implementation has modules for a slowed down sampling rate and varying numbers of channels. This file is for a logic analyzer implementation where the FPGA input clock (48Mhz) is multiplied so that higher frequency signals can be properly sampled by the FPGA. 
