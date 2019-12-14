// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Javen   penguinleo@163.com
// File   : ByteAnalyse.v
// Create : 2019-12-14 18:48:37
// Revise : 2019-12-14 18:48:37
// Editor : sublime text3, tab size (4)
// Comment: this module is designed to analyse the received byte data and store it 
// 			in the fifo. So this module get data from the shiftregister module and 
// 			send data to the fifo module.
//          Up module:
//              RxCore.v
//          Sub module:
//              ---
// Input Signal List:
//      1   |   clk         :   clock signal
//      2   |   rst         :   reset signal
//      3   |   
// Output Signal List:
//      1   |     
//  
// Note:  
// 
// -----------------------------------------------------------------------------   
module ByteAnalyse(
	input 	clk,
	input 	rst,
	// the interface with fifo 
		output 			n_we_o,
		output 	[7:0]	data_o,
		input 			p_full_i,
	// the interface with shift register
		input 	[11:0]	byte_i,
		input 			Bit_Synch_i,
	// the interface with the FSM
		input  	[4:0]	State_i,
		input 	[3:0]	BitCounter_o,
	// the control register
		input 			p_ParityEnable_i,
		input 			p_BigEnd_i,
	// the error flag
		output 			p_ParityError_o
	);
	// register definition
		reg [7:0]		byte_r;
		reg 			p_ParityError_r;
	


endmodule
