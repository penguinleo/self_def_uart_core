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
module AnsDelayTimeMeasure(
	input 	clk,
	input 	rst,
	// the interface with the tx core
		input 			p_SendFinished_i,
	// the interface with the rx core
		input 			p_DataReceived_i,
	// the 10MHz Signal
		input 			p_sig_10MHz_i,
	// Ans delay information opperation port
		input 			n_rd_i,
		input 			n_clr_i,
		// input 	[15:0]	ans_delay_limit_i,
		output 	[15:0]  ans_delay_o
	);
	// register definition
		reg [15:0]	ans_delay_time1_r;
		reg [15:0]	ans_delay_time2_r;
		reg [15:0]	ans_delay_time3_r;
		reg [15:0]	ans_delay_time4_r;
		reg [15:0]	ans_delay_time_r;
		reg [15:0]	delay_cnt_r;
		reg [3:0]	info_num_r;
		reg  		flag_tx_rx_interval_r;
	// wire definition
		wire 		p_over_limit_w;
	// parameter definition
		parameter	MAX_DLY_TIME 	= 16'd999;
		parameter 	FLAG_1 			= 1'b1;
		parameter 	FLAG_0			= 1'b0;
	// logic definition
		// assign p_over_limit_w 	= (delay_cnt_r >= ans_delay_limit_i);
		assign p_over_max_w 	= (delay_cnt_r >= MAX_DLY_TIME);
		assign ans_delay_o 		= ans_delay_time_r;
	// the interval flag
		always @(posedge clk or negedge rst) begin
			if (!rst) begin
				flag_tx_rx_interval_r <= FLAG_0;				
			end
			else if (p_SendFinished_i == 1'b1) begin
				flag_tx_rx_interval_r <= FLAG_1;
			end
			else if (p_DataReceived_i == 1'b1) begin
				flag_tx_rx_interval_r <= FLAG_0;
			end
			else begin
				flag_tx_rx_interval_r <= flag_tx_rx_interval_r;
			end
		end
	// the output buffer of ans_delay_time_r
		always @(posedge clk or negedge rst) begin
			if (!rst) begin
				ans_delay_time_r <= 16'd0;				
			end
			else if (n_rd_i) begin
				ans_delay_time_r <= ans_delay_time1_r;
			end
			else begin
				ans_delay_time_r <= ans_delay_time_r;
			end
		end
	// the counter, the response interval counter would keep gain with the flag is 1 below max
		always @(posedge clk or negedge rst) begin
			if (!rst) begin
				delay_cnt_r <= 16'd0;				
			end
			else if ((p_SendFinished_i == 1'b1) || (n_clr_i == 1'b0)) begin
				delay_cnt_r <= 16'd0;
			end
			else if ((p_sig_10MHz_i == 1'b1) && (flag_tx_rx_interval_r == FLAG_1)) begin
				if (~p_over_max_w) begin
					delay_cnt_r <= delay_cnt_r + 1'b1;
				end
				else begin
					delay_cnt_r <= MAX_DLY_TIME;
				end				
			end
		end
	// delay fifo fresh\
		always @(posedge clk or negedge rst) begin
			if (!rst) begin
				ans_delay_time1_r <= 16'd0;
				ans_delay_time2_r <= 16'd0;
				ans_delay_time3_r <= 16'd0;
				ans_delay_time4_r <= 16'd0;				
			end
			else if ((p_DataReceived_i == 1'b1) && (flag_tx_rx_interval_r == FLAG_1)) begin // receive 
				case(info_num_r)
					4'd0: begin
						ans_delay_time1_r <= delay_cnt_r;
						ans_delay_time2_r <= 16'd0;
						ans_delay_time3_r <= 16'd0;
						ans_delay_time4_r <= 16'd0;
					end
					4'd1: begin
						ans_delay_time1_r <= ans_delay_time1_r;
						ans_delay_time2_r <= delay_cnt_r;
						ans_delay_time3_r <= 16'd0;
						ans_delay_time4_r <= 16'd0;
					end
					4'd2: begin
						ans_delay_time1_r <= ans_delay_time1_r;
						ans_delay_time2_r <= ans_delay_time2_r;
						ans_delay_time3_r <= delay_cnt_r;
						ans_delay_time4_r <= 16'd0;
					end
					4'd3: begin
						ans_delay_time1_r <= ans_delay_time1_r;
						ans_delay_time2_r <= ans_delay_time2_r;
						ans_delay_time3_r <= ans_delay_time3_r;
						ans_delay_time4_r <= delay_cnt_r;
					end
					4'd4: begin
						ans_delay_time1_r <= ans_delay_time2_r;
						ans_delay_time2_r <= ans_delay_time3_r;
						ans_delay_time3_r <= ans_delay_time4_r;
						ans_delay_time4_r <= delay_cnt_r;
					end
					default: begin
						ans_delay_time1_r <= ans_delay_time2_r;
						ans_delay_time2_r <= ans_delay_time3_r;
						ans_delay_time3_r <= ans_delay_time4_r;
						ans_delay_time4_r <= delay_cnt_r;
					end
				endcase
			end
			else if (n_rd_i == 1'b0) begin // read info
				ans_delay_time1_r <= ans_delay_time2_r;
				ans_delay_time2_r <= ans_delay_time3_r;
				ans_delay_time3_r <= ans_delay_time4_r;
				ans_delay_time4_r <= 16'd0;
			end
		end
	// info num opperate submodule, the info_num_r would gain to 4
	 	always @(posedge clk or negedge rst) begin
	 		if (!rst) begin
	 			info_num_r <= 4'd0;	 			
	 		end
	 		else if (n_clr_i == 1'b0) begin
	 			info_num_r <= 4'd0;
	 		end
	 		else begin
	 			case(info_num_r)
	 				4'd0: begin
	 					if ((p_DataReceived_i == 1'b1) && (flag_tx_rx_interval_r == FLAG_1)) begin
	 						info_num_r <= 4'd1;
	 					end
	 					else begin
	 						info_num_r <= 4'd0;	 						
	 					end
	 				end
	 				4'd1: begin
	 					if ((p_DataReceived_i == 1'b1) && (flag_tx_rx_interval_r == FLAG_1)) begin
	 						info_num_r <= 4'd2;
	 					end
	 					else if (n_rd_i == 1'b0) begin
	 						info_num_r <= 4'd0;
	 					end
	 					else begin
	 						info_num_r <= 4'd1;
	 					end
	 				end
	 				4'd2: begin
	 					if ((p_DataReceived_i == 1'b1) && (flag_tx_rx_interval_r == FLAG_1)) begin
	 						info_num_r <= 4'd3;
	 					end
	 					else if (n_rd_i == 1'b0) begin
	 						info_num_r <= 4'd1;
	 					end
	 					else begin
	 						info_num_r <= 4'd2;
	 					end
	 				end
	 				4'd3: begin
	 					if ((p_DataReceived_i == 1'b1) && (flag_tx_rx_interval_r == FLAG_1)) begin
	 						info_num_r <= 4'd4;
	 					end
	 					else if (n_rd_i == 1'b0) begin
	 						info_num_r <= 4'd2;
	 					end
	 					else begin
	 						info_num_r <= 4'd3;
	 					end
	 				end
	 				4'd4: begin
	 					if (n_rd_i == 1'b0) begin
	 						info_num_r <= 4'd3;
	 					end
	 					else begin
	 						info_num_r <= 4'd4;
	 					end
	 				end
	 				default: begin
	 					info_num_r <= 4'd4;
	 				end
	 			endcase
	 		end
	 	end
	// 

endmodule