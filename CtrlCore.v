// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Javen   penguinleo@163.com
// File   : CtrlCore.v
// Create : 2019-12-17 15:19:59
// Revise : 2019-12-17 15:19:59
// Editor : sublime text3, tab size (4)
// Comment: this module is designed to control the uart port.
//          The uart module is designed a compensate method to implement an acqurate bit width
//          I call this method acquisite period compensate method.
//          In further, the bit width compensate method would be introduced to reduce the accumulate
//          error in the last bit of a byte during transmitte.
//          Up module:
//              UartCore
//          Sub module:
//              None
// Input Signal List:
//      1   |   clk                 :   clock signal
//      2   |   rst                 :   reset signal
//      3   |   p_We_i              :   control register write enable signal, positive effective.
//      4   |   CtrlReg1_i          :   Control parameter register,
//                                      Bit 7 controls the big end or little end format;
//                                      Bit 6 controls the parity function, 1-enable,0-disable;
//                                      Bit 5 choose the parity method, 0-even,1-odd;
//                                      Bit 4 reserved bit;
//                                      Bit 3 ~ 0 are the high 4 bits of acquisite period control reg;
//      6   |   BitCompensateMethod :   Compensation control register
//                                      Bit 7 ~ 4 are the number of round-up acquisite period in a bit time;
//                                      Bit 3 ~ 0 are the number of round-down period in a bit time;
//                                      The acquisite period control reg is the round-down period data.
// Output Signal List:      
//      1   |   BaudRateGen_o         :   The acquisite perid control register output. This period is the round-down
//                                      period. This data is sent to the BaudGenerate module to generate the AcqSig
//      2   |   BitCompensation_o   :   The compensate control register, which would help the BaudGenerate module
//                                      reduce the bit width error less than a system clk;
//                                      Bit 7 ~ 4 are the number of round-up acquisite period in a bit time
//                                      Bit 3 ~ 0 are the number of round-down acquisite period in a bit time
//      3   |   AcqNumPerBit_o      :   The number to acquisite opperation in a bit time. This data is the sum of
//                                      the BitCompensation_o[7:4] + BitCompensation_o[3:0]
//      4   |   p_ParityEnable_o    :   The parity enable signal output for other uart submodules, 1-enable,0-disable;
//      5   |   p_BigEnd_o          :   The format control signal output for other uart submodules, 0-even,1-odd;
//      6   |   ParityMethod_o      :   The parity method select signal output for other uart submodule, 0-even,1-odd;
// Note:  
// 
// -----------------------------------------------------------------------------   
module CtrlCore(
    input   clk,
    input   rst,
    // write enable
        input           p_We_i,
    // input control register
        input [7:0]     EnCodeCtrl_i,
        input [7:0]     BaudRateGenHigh_i,
        input [7:0]     BaudRateGenLow_i,
        input [7:0]     BitCompensateMethod,
    // interupte control register
        input [7:0]     InterrputCtrl_i,
        input [7:0]     FifoInterrputNumHigh_i,
        input [7:0]     FifoInterrputNumLow_i,
    // output control register
        output [15:0]   BaudRateGen_o,
        output [7:0]    BitCompensation_o,
        output [3:0]    AcqNumPerBit_o,
    // output protocol control register
        output          p_ParityEnable_o,
        output          p_BigEnd_o,
        output          ParityMethod_o
    );
    // register 
        reg [15:0]  BaudRateGen_r;
        reg [7:0]   BitCompensation_r;
        reg         p_ParityEnable_r;
        reg         p_BigEnd_r;
        reg         ParityMethod_r;
        reg [3:0]   AcqNumPerBit_r;
    // parameter
        // Default parameter
            parameter       DEFAULT_PERIOD      = 16'd20;
            parameter       DEFAULT_UP_TIME     = 4'd10;
            parameter       DEFAULT_DOWN_TIME   = 4'd5;
        // Parity Enable definition
            parameter ENABLE    = 1'b1;
            parameter DISABLE   = 1'b0;
        // Big end and littel end definition
            parameter BIGEND    = 1'b1;
            parameter LITTLEEND = 1'b0;
        // parity method definition
            parameter EVEN      = 1'b0;
            parameter ODD       = 1'b1;
    // assign
        assign BaudRateGen_o        = BaudRateGen_r;
        assign BitCompensation_o    = BitCompensation_r;
        assign p_ParityEnable_o     = p_ParityEnable_r;
        assign p_BigEnd_o           = p_BigEnd_r;
        assign ParityMethod_o       = p_ParityEnable_r;
        assign AcqNumPerBit_o       = AcqNumPerBit_r;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            BaudRateGen_r       <= DEFAULT_PERIOD;
            BitCompensation_r   <= {DEFAULT_UP_TIME,DEFAULT_DOWN_TIME};
            p_ParityEnable_r    <= ENABLE;
            p_BigEnd_r          <= LITTLEEND;
            ParityMethod_r      <= ODD;
            AcqNumPerBit_r      <= DEFAULT_UP_TIME + DEFAULT_DOWN_TIME;      
        end
        else if (p_We_i == 1'b1) begin
            BaudRateGen_r       <= {BaudRateGenHigh_i,BaudRateGenLow_i};
            BitCompensation_r   <= BitCompensateMethod;
            p_ParityEnable_r    <= EnCodeCtrl_i[6];
            p_BigEnd_r          <= EnCodeCtrl_i[7];
            ParityMethod_r      <= EnCodeCtrl_i[5];
            AcqNumPerBit_r      <= BitCompensateMethod[7:4] + BitCompensateMethod[3:0];
        end
        else begin
            BaudRateGen_r       <= BaudRateGen_r;
            BitCompensation_r   <= BitCompensation_r;
            p_ParityEnable_r    <= p_ParityEnable_r;
            p_BigEnd_r          <= p_BigEnd_r;
            ParityMethod_r      <= ParityMethod_r;
            AcqNumPerBit_r      <= AcqNumPerBit_r;
        end
    end
endmodule
