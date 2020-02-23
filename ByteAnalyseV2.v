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
// Note:
// 		2020-02-16 	This module should be seperated from the state machine of the Rx machine.
// 					The data process could compensate many clocks, thus the baudrate would be
// 					limited by the data processing module.
// -----------------------------------------------------------------------------
module ByteAnalyseV2(
	input   clk,
    input   rst,
    // the interface with fifo 
        output          n_we_o,
        output  [7:0]   data_o,
        input           p_full_i,
    // the interface with the baudrate module
    	input 			BaudSig_i,
    // the interface with shift register
        input   [11:0]  byte_i,
        input           Bit_Synch_i,
        input 			Byte_Synch_i,
    // the interface with the FSM
        input   [4:0]   State_i,
        input   [3:0]   BitWidthCnt_i,
    // the interface with the Time Stamp Module
    	input   [3:0]    acqurate_stamp_i,
        input   [11:0]   millisecond_stamp_i,
        input   [31:0]   second_stamp_i,
    // the control register
        input           p_ParityEnable_i,
        input           p_BigEnd_i,
    // the frame fifo interface
    	input 			n_rd_frame_fifo_i,
    	output 	[27:0]	frame_info_o,
    // the interface with the parity generator module
    	output 	[7:0]	ParityCalData_o,
    	output 			p_ParityCalTrigger_o,
    	input 			ParityResult_i,
        output  [7:0]   ParityErrorNum_o
	);
	// register definition
		// state machine
			reg [4:0]		state_r;		// the state machine register of the module
			reg [11:0] 		byte_r;   // the buffer for the input data
			reg 			parity_trig_r;
			reg 			parity_result_r;
			reg [7:0]		fifo_data_r;		// the data that sent to the fifo
			reg 			n_we_r;				// the we signal of the fifo
			reg 			n_rd_frame_fifo_r;	// 
			reg [2:0]		rd_frame_fifo_shift_r;
			reg [7:0]		parity_error_num_r; // the parity error number
		// the time stamp
			reg [31:0]	t0_s_stamp_r;
			reg [11:0]	t0_ms_stamp_r;
			reg [3:0]	t0_100us_stamp_r;	
		// the frame info recognize register
			reg [7:0]	byte_interval_cnt_r;	// the frame interval counter
			reg [7:0]	byte_num_cnt_r;			// the frame byte number counter
			reg [3:0]	frame_num_cnt_r;		// indicate that how many frame left in the  fifo
			reg 		new_frame_sig_r;		// indicate that this byte belong to another frame
		// Frame information buffer
			reg [27:0] 	frame0_info_r;
			reg [27:0]	frame1_info_r;
			reg [27:0] 	frame2_info_r;	
			reg [27:0]	frame3_info_r;
			reg [27:0]	frame_info_output_r;		
	// wire definition
		// control signal
			wire [7:0]	big_end_data_w; 
			wire [7:0]	little_end_data_w;	
			wire 		start_bit_w;
			wire 		parity_bit_w;
			wire 		stop_bit_w;
			wire 		falling_edge_rd_fifo_w;
		// Frame0 information definition
			wire [11:0]	frame0_stamp_ms_w;
			wire [3:0]	frame0_stamp_us_w;
			wire [11:0]	frame0_byte_num_w;
		// Frame3 information definition
			wire [11:0]	frame3_stamp_ms_w;
			wire [3:0]	frame3_stamp_us_w;
			wire [11:0]	frame3_byte_num_w;
	// parameter definition
		// State Machine definition
			parameter IDLE  	= 5'b0_0001; 	// the module is waiting the shiftregister module give out data
			parameter BUFF 		= 5'b0_0010;  	// the module is buffering the data and give out the time stamp
			parameter PARR 		= 5'b0_0100;	// the module is checking the data according to the parity data
			parameter CHCK 		= 5'b0_1000;	// the module recognizes the frame 
			parameter FIFO 		= 5'b1_0000;	// the module should send out the data to the FIFO
		// The Byte interval definition
			parameter MAX_CNT_NUM 			= 8'hff;
			parameter BYTE_CNT_NUM 			= 8'd11;
			parameter FRAME_BYTE_INTERVAL 	= BYTE_CNT_NUM + 8'd17;  // the byte interval in one frame should less than 16.5 baudrate time
			parameter FRAME_INTERVAL 		= BYTE_CNT_NUM + 8'd55;  // the interval between two consecutive frames should less than 55 baudrate time
		// The frame definition
			parameter NEW_FRAME = 1'b1;
			parameter NOT_FINISH= 1'b0;
		// parity enable definition
            parameter ENABLE    = 1'b1;
            parameter DISABLE   = 1'b0;
        // Big end and littel end definition
            parameter BIGEND    = 1'b1;
            parameter LITTLEEND = 1'b0;
        // Parity check results
        	parameter PAR_TRUE 	= 1'b1;
        	parameter PAR_FALSE = 1'b0;
	// Logic definition
		// output logic definition
			assign ParityCalData_o 		= byte_r[10:3];
			assign data_o 				= fifo_data_r;
			assign p_ParityCalTrigger_o = parity_trig_r;
			assign n_we_o  				= n_we_r;
			assign ParityErrorNum_o 	= parity_error_num_r;
		// inner logic signal
			assign start_bit_w 				= byte_r[11];
			assign little_end_data_w 		= {
                                    			byte_r[3],byte_r[4],byte_r[5],byte_r[6],
                                    			byte_r[7],byte_r[8],byte_r[9],byte_r[10]
                                				};
        	assign big_end_data_w 			= {
                                	    		byte_r[10],byte_r[9],byte_r[8],byte_r[7],
                                	    		byte_r[6],byte_r[5],byte_r[4],byte_r[3]
                                				};
            assign parity_bit_w 			= byte_r[2];
            assign stop_bit_w 				= byte_r[1];
        // Frame0 and Frame1 logic definition
        	assign frame0_stamp_ms_w = frame0_info_r[17:16];
        	assign frame0_stamp_us_w = frame0_info_r[15:12];
        	assign frame0_byte_num_w = frame0_info_r[11:00];
        	assign frame3_stamp_ms_w = frame3_info_r[17:16];
        	assign frame3_stamp_us_w = frame3_info_r[15:12];
        	assign frame3_byte_num_w = frame3_info_r[11:00];
        	assign frame_info_o 	 = frame_info_output_r;
	// Basic function module
	    // state machine
	    	always @(posedge clk or negedge rst) begin
	    		if (!rst) begin
	    			state_r <= IDLE;    			
	    		end
	    		else begin
	    			case(state_r)
	    				IDLE:	begin
	    					if (Byte_Synch_i == 1'b1) begin
	    						state_r <= BUFF;
	    					end
	    					else begin
	    						state_r <= IDLE;
	    					end
	    				end
	    				BUFF:	begin
	    					state_r <= PARR;
	    				end
	    				PARR:	begin
	    					state_r <= CHCK;
	    				end
	    				CHCK:	begin
	    					state_r <= FIFO;
	    				end
	    				FIFO:	begin
	    					state_r <= IDLE;
	    				end
	    				default: begin
	    					state_r <= IDLE;
	    				end
	    			endcase
	    		end
	    	end
		// byte_r buffer fresh module
			always @(posedge clk or negedge rst) begin
				if (!rst) begin
					// reset
					byte_r <= 12'h000;
				end
				else if (Byte_Synch_i == 1'b1) begin
					byte_r <= byte_i;
				end
				else begin
					byte_r <= byte_r;
				end
			end
		// parity trigger sig register
			always @(posedge clk or negedge rst) begin
				if (!rst) begin
					parity_trig_r <= 1'b0;				
				end
				else if ((state_r == BUFF) && (p_ParityEnable_i == ENABLE)) begin
					parity_trig_r <= 1'b1;
				end 
				else begin
					parity_trig_r <= 1'b0;
				end
			end
		// fifo data output register fresh
			always @(posedge clk or negedge rst) begin
				if (!rst) begin
					fifo_data_r <= 8'd0;				
				end
				else if (state_r == PARR) begin
					if (p_BigEnd_i == BIGEND) begin
						fifo_data_r <= big_end_data_w;
					end
					else begin
						fifo_data_r <= little_end_data_w;
					end
				end
				else begin
					fifo_data_r <= fifo_data_r;
				end
			end
		// parity results register
			always @(posedge clk or negedge rst) begin
				if (!rst) begin
					parity_result_r <= PAR_TRUE;				
				end
				else if ((state_r == CHCK) && (p_ParityEnable_i == ENABLE)) begin
					parity_result_r <= (ParityResult_i ^~ parity_bit_w);
				end
				else if (p_ParityEnable_i == DISABLE) begin
					parity_result_r <= PAR_TRUE;
				end
				else begin
					parity_result_r <= parity_result_r;
				end
			end
		// FIFO operation
			always @(posedge clk or negedge rst) begin
				if (!rst) begin
					n_we_r <= 1'b1;				
				end
				else if ((state_r == FIFO) && (parity_result_r == PAR_TRUE)) begin
					n_we_r <= 1'b0;
				end
				else begin
					n_we_r <= 1'b1;
				end
			end
	// Advanced function module
		// Time stample 
			always @(posedge clk or negedge rst) begin
				if (!rst) begin
					t0_s_stamp_r 		<= 32'd0;
					t0_ms_stamp_r 		<= 12'd0;
					t0_100us_stamp_r	<= 4'd0;			
				end
				else if (Byte_Synch_i == 1'b1) begin
					t0_s_stamp_r 		<= second_stamp_i;
					t0_ms_stamp_r 	 	<= millisecond_stamp_i;
					t0_100us_stamp_r 	<= acqurate_stamp_i;
				end
				else begin
					t0_s_stamp_r		<= t0_s_stamp_r;
					t0_ms_stamp_r		<= t0_ms_stamp_r;
					t0_100us_stamp_r 	<= t0_100us_stamp_r;
				end
			end
		// Byte interval counter
			always @(posedge clk or negedge rst) begin
				if (!rst) begin
					byte_interval_cnt_r <= MAX_CNT_NUM;				
				end
				else if (Byte_Synch_i == 1'b1) begin
					byte_interval_cnt_r <= 8'h00;
				end
				else if (BaudSig_i == 1'b1) begin
					if (byte_interval_cnt_r == MAX_CNT_NUM) begin
						byte_interval_cnt_r <= byte_interval_cnt_r;
					end
					else begin
						byte_interval_cnt_r <= byte_interval_cnt_r + 1'b1;
					end
				end
				else begin
					byte_interval_cnt_r <= byte_interval_cnt_r;
				end
			end
		// frame recognize
			always @(posedge clk or negedge rst) begin
				if (rst) begin
					new_frame_sig_r <= NEW_FRAME;				
				end
				else if ((BaudSig_i == 1'b1) && (byte_interval_cnt_r >= FRAME_BYTE_INTERVAL) ) begin
					new_frame_sig_r <= NEW_FRAME;
				end
				else begin
					new_frame_sig_r <= NOT_FINISH;
				end
			end 		
		// byte number counter
			always @(posedge clk or negedge rst) begin
				if (!rst) begin
					byte_num_cnt_r <= 8'd0;		
				end
				else if (state_r == IDLE) begin
					if (new_frame_sig_r == NEW_FRAME) begin
						byte_num_cnt_r <= 8'd0;
					end
					else begin
						byte_num_cnt_r <= byte_num_cnt_r;
					end
				end
				else if (state_r == FIFO) begin
					if (parity_result_r == PAR_TRUE) begin
						byte_num_cnt_r <= byte_num_cnt_r + 1'b1;
					end
					else begin
						byte_num_cnt_r <= byte_num_cnt_r;
					end
				end
				else begin
					byte_num_cnt_r <= byte_num_cnt_r;
				end
			end
		// shift register of n_rd_frame_fifo_i
			always @(posedge clk or negedge rst) begin
				if (!rst) begin
					rd_frame_fifo_shift_r <= 3'b111;				
				end
				else begin
					rd_frame_fifo_shift_r <= {rd_frame_fifo_shift_r[1:0] , n_rd_frame_fifo_i};
				end
			end
		// n_rd_frame_fifo_r fresh
			always @(posedge clk or negedge rst) begin
				if (!rst) begin
					n_rd_frame_fifo_r <= 1'b1;				
				end
				else if (falling_edge_rd_fifo_w == 1'b1) begin
					n_rd_frame_fifo_r <= 1'b0;
				end
				else begin
					if (state_r != FIFO) begin  // FIFO state the rd sig is locked 
						n_rd_frame_fifo_r <= 1'b1;
					end
					else begin
						n_rd_frame_fifo_r <= n_rd_frame_fifo_r;
					end
				end
			end
		// frame number counter 
			always @(posedge clk or negedge rst) begin
				if (!rst) begin
					frame_num_cnt_r <= 4'd0;				
				end
				else if (state_r == IDLE) begin
					if ((new_frame_sig_r == NEW_FRAME) && (byte_num_cnt_r != 8'd0)) begin  //
						if (frame_num_cnt_r >= 4'd4) begin
							frame_num_cnt_r <= 4'd4;
						end
						else begin
							frame_num_cnt_r <= frame_num_cnt_r + 1'b1;
						end
					end
					else if ((n_rd_frame_fifo_r == 1'b0) && (frame_num_cnt_r != 4'd0)) begin
						frame_num_cnt_r <= frame_num_cnt_r - 1'b1;
					end
					else begin
						frame_num_cnt_r <= frame_num_cnt_r;
					end
				end
				else begin
					if ((n_rd_frame_fifo_r == 1'b0) && (frame_num_cnt_r != 4'd0)) begin
						frame_num_cnt_r <= frame_num_cnt_r - 1'b1;
					end
					else begin
						frame_num_cnt_r <= frame_num_cnt_r;
					end
				end
			end
		// fram information buffer fresh
			always @(posedge clk or negedge rst) begin
				if (!rst) begin
					frame0_info_r <= 28'd0;
					frame1_info_r <= 28'd0;
					frame2_info_r <= 28'd0;
					frame3_info_r <= 28'd0;		
				end
				else if (state_r == IDLE) begin  // in IDLE state the system finds the byte interval over the limit
					if ((new_frame_sig_r == NEW_FRAME) && (byte_num_cnt_r != 8'd0)) begin
						if (frame_num_cnt_r == 4'd0) begin
							frame0_info_r <= {t0_100us_stamp_r,t0_ms_stamp_r,byte_num_cnt_r};
							frame1_info_r <= 28'd0;
							frame2_info_r <= 28'd0;
							frame3_info_r <= 28'd0;	
						end
						else if (frame_num_cnt_r == 4'd1) begin
							frame0_info_r <= frame0_info_r;
							frame1_info_r <= {t0_100us_stamp_r,t0_ms_stamp_r,byte_num_cnt_r};
							frame2_info_r <= 28'd0;
							frame3_info_r <= 28'd0;	
						end
						else if (frame_num_cnt_r == 4'd2) begin
							frame0_info_r <= frame0_info_r;
							frame1_info_r <= frame1_info_r;
							frame2_info_r <= {t0_100us_stamp_r,t0_ms_stamp_r,byte_num_cnt_r};
							frame3_info_r <= 28'd0;	
						end
						else if (frame_num_cnt_r == 4'd3) begin // fifo is not full
							frame0_info_r <= frame0_info_r;
							frame1_info_r <= frame1_info_r;
							frame2_info_r <= frame2_info_r;
							frame3_info_r <= {t0_100us_stamp_r,t0_ms_stamp_r,byte_num_cnt_r};	
						end
						else begin   // when fifo if full
							frame0_info_r <= frame1_info_r;
							frame1_info_r <= frame2_info_r;
							frame2_info_r <= frame3_info_r;
							frame3_info_r <= {t0_100us_stamp_r,t0_ms_stamp_r,byte_num_cnt_r};
						end
					end
					else if ((n_rd_frame_fifo_r == 1'b0) && (frame_num_cnt_r != 4'd0)) begin  // ouput frame info
						frame0_info_r <= frame1_info_r;
						frame1_info_r <= frame2_info_r;
						frame2_info_r <= frame3_info_r;
						frame3_info_r <= 28'd0;						
					end
					else begin
						frame0_info_r <= frame0_info_r;
						frame1_info_r <= frame1_info_r;
						frame2_info_r <= frame2_info_r;
						frame3_info_r <= frame3_info_r;
					end
				end
				else begin
					if ((n_rd_frame_fifo_i == 1'b0) && (frame_num_cnt_r != 4'd0)) begin
						frame0_info_r <= frame1_info_r;
						frame1_info_r <= frame2_info_r;
						frame2_info_r <= frame3_info_r;
						frame3_info_r <= 28'd0;
					end
					else begin
						frame0_info_r <= frame0_info_r;
						frame1_info_r <= frame1_info_r;
						frame2_info_r <= frame2_info_r;
						frame3_info_r <= frame3_info_r;
					end
				end
			end
		// frame_info_output_r frame info fifo output port
			always @(posedge clk or negedge rst) begin
				if (!rst) begin
					frame_info_output_r <= 28'd0;				
				end
				else if (state_r == IDLE) begin
					if ((new_frame_sig_r == NEW_FRAME) && (byte_num_cnt_r != 8'd0)) begin  //
						frame_info_output_r <= frame_info_output_r;
					end
					else if ((n_rd_frame_fifo_r == 1'b0) && (frame_num_cnt_r != 4'd0)) begin
						frame_info_output_r <= frame0_info_r;
					end
					else begin
						frame_info_output_r <= frame_info_output_r;
					end
				end
				else begin
					if ((n_rd_frame_fifo_r == 1'b0) && (frame_num_cnt_r != 4'd0)) begin
						frame_info_output_r <= frame0_info_r;
					end
					else begin
						frame_info_output_r <= frame_info_output_r;
					end
				end
			end
		// parity error number counter
			always @(posedge clk or negedge rst) begin
				if (!rst) begin
					parity_error_num_r <= 8'd0;				
				end
				else if ((state_r == FIFO) && (parity_result_r == PAR_FALSE)) begin
					parity_error_num_r <= parity_error_num_r + 1'b1;
				end
				else begin
					parity_error_num_r <= parity_error_num_r;
				end
			end
endmodule