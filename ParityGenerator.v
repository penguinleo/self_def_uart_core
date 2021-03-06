// -----------------------------------------------------------------------------
// Copyright (c) 2019-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author   :   Javen Peng, pengjaven@gmail.com
// File     :   ParityGenerator.v
// Create   :   2019-10-18 09:46:02
// Revise   :   2019-10-18 09:46:02
// Editor   :   sublime text3, tab size (4)
// Comment  :   This module is applied to generate the parity code for the uart.
// 
// 
// 
// Input Signal List:
//      1   :   clk, the system input clock signal, the frequency is greater than 40MHz
//      2   :   rst, the system reset signal, the module should be reset asynchronously,
//                   and must be released synchronously with the clock;
//      3   :   p_ParityCalTrigger_i, the trigger signal given by the FSM of the TX core and the shiftregister of the RX core
//                                      when the signal is setted, this module should give out the parity result 
//      6   :   ParityMethod_i, the parity method,0-even,1-odd
//      7   :   Data_i, the input data
// Output Signal List:
//      1   :   ParityResult_o, the parity calculate result.
// Note     2019-12-14
//              1   |   Prob1   |   The parity result calculate judgement is wrong, when using in the RxCore module! 
//                                  the parity result is freshed at the wrong time. 
//                                  According to the FSM of the TxCore the bit counter would keep
//                                  gainning until the state machine jump to parity or stop state, in other words in the
//                                  DATABITS state the bit counter would not be zero, except the first bit! Thus,
//                                  the parity result would be wrong.
//                                  This module is applied for TxCore only!
//              2   |   Ans1    |   The State_i and the BitCounter_i are removed from the module, instead the p_ParityCalTrigger_i
//                                  is introduced into the module to satisfy different requirement of Rx and Tx core
// -----------------------------------------------------------------------------
module ParityGenerator(
    input           clk,
    input           rst,
    // input           p_BaudSig_i,
    // input [4:0]     State_i,
    input           p_ParityCalTrigger_i,   // the trigger to start parity calculate
    // input [3:0]     BitCounter_i,
    // input           ParityEnable_i, 
    input           ParityMethod_i, 
    input [7:0]     Data_i, 
    output          ParityResult_o
    );
    // register definition 
        reg         parity_result_r;
    // wire definition
        wire        bit7_xor_bit6;      // first level
        wire        bit5_xor_bit4;
        wire        bit3_xor_bit2;
        wire        bit1_xor_bit0;
        wire        bit76_xor_bit54;    // second level
        wire        bit32_xor_bit10;
        wire        byte_xor;           // third level
    // parameter definition
        // state machine definition
            parameter INTERVAL  = 5'b0_0001;
            parameter STARTBIT  = 5'b0_0010;
            parameter DATABITS  = 5'b0_0100;
            parameter PARITYBIT = 5'b0_1000;
            parameter STOPBIT   = 5'b1_0000;
        // Bit name definition
            parameter BIT0      = 4'd0;
            parameter BIT1      = 4'd1;
            parameter BIT2      = 4'd2;
            parameter BIT3      = 4'd3;
            parameter BIT4      = 4'd4;
            parameter BIT5      = 4'd5;
            parameter BIT6      = 4'd6;
        // parity enable definition
            parameter ENABLE    = 1'b1;
            parameter DISABLE   = 1'b0;
        // parity method definition
            parameter EVEN      = 1'b0;
            parameter ODD       = 1'b1;
    // assign
        // xor calculate
            assign bit7_xor_bit6    = Data_i[7]         ^ Data_i[6];
            assign bit5_xor_bit4    = Data_i[5]         ^ Data_i[4] ;
            assign bit3_xor_bit2    = Data_i[3]         ^ Data_i[2] ;
            assign bit1_xor_bit0    = Data_i[1]         ^ Data_i[0] ;
            assign bit76_xor_bit54  = bit7_xor_bit6     ^ bit5_xor_bit4 ;
            assign bit32_xor_bit10  = bit3_xor_bit2     ^ bit1_xor_bit0 ;
            assign byte_xor         = bit76_xor_bit54   ^ bit32_xor_bit10 ;
            assign ParityResult_o   = parity_result_r;        
    // the parity result calculate
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                parity_result_r <= 1'b1;                
            end
            else if (p_ParityCalTrigger_i == 1'b1) begin
                if ( ParityMethod_i == EVEN) begin  // at the first bit ending time
                    parity_result_r <= byte_xor;
                end
                else begin // if ( ParityMethod_i == ODD)
                    parity_result_r <= ~byte_xor ;
                end
            end
            else begin
                parity_result_r <= parity_result_r;
            end
        end 
endmodule
