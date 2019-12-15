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
		input 	[3:0]	BitWidthCnt_i,
	// the control register
		input 			p_ParityEnable_i,
		input 			p_BigEnd_i,
	// the error flag
		output 			p_ParityError_o
	);
	// register definition
		reg [7:0]		data_r;
		reg 			p_ParityError_r;
		reg 			n_we_r;
	// wire definition
		wire [7:0]		small_end_data_w;
		wire [7:0]		big_end_data_w;
	// parameter definition
		// Receiving state machine definition  
            parameter   IDLE        = 5'b0_0001;   
            parameter   STARTBIT    = 5'b0_0010;
            parameter   DATABITS    = 5'b0_0100;
            parameter   PARITYBIT   = 5'b0_1000;
            parameter   STOPBIT     = 5'b1_0000;
        // error definition
            parameter   WRONG       = 1'b1;
            parameter   RIGHT       = 1'b0;
        // Big end and littel end definition
            parameter BIGEND    = 1'b1;
            parameter LITTLEEND = 1'b0;
        // bit acquisite location
        	parameter   ACQSITION_POINT 	= 4'd7;
        	parameter 	PARITY_JUDGE_POINT 	= ACQSITION_POINT + 1'b1; 
        	parameter 	DATA_POINT 			= PARITY_JUDGE_POINT + 1'b1;
        	parameter 	FIFO_POINT			= DATA_POINT + 1'b1;	
    // wire assign
    	assign small_end_data_w = {
    								byte_i[0],byte_i[1],byte_i[2],byte_i[3],
    								byte_i[4],byte_i[5],byte_i[6],byte_i[7]
    							};
    	assign big_end_data_w = {
    								byte_i[7],byte_i[6],byte_i[5],byte_i[4],
    								byte_i[3],byte_i[2],byte_i[1],byte_i[0]
    							};
    	assign p_ParityError_o = p_ParityError_r;
    	assign data_o = data_r;
    	assign n_we_o = n_we_r;
    // p_ParityError_r fresh 
    	always @(posedge clk or negedge rst) begin
    		if (!rst) begin
    			p_ParityError_r <= RIGHT;    			
    		end
    		else if ((State_i == PARITYBIT) && (BitWidthCnt_i == PARITY_JUDGE_POINT)) begin
    			p_ParityError_r <=  p_ParityEnable_i & (byte_i[0] ^ byte_i[1]);
    		end
    		else if ((State_i == IDLE)||(State_i == STARTBIT)||(State_i == DATABITS)) begin
    			p_ParityError_r <= RIGHT;
    		end
    		else begin
    			p_ParityError_r <= p_ParityError_r;
    		end
    	end
    // data_r register fresh
		always @(posedge clk or negedge rst) begin
			if (!rst) begin
				data_r	<= 	8'h00;			
			end
			else if (State_i == DATABITS && BitWidthCnt_i == DATA_POINT) begin
				if (p_BigEnd_i == BIGEND) begin
					data_r <= big_end_data_w;    // @DATABITS time the shiftregister low 8 bits is the data bits!
				end
				else begin
					data_r <= small_end_data_w;
				end
			end
			else if ((State_i == STARTBIT) || (State_i == IDLE)) begin
				data_r <= 8'h00
			end
			else begin
				data_r <= data_r;
			end
		end
	// n_we_r register fresh
		always @(posedge clk or negedge rst) begin
			if (!rst) begin
				n_we_r <= 1'b1;				
			end
			else if () begin
				
			end
		end
endmodule
