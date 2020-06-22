// -----------------------------------------------------------------------------
// Copyright (c) 2014-2020 All rights reserved
// -----------------------------------------------------------------------------
// Author : Javen Peng, pengjaven@gmail.com
// File   : AnsDelayTimeMeasure.v
// Create : 2020-03-24 08:10:16
// Revise : 2020-03-24 08:10:16
// Editor : sublime text3, tab size (4)
// Comment:	This module is designed to measure the answer delay of the uart port. This 
// 			module using a counter to measure the interval time between the tx port and 
// 			rx port. From the last byte Stop bit of tx port to the First byte Start bit or Stop Bit
// 			of the rx port.
// 			The acurate of the data is 0.1ms.
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
module AnsDelayTimeMeasure_ver2(
	input 	clk,
	input 	rst,
	// the interface with upper module
		input [15:0] 	TimeOutSet_i,
		input 			p_TimeCntHoldSig_i,
		input 			p_TimeCntStartSig_i,
		input 			p_TimeCntResetSig_i,
	// the output interface
		output [15:0]	TimeCnt_o,
		output 			p_TimeOut_o,
	// the Counter signal
		input 			AcqSig_i
	);
	// register definition
		reg [15:0]	RxTimeCounter_r;
		reg [2:0] 	WorkState_r/*synthesis syn_preserve = 1*/;
		reg [2:0]	TimeOut_r/*synthesis syn_preserve = 1*/;
	// wire definition
		wire 		WorkState_w;
		wire 		p_over_limit_w;
		wire 		p_over_max_w;
	// parameter definition
		// Work State definition
			parameter COUNT = 1'b1;
			parameter HOLD 	= 1'b0;
		// Counter value definition
			parameter MAX 	= 16'hFFFF;
	// logic definition
		// assign p_over_limit_w 	= (delay_cnt_r >= ans_delay_limit_i);
		assign WorkState_w 		= (WorkState_r[0]&&WorkState_r[1])||(WorkState_r[1]&&WorkState_r[2])||(WorkState_r[2]&&WorkState_r[0]);
		assign p_over_limit_w 	= (RxTimeCounter_r >= TimeOutSet_i);
		assign p_over_max_w 	= (RxTimeCounter_r >= MAX);
		assign TimeCnt_o 		= RxTimeCounter_r;
		assign p_TimeOut_o   	= (TimeOut_r[0]&&TimeOut_r[1])||(TimeOut_r[1]&&TimeOut_r[2])||(TimeOut_r[2]&&TimeOut_r[0]);
	// WorkState_r update
		always @(posedge clk or negedge rst) begin
			if (!rst) begin
				WorkState_r <= {HOLD,HOLD,HOLD};				
			end
			else if (p_TimeCntStartSig_i == 1'b1) begin
				WorkState_r <= {COUNT,COUNT,COUNT};
			end
			else if ((p_over_limit_w == 1'b1) || (p_over_max_w == 1'b1) || (p_TimeCntHoldSig_i == 1'b1) ) begin
				WorkState_r <= {HOLD,HOLD,HOLD};
			end
			else begin
				WorkState_r <= {WorkState_w,WorkState_w,WorkState_w};
			end
		end
	// RxTimeCounter_r register
		always @(posedge clk or negedge rst) begin
			if (!rst) begin
				RxTimeCounter_r	<= 16'd0;			
			end
			else if ((WorkState_w == COUNT) && (AcqSig_i == 1'b1)) begin
				RxTimeCounter_r <= RxTimeCounter_r + 1'b1;
			end
			else if ((p_TimeCntStartSig_i == 1'b1) || (p_TimeCntResetSig_i == 1'b1)) begin
				RxTimeCounter_r	<= 16'd0;
			end
			else begin
				RxTimeCounter_r <= RxTimeCounter_r;  // hold
			end
		end
	// Timeout register
	 	always @(posedge clk or negedge rst) begin
	 		if (!rst) begin
	 			TimeOut_r <= 3'b111;	 			
	 		end
	 		else begin
	 			TimeOut_r <= {p_over_limit_w,p_over_limit_w,p_over_limit_w};
	 		end
	 	end
endmodule