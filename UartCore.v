// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Javen   penguinleo@163.com
// File   : UartCore.v
// Create : 2019-12-17 15:17:15
// Revise : 2019-12-17 15:17:15
// Editor : sublime text3, tab size (4)
// Comment: this module is designed as the top module of the UART module
//          Up module:
//              ----
//          Sub module:
//              CtrlCore.v
//              TxCore.v
//              RxCore.v
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
module UartCore(
    input   clk,
    input   rst,
    // write enable & control register
        input           p_We_i,
        input [7:0]     CtrlReg1_i,
        input [7:0]     CtrlReg2_i,
        input [7:0]     CtrlReg3_i,
    // rx fifo control signal
        output [7:0]    data_o,
        input           n_rd_i,     // the fifo read signal
        output          p_empty_o,  // the fifo is empty
    // tx fifo control signal
        input [7:0]     data_i,
        input           n_we_i,
        output          p_full_o,
    // Uart port
        input           Rx_i,
        output          Tx_o
    );

    wire [11:0] AcqPeriod_w;
    wire [7:0]  BitCompensation_w;
    wire        p_ParityEnable_w;
    wire        p_BigEnd_w;
    wire        ParityMethod_w; 
    wire        AcqSig_w;
    wire        BaudSig_w;

    CtrlCore ControlCore(
        .clk(clk),
        .rst(rst),
        .p_We_i(p_We_i),
        .CtrlReg1_i(CtrlReg1_i),
        .CtrlReg2_i(CtrlReg2_i),
        .CtrlReg3_i(CtrlReg3_i),
        .AcqPeriod_o(AcqPeriod_w),
        .BitCompensation_o(BitCompensation_w),
        .p_ParityEnable_o(p_ParityEnable_w),
        .p_BigEnd_o(p_BigEnd_w),
        .ParityMethod_o(ParityMethod_w)
    );

    BaudrateModule_Simplified BaudGen(
        .clk(clk),
        .rst(rst),
        .AcqPeriod_i(AcqPeriod_w),
        .BitCompensation_i(BitCompensation_w),
        .AcqSig_o(AcqSig_w),
        .BaudSig_o(BaudSig_w)
    );

    RxCore RxCore(
        .clk(clk),
        .rst(rst),
        .data_o(data_o),
        .n_rd_i(n_rd_i),
        .p_empty_o(p_empty_o),
        .AcqSig_i(AcqSig_w),
        .p_ParityEnable_i(p_ParityEnable_w),
        .p_BigEnd_i(p_BigEnd_w),
        .ParityMethod_i(ParityMethod_w),
        // .p_BaudrateError_o(),
        // .p_ParityError_o(),
        .Rx_i(Rx_i)
    );

    TxCore TxCore(
        .clk(clk),
        .rst(rst),
        .data_i(data_i),
        .n_we_i(n_we_i),
        .p_full_o(p_full_o),
        .p_BaudSig_i(BaudSig_w),
        .p_ParityEnable_i(p_ParityEnable_w),
        .p_BigEnd_i(p_BigEnd_w),
        .ParityMethod_i(ParityMethod_w),
        .Tx_o(Tx_o) 
    );


endmodule
