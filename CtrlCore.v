// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Javen   penguinleo@163.com
// File   : CtrlCore.v
// Create : 2019-12-17 15:19:59
// Revise : 2019-12-17 15:19:59
// Editor : sublime text3, tab size (4)
// Comment: this module is designed to ...
//          Up module:
//              xxxx.v
//          Sub module:
//              xxxx.v
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
