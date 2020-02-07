// -----------------------------------------------------------------------------
// Copyright (c) 2014-2020 All rights reserved
// -----------------------------------------------------------------------------
// Author : Javen Peng, pengjaven@gmail.com
// File   : ByteAnalyseV2.v
// Create : 2020-01-26 17:14:16
// Revise : 2020-01-26 21:52:30
// Editor : sublime text3, tab size (4)
// Comment:	This module function:
// 			1, Byte data anlayse;
// 			2, Time stamp generate;
// 
// Input Signal List:
// 		1	:	clk, the system input clock signal, the frequency is greater than 40MHz
// 		2	:	rst, the system reset signal, the module should be reset asynchronously,
//                   and must be released synchronously with the clock;
// 		3	:	
// Output Signal List:
// 		1	:	
// Note	
// -----------------------------------------------------------------------------
module ByteAnalyseV2(
	input   clk,
    input   rst,
    // the interface with fifo 
        output          n_we_o,
        output  [7:0]   data_o,
        input           p_full_i,
    // the interface with shift register
        input   [11:0]  byte_i,
        input           Bit_Synch_i,
    // the interface with the FSM
        input   [4:0]   State_i,
        input   [3:0]   BitWidthCnt_i,
    // the control register
        input           p_ParityEnable_i,
        input           p_BigEnd_i,
    // the error flag
        output          p_ParityError_o
	);
	// register definition
		reg []
	// wire definition
		


endmodule