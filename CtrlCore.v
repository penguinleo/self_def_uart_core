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
//      5   |   CtrlReg2_i          :   This byte is the low 8 bits of the acquisite period control reg;
//      6   |   CtrlReg3_i          :   Compensation control register
//                                      Bit 7 ~ 4 are the number of round-up acquisite period in a bit time;
//                                      Bit 3 ~ 0 are the number of round-down period in a bit time;
//                                      The acquisite period control reg is the round-down period data.
// Output Signal List:      
//      1   |   AcqPeriod_o         :   The acquisite perid control register output. This period is the round-down
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
        input [7:0]     CtrlReg1_i,
        input [7:0]     CtrlReg2_i,
        input [7:0]     CtrlReg3_i,
    // output control register
        output [11:0]   AcqPeriod_o,
        output [7:0]    BitCompensation_o,
        output [3:0]    AcqNumPerBit_o,
    // output protocol control register
        output          p_ParityEnable_o,
        output          p_BigEnd_o,
        output          ParityMethod_o
    );
    // register 
        reg [11:0]  AcqPeriod_r;
        reg [7:0]   BitCompensation_r;
        reg         p_ParityEnable_r;
        reg         p_BigEnd_r;
        reg         ParityMethod_r;
        reg [3:0]   AcqNumPerBit_r;
    // parameter
        // Default parameter
            parameter       DEFAULT_PERIOD      = 12'd20;
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
        assign AcqPeriod_o          = AcqPeriod_r;
        assign BitCompensation_o    = BitCompensation_r;
        assign p_ParityEnable_o     = p_ParityEnable_r;
        assign p_BigEnd_o           = p_BigEnd_r;
        assign ParityMethod_o       = p_ParityEnable_r;
        assign AcqNumPerBit_o       = AcqNumPerBit_r;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            AcqPeriod_r         <= DEFAULT_PERIOD;
            BitCompensation_r   <= {DEFAULT_UP_TIME,DEFAULT_DOWN_TIME};
            p_ParityEnable_r    <= ENABLE;
            p_BigEnd_r          <= LITTLEEND;
            ParityMethod_r      <= ODD;
            AcqNumPerBit_r      <= DEFAULT_UP_TIME + DEFAULT_DOWN_TIME;      
        end
        else if (p_We_i == 1'b1) begin
            AcqPeriod_r         <= {CtrlReg1_i[3:0],CtrlReg2_i};
            BitCompensation_r   <= CtrlReg3_i;
            p_ParityEnable_r    <= CtrlReg1_i[6];
            p_BigEnd_r          <= CtrlReg1_i[7];
            ParityMethod_r      <= CtrlReg1_i[5];
            AcqNumPerBit_r      <= CtrlReg3_i[7:4] + CtrlReg3_i[3:0];
        end
        else begin
            AcqPeriod_r         <= AcqPeriod_r;
            BitCompensation_r   <= BitCompensation_r;
            p_ParityEnable_r    <= p_ParityEnable_r;
            p_BigEnd_r          <= p_BigEnd_r;
            ParityMethod_r      <= ParityMethod_r;
            AcqNumPerBit_r      <= AcqNumPerBit_r;
        end
    end
endmodule
