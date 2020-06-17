// -----------------------------------------------------------------------------
// Copyright (c) 2019-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author   :   Javen Peng, pengjaven@gmail.com
// File     :   TxCore.v
// Create   :   2019-10-02 10:14:49
// Revise   :   2019-10-02 10:14:49
// Editor   :   sublime text3, tab size (4)
// Comment  :   these module is consist of 4 modules. ShiftRegister, FIFO_ver1, 
//              ParityGenerator, multiplexer, FSM.
// 
//              ShiftRegister:      send out the parallel data bit by bit, the shife register
//                                  is controlled by the FSM module.
//              ParityGenerator:    generate the parity results, when the parity function is
//                                  enabled.
//              FSM:                The state machine of the tx core.
//              
//              FIFO_ver1:          The transmite fifo of the tx core, which could be reconfigered 
//                                  with maximum 512 bytes when instantiated.
// 
// Input Signal List:
//      1   :   clk,                The system input clock signal, the frequency is greater than 40MHz
//      2   :   rst,                The system reset signal, the module should be reset asynchronously,
//                                  and must be released synchronously with the clock;
//      3   :   data_i,             The input data that want to send through the uart;
//      4   :   n_we_i,             The write signal of the tramsmite fifo;
//      5   :   n_clr_i,            The fifo clear signal;    
//      6   :   p_BaudSig_i,        The baudrate signal which is generated by the Baud generate module.
//      7   :   p_BigEnd_i,         The big end is 1; little end is 0;
//      8   :   p_ParityEnable_i,   Parity enable is 1, disable is 0
//      9   :   ParityMethod_i,     The parity method,0-even,1-odd 
// Output Signal List:
//      1   :   p_full_o,           The fifo full signal;
//      2   :   Tx_o ,              The tx wire driver.     
// -----------------------------------------------------------------------------
module TxCore(
    input           clk,
    input           rst,
    // fifo control signal
        input [7:0] Data_i,
        input       n_We_i,
        input       n_Clr_i,
        input       p_Enable_i,
    // fifo status signal
        output      p_Full_o,
        output      p_Over_o,
        output      p_NearFull_o,
        output      p_Empty_o,
        output [15:0] bytes_in_fifo_o,
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
        wire            p_SendFinished_w;
    // parameter 
        // state machine definition
            parameter INTERVAL  = 5'b0_0001;
            parameter STARTBIT  = 5'b0_0010;
            parameter DATABITS  = 5'b0_0100;
            parameter PARITYBIT = 5'b0_1000;
            parameter STOPBIT   = 5'b1_0000;
        // fifo state definition
            parameter EMPTY     = 1'b1;
            parameter NONEMPTY  = 1'b0;
    // logic definition
        assign p_SendFinished_w = (State_w == STOPBIT) && (p_FiFoEmpty_w == EMPTY) && (p_BaudSig_i == 1'b1);
        assign p_SendFinished_o = p_SendFinished_w;
        // output 
            assign p_Empty_o    = p_FiFoEmpty_w;
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
        // .State_i(State_w),
        .p_ParityCalTrigger_i(p_ParityCalTrigger_w),
        // .BitCounter_i(BitCounter_w),
        .ParityMethod_i(ParityMethod_i),
        .Data_i(ShiftData_w),
        .ParityResult_o(ParityResult_w)
        );

    FIFO_ver2 #(
        .WIDTH(16'd16),
        .DEPTH(16'd4096)        
        ) TxCoreFifo (
        .clk(clk),
        .rst(rst),
        .data_i(data_i),
        .n_we_i(n_we_i),
        .n_re_i(n_FifoRe_w),
        .n_clr_i(n_clr_i),
        .data_o(FifoData_w),
        .bytes_in_fifo_o(bytes_in_fifo_o),
        .p_over_o(p_Over_o),
        .p_nearfull_o(p_NearFull_o),
        .p_empty_o(p_FiFoEmpty_w),
        .p_full_o(p_Full_o)
        );
endmodule
