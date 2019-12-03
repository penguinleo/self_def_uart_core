// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Javen   penguinleo@163.com
// File   : FSM_Rx.v
// Create : 2019-12-02 20:55:52
// Revise : 2019-12-02 20:55:52
// Editor : sublime text3, tab size (4)
// Comment: this module is designed to control the UART rx core. The state definition is 
// 			described as below.
//			
//          Up module:
//              xxxx.v
//          Sub module:
//              xxxx.v
// Input Signal List:
//      1   |   clk         :   clock signal
//      2   |   rst         :   reset signal
//      3   |   
// Output Signal List:
//      1   |     
//  
// Note:     
// -----------------------------------------------------------------------------
module FSM_Rx(
    // System signal definition
        input           clk,
        input           rst,
    // signal from ShiftRegister_Rx
    	input 			Rx_Synch_i,			// the triggle signal that a byte is running on the wire
    	input 			Bit_Synch_i,		// the bit in the byte has been received successfully
    // signal from the baudrate generate module
    	input 			AcqSig_i,
    // output of the FSM RX
   		output [4:0] 	State_o,			// Rx core state machine output 
   		output [3:0]	BitCounter_o		// the bit counter output
	);
	// register definition
		// state machine register
		 	reg [4:0]   state_A_r/*synthesis syn_preserve=1*/;    // the state machine
            reg [4:0]   state_B_r/*synthesis syn_preserve=1*/;
            reg [4:0]   state_C_r/*synthesis syn_preserve=1*/;
        // bit counter
            reg [3:0]   bit_counter_A_r/*synthesis syn_preserve=1*/;  // bit counter
            reg [3:0]   bit_counter_B_r/*synthesis syn_preserve=1*/;
            reg [3:0]   bit_counter_C_r/*synthesis syn_preserve=1*/;
    // wire definition
    	wire [4:0]		state_w; // triple mode result output
    	wire [3:0]		bit_counter_w;
endmodule