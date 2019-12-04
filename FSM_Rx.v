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
    // parameter definition
    	// state machine definition
    		parameter INTERVAL  = 5'b0_0001;
            parameter STARTBIT  = 5'b0_0010;
            parameter DATABITS  = 5'b0_0100;
            parameter PARITYBIT = 5'b0_1000;
            parameter STOPBIT   = 5'b1_0000;
    // wire assign
    	assign state_w 			= (state_A_r & state_B_r)
    							& (state_B_r & state_C_r)
    							& (state_C_r & state_A_r);
    	assign bit_counter_w 	= (bit_counter_A_r & bit_counter_B_r)
    							& (bit_counter_B_r & bit_counter_C_r)
    							& (bit_counter_C_r & bit_counter_A_r);
    	assign State_o 			= state_w;
   	// data bits counter module
   		always @(posedge clk or negedge rst) begin
   		 	if (!rst) begin
   		 		bit_counter_A_r <= 4'd0;
   		 		bit_counter_B_r <= 4'd0;
   		 		bit_counter_C_r <= 4'd0;   		 		
   		 	end
   		 	else if ((state_w == DATABITS) & (Rx_Synch_i != 1'b1)) begin
   		 		bit_counter_A_r <= bit_counter_w;
				bit_counter_B_r <= bit_counter_w;
				bit_counter_C_r <= bit_counter_w;
   		 	end
   		 	else if ((state_w == DATABITS) & (Rx_Synch_i == 1'b1)) begin
   		 		bit_counter_A_r <= bit_counter_A_r + 1'b1;
				bit_counter_B_r <= bit_counter_B_r + 1'b1;
				bit_counter_C_r <= bit_counter_C_r + 1'b1;
   		 	end
   		 	else begin
   		 		bit_counter_A_r <= 4'd0;
				bit_counter_B_r <= 4'd0;
				bit_counter_C_r <= 4'd0;
   		 	end
   		 end 
   	// state machine module
   		always @(posedge clk or negedge rst) begin
   			if (!rst) begin
				state_A_r <= INTERVAL;   				
				state_B_r <= INTERVAL;
				state_C_r <= INTERVAL; 				
   			end
   			else begin
   				case(state_w)
   					INTERVAL: begin
   						if (Rx_Synch_i == 1'b1) begin
							state_A_r <= STARTBIT;   							
							state_B_r <= STARTBIT;
							state_C_r <= STARTBIT;
   						end
   						else begin
   							state_A_r <= INTERVAL;   							
							state_B_r <= INTERVAL;
							state_C_r <= INTERVAL;
   						end
   					end
   					STARTBIT: begin
   						
   					end
   					DATABITS: begin
   						
   					end
   					PARITYBIT: begin
   						
   					end
   					STOPBIT: begin
   						
   					end
   			end
   		end
endmodule