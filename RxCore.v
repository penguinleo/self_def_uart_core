// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Javen   penguinleo@163.com
// File   : RxCore.v
// Create : 2019-11-17 10:19:33
// Revise : 2019-11-17 10:19:34
// Editor : sublime text3, tab size (4)
// Comment: this module is designed to receive the serial data from rx wire
//          Up module:
//              UartCore
//          Sub module:
//              ShiftRegister_Rx        Serial to byte module
//              FIFO_Ver1               Fifo module
//              FSM_Rx                  State machine of rx core
//               
//          Input
//              clk :   clock signal
//              rst :   reset signal
//          Output
//              
// -----------------------------------------------------------------------------
module RxCore(
    input   clk,
    input   rst,
    // fifo control signal
        output [7:0]    data_o,
        input           n_rd_i,     // the fifo read signal
        output          p_empty_o,  // the fifo is empty
    // frame info rd control
    	input 			n_rd_frame_fifo_i,
    	output [27:0]	frame_info_o,
    // the baudsig from the baudrate generate module
        input           AcqSig_i,   // acquistion signal
        input 			BaudSig_i,
    // the rx core control signal
        input           p_ParityEnable_i,
        input           p_BigEnd_i,
        input           ParityMethod_i,
        input [3:0]     AcqNumPerBit_i,
    // time stamp input
		input [3:0]		acqurate_stamp_i,
		input [11:0]	millisecond_stamp_i,
		input [31:0]	second_stamp_i,    	
    // the error flag signal
    	output  [7:0]   ParityErrorNum_o,
        // output           p_BaudrateError_o,  // the Baudrate error
        // output           p_ParityError_o,    // the Parity error
    // the rx signal
        input           Rx_i            
    );
    // register definition
        // NONE
    // wire definition
        wire        Rx_Synch_w;
        wire        Bit_Synch_w;
        wire 		Byte_Synch_w;
        wire        p_ParityCalTrigger_w;
        wire [4:0]  State_w;
        wire [3:0]  BitCounter_w;
        wire [3:0]  BitWidthCnt_w;
        wire        ParityResult_w;
        wire [11:0] Byte_w;
        wire [7:0]  Data_w;
        wire [7:0]	ParityData_w;
        wire        n_we_w;
        wire        p_full_w;
        
    FSM_Rx StateMachine(
        .clk(clk),
        .rst(rst),
        .Rx_Synch_i(Rx_Synch_w),
        .Bit_Synch_i(Bit_Synch_w),
        .AcqSig_i(AcqSig_i),
        .p_ParityEnable_i(p_ParityEnable_i),
        // .p_ParityCalTrigger_o(p_ParityCalTrigger_w),
        .State_o(State_w),
        .BitCounter_o(BitCounter_w)
        );

    ShiftRegister_Rx ShiftReg(
        .clk(clk),
        .rst(rst),
        .AcqSig_i(AcqSig_i),
        .AcqNumPerBit_i(AcqNumPerBit_i),
        .Rx_i(Rx_i),
        .AcqNumPerBit_i(AcqNumPerBit_w),
        .State_i(State_w),
        .BitWidthCnt_o(BitWidthCnt_w),
        .ParityResult_i(ParityResult_w),
        .Byte_o(Byte_w),
        .Bit_Synch_o(Bit_Synch_w),
        .Byte_Synch_o(Byte_Synch_w).
        .Rx_Synch_o(Rx_Synch_w)
        );

    ParityGenerator ParityGenerator(
        .clk(clk),
        .rst(rst),
        // .p_BaudSig_i(p_BaudSig_i),
        .State_i(State_w),
        .p_ParityCalTrigger_i(p_ParityCalTrigger_w),
        // .BitCounter_i(BitCounter_w),
        .ParityMethod_i(ParityMethod_i),
        .Data_i(ParityData_w),          // Be Carefull, when trigger signal generate the byte data is low 8 bits
        .ParityResult_o(ParityResult_w)
        );

    ByteAnalyse ByteAnalyse(
      	.clk(clk),
		.rst(rst),
		.n_we_o(n_we_w),
		.data_o(Data_w),
		.p_full_i(p_full_w),
		.BaudSig_i(BaudSig_i),
		.byte_i(Byte_w),
		.Bit_Synch_i(Bit_Synch_w),
		.Byte_Synch_i(Byte_Synch_w),
		.State_i(State_w),
		.BitWidthCnt_i(BitWidthCnt_w),
		.acqurate_stamp_i(acqurate_stamp_i),
		.millisecond_stamp_i(millisecond_stamp_i),
		.second_stamp_i(second_stamp_i),
		.p_ParityEnable_i(p_ParityEnable_i),
		.p_BigEnd_i(p_BigEnd_i),
		.n_rd_frame_fifo_i(n_rd_frame_fifo_i),
		.frame_info_o(frame_info_o),
		.ParityCalData_o(ParityData_w),
		.p_ParityCalTrigger_o(p_ParityCalTrigger_w),
		.ParityResult_i(ParityResult_w),
		.ParityErrorNum_o(ParityErrorNum_w),
        );

    FIFO_ver1 #(.DEPTH(8'd128)) RxCoreFifo (
        .clk(clk),
        .rst(rst),
        .data_i(Data_w),
        .n_we_i(n_we_w),
        .n_re_i(n_rd_i),
        .data_o(data_o),
        .p_empty_o(p_empty_o),
        .p_full_o(p_full_w)
        );
    

endmodule