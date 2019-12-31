// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Javen   penguinleo@163.com
// File   : BaudrateModule_Simplified.v
// Create : 2019-12-31 18:54:53
// Revise : 2019-12-31 18:54:53
// Editor : sublime text3, tab size (4)
// Comment: this module is designed to generate the baudrate signal and acquisition signal
//          which consider the bit width error compensation and ignore the byte compensat-
//          -ion. The byte compensation will be introduced into the system in next version.
//          The acquisition time in a bit period is the sum of PosCompensation_i[7:4] and 
//          PosCompensation_i[3:0].
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
module BaudrateModule(
    input               clk,            //System input clock signal
    input               rst,            //System reset signal
    // The Acquisition Parameter definition
        input   [11:0]  AcqPeriod_i,        //The acquisition period base on the system clk
    // The relationship between Acq and Baudrate
        input   [7:0]   BitCompensation_i,  //The compensation method, which result in bit width over limit, just put the minimum width error method! 
        // input   [7:0]   NegCompensation_i,  //The compensation method, which result in bit width below limit, reserved
    // The Byte compensation method
        // input   [7:0]   ByteCompensation_i, //The second level compensation method,which would made the byte more precision, this function is reserved
    // The input and output control signal
        input           BaudEn_i,    //Baudrate enable signal
        output          AcqSig_o,    //Rx port acquisite signal
        output          BaudSig_o    //Tx port singal frequency
    );
    // Register definition
        // input buffer
            reg     [11:0]  acq_period_down_r;              // the data is come from the AcqPeriod_i   
            reg     [11:0]  acq_period_up_r;                // the data is equal with AcqPeriod_i + 1
            reg     [3:0]   acq_up_time_limit_r;            // the period round up times, it is the PosCompensation_i[7:4]
            reg     [3:0]   acq_down_time_limit_r;          // the period round down times,it is the PosCompensation_i[3:0]
            reg             baud_en_r;
        // divider to generate the baudrate signal from the acquisition signal, the baud_divider_r = acq_num_counter_r + comp_num_counter_r
            reg     [11:0]  acq_period_limit_r;             // it is choosen from the acq_period_down_r and acq_period_up_r
            reg     [11:0]  acq_period_counter_r;           // the counter for the period 
            reg     [3:0]   acq_time_down_cnt_r;            // the divider for the baud sig, count the normal acq signal
            reg     [3:0]   acq_time_up_cnt_r;              // the divider for the baud sig, count the compensated acq signal   
            reg             acqsig_r;                       // the register of acquisition signal, which only last 1 clock
            reg             baudsig_r;                      // the register of the baudrate signal, which only last 1 clock
        // Acquisition signal and Baudrate signal trigger
            wire            AcqRising_w;                    // the acq_period_counter_r reach the limit
            wire            BaudRising_w;                   // when round up time and round down time reach the limit 
            wire            AcqTimeUpSelected_w;            // the acq_period_counter_r should gain to equal with the acq_period_up_r,
    // Parameter definition
        // Byte width
            parameter       BYTEWIDTH   = 4'd10;       // the second compensated method define a byte width 
        // Bit Type Definition
            parameter       POSITIVE    = 1'b1;        // the compensated method made the bit a little over time than required bit time(baudrate)
            parameter       NEGATIVE    = 1'b0;        // the compensated method made the bit a little shorter than required bit time(baudrate)
        // Enable Definition
            parameter       BAUD_ON     = 1'b1;
            parameter       BAUD_OFF    = 1'b0;
        // The divider between the baudrate sig and the acquisition sig
            parameter       BAUD_DIV    = 3'b111;
    // Assign
            assign AcqRising_w  = (acq_period_counter_r == acq_period_limit_r);
            assign BaudRising_w = AcqRising_w & (acq_time_up_cnt_r == acq_up_time_limit_r) & (acq_time_down_cnt_r == acq_down_time_limit_r);

    // the module enable signal
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                baud_en_r   <= BAUD_OFF;                
            end
            else begin
                baud_en_r   <= BaudEn_i;
            end
        end
    // input data buffer opperation all register only available when the baud_en_r is disabled
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                acq_period_down_r           <= 1'b1;
                acq_period_up_r             <= 1'b1;
                acq_up_time_limit_r         <= 1'b1;
                acq_down_time_limit_r       <= 1'b1;
            end
            else if (baud_en_r == BAUD_OFF) begin  // only when the baudrate module is off
                acq_period_down_r           <= AcqPeriod_i;
                acq_period_up_r             <= AcqPeriod_i + 1'b1;
                acq_up_time_limit_r         <= BitCompensation_i[7:4];
                acq_down_time_limit_r       <= BitCompensation_i[3:0];
            end
            else begin
                acq_period_down_r           <= acq_period_down_r;                    
                acq_period_up_r             <= acq_period_up_r;      
                acq_up_time_limit_r         <= acq_up_time_limit_r;  
                acq_down_time_limit_r       <= acq_down_time_limit_r;                
            end
        end
    // the acquisition period coutner
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                acq_period_counter_r <=                      
            end
            else if () begin
                
            end
        end 
endmodule

