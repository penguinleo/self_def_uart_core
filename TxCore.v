// -----------------------------------------------------------------------------
// Copyright (c) 2019-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author   :   Javen Peng, pengjaven@gmail.com
// File     :   TxCore.v
// Create   :   2019-10-02 10:14:49
// Revise   :   2019-10-02 10:14:49
// Editor   :   sublime text3, tab size (4)
// Comment  :   these module is consist of 4 modules. Shift register, FIFO module, 
//              parity generator, multiplexer, FSM.
//              ShiftRegister: send out the parallel data bit by bit
//              parity generator: generate the parity results
// 
// 
// Input Signal List:
//      1   :   clk, the system input clock signal, the frequency is greater than 40MHz
//      2   :   rst, the system reset signal, the module should be reset asynchronously,
//                   and must be released synchronously with the clock;
//      3   :   data_i, the input data that want to send through the uart;
//      4   :   n_we_i, The write signal of the fifo;
//      5   :   p_full_o, the fifo full signal;
//      6   :   p_BaudSig_i, the baudrate signal
//      7   :   p_BigEnd_i, the big end is 1; little end is 0;
//      8   :   p_ParityEnable_i, parity enable is 1, disable is 0
//      9   :   ParityMethod_i, the parity method,0-even,1-odd 
// Output Signal List:
//      
// 
// -----------------------------------------------------------------------------
module TxCore(
    input           clk,
    input           rst,
    // fifo control signal
        input [7:0] data_i,
        input       n_we_i,
        output      p_full_o,
    // the baudsig from the baudrate module
        input           p_BaudSig_i,
    // the tx core control signal
        input           p_ParityEnable_i,
        input           p_BigEnd_i,
        input           ParityMethod_i,
    // the tx signal
        output          Tx_o
    );
    // register definition
        //None
    // wire definition
        wire    [4:0]   State_w;
        wire    [3:0]   BitCounter_w;
        wire            p_ParityCalTrigger_w;
        wire    [7:0]   ShiftData_w;
        wire    [7:0]   FifoData_w;
        wire            ParityResult_w;
        wire            p_FiFoEmpty_w;
        wire            n_FifoRe_w;
    FSM StateMachine(
        .clk(clk),
        .rst(rst),
        .p_BaudSig_i(p_BaudSig_i),
        .p_FiFoEmpty_i(p_FiFoEmpty_w),
        .ParityEnable_i(p_ParityEnable_i),
        .p_ParityCalTrigger_o(p_ParityCalTrigger_w),
        .State_o(State_w),
        .BitCounter_o(BitCounter_w)
        );
    
    ShiftRegister ShiftReg(
        .clk(clk),
        .rst(rst),
        .p_BaudSig_i(p_BaudSig_i),
        .State_i(State_w),
        .BitCounter_i(BitCounter_w),
        .n_FifoRe_o(n_FifoRe_w),
        .FifoData_i(FifoData_w),
        .p_FiFoEmpty_i(p_FiFoEmpty_w),
        .p_BigEnd_i(p_BigEnd_i),
        .ParityResult_i(ParityResult_w),
        .ShiftData_o(ShiftData_w),
        .SerialData_o(Tx_o)
        );

    ParityGenerator ParityGenerator(
        .clk(clk),
        .rst(rst),
        // .p_BaudSig_i(p_BaudSig_i),
        .State_i(State_w),
        .p_ParityCalTrigger_i(p_ParityCalTrigger_w)
        // .BitCounter_i(BitCounter_w),
        .ParityMethod_i(ParityMethod_i),
        .Data_i(ShiftData_w),
        .ParityResult_o(ParityResult_w)
        );

    FIFO_ver1 #(.DEPTH(8'd32)) TxCoreFifo (
        .clk(clk),
        .rst(rst),
        .data_i(data_i),
        .n_we_i(n_we_i),
        .n_re_i(n_FifoRe_w),
        .data_o(FifoData_w),
        .p_empty_o(p_FiFoEmpty_w),
        .p_full_o(p_full_o)
        );
endmodule
