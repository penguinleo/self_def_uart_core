// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Javen   penguinleo@163.com
// File   : UartCore.v
// Create : 2019-12-17 15:17:15
// Revise : 2019-12-17 15:17:15
// Editor : sublime text3, tab size (4)
// Comment: this module is designed as the top module of the UART module. The module 
//          is built up by its submodules.
//          To realize the high precision of the bit width(baudrate), the bit compensation
//          method was introduced into the uart port. The accuracy of the bit width which 
//          send out by the module could be reduced under 1 system clock!
//          By the way, the uart core should work with the 40MHz system clock.
//          Up module:
//              ----
//          Sub module:
//              CtrlCore.v
//              TxCore.v
//              RxCore.v
// Input Signal List:
//      1   |   clk         :   clock signal
//      2   |   rst         :   reset signal
//      3   |   p_We_i      :   The control signal that the control parameters should enabled
//      4   |   CtrlReg1_i  :   The control register for the uart core. In this byte there are
//                              Bit7: the BigEnd or SmallEnd control bit, 1-Big End; 0-Small End.
//                              Bit6: the Parity Enable control bit, 1-Enable the parity function; 0-Disabled.
//                              Bit5: the Parity Method control bit, 0-EVEN parity; 1-ODD parity
//                              Bit4: Reserved
//                              Bit3~0: The high 4 bits for the acquisition signal cycle congtrol
//      5   |   CtrlReg2_i  :   The low 8 bits for the acquisition signal cycle control 
//      6   |   CtrlReg3_i  :   The compensation method for the baudrate signal.
//                              Bit7~4: The round up acquisition signal cycle numbers.
//                              Bit3:0: The round down acquisition signal cycle number.
//      7   |   n_rd_i      :   The read signal of the reveice fifo, which is better to be triggled 
//                              by the read access from the bus.
//      8   |   data_i      :   The write port of the transimit fifo.
//      9   |   n_we_i      :   The write signal of the transimit fifo, which is better to be triggled 
//                              by the write access from the bus.
//      10  |   Rx_i        :   The rx signal from the FPGA pin.
// Output Signal List:
//      1   |   data_o      :   The receive fifo output.
//      2   |   p_empty_o   :   The receive fifo empty flag, 1-empty, 0-something in the fifo to be read
//      3   |   p_full_o    :   The transimite fifo is full, 1-full, 0-not full.      
//      4   |   Tx_o        :   The tx output signal through the FPGA pin.
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
    // frame info 
        input           n_rd_frame_fifo_i,
        output [27:0]   frame_info_o,
    // rx fifo control signal
        output [7:0]    data_o,
        input           n_rd_i,     // the fifo read signal
        output          p_empty_o,  // the fifo is empty
    // tx fifo control signal
        input [7:0]     data_i,
        input           n_we_i,
        output          p_full_o,
    // time stamp input
        input [3:0]     acqurate_stamp_i,
        input [11:0]    millisecond_stamp_i,
        input [31:0]    second_stamp_i,     
    // the error flag signal
        output  [7:0]   ParityErrorNum_o,
    // Uart port
        input           Rx_i,
        output          Tx_o
    );

    wire [11:0] AcqPeriod_w;
    wire [7:0]  BitCompensation_w;
    wire [3:0]  AcqNumPerBit_w;
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
        .AcqNumPerBit_o(AcqNumPerBit_w),
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
        .n_rd_frame_fifo_i(n_rd_frame_fifo_i),
        .frame_info_o(frame_info_o),
        .AcqSig_i(AcqSig_w),
        .AcqNumPerBit_i(AcqNumPerBit_w),
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
