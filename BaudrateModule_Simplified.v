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
module BaudrateModule_Simplified(
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
        output          AcqSig_o,    //Rx port acquisite signal
        output          BaudSig_o    //Tx port singal frequency
    );
    // Register definition
        // input buffer
            reg     [11:0]  acq_period_down_r;              // the data is come from the AcqPeriod_i   
            reg     [11:0]  acq_period_up_r;                // the data is equal with AcqPeriod_i + 1
            reg     [3:0]   acq_up_time_limit_r;            // the period round up times, it is the PosCompensation_i[7:4]
            reg     [3:0]   acq_down_time_limit_r;          // the period round down times,it is the PosCompensation_i[3:0]
        // divider to generate the baudrate signal from the acquisition signal, the baud_divider_r = acq_num_counter_r + comp_num_counter_r
            reg     [11:0]  acq_period_limit_r;             // it is choosen from the acq_period_down_r and acq_period_up_r
            reg     [11:0]  acq_period_counter_r;           // the counter for the period 
            reg     [3:0]   acq_down_time_cnt_r;            // the divider for the baud sig, count the normal acq signal, Note this counter count down from the limit to zero 
            reg     [3:0]   acq_up_time_cnt_r;              // the divider for the baud sig, count the compensated acq signal,Note this counter count down from the limit to zero    
            reg             acqsig_r;                       // the register of acquisition signal, which only last 1 clock
            reg             baudsig_r;                      // the register of the baudrate signal, which only last 1 clock
        // Acquisition signal and Baudrate signal trigger
    // Wire logic definition
        // state logic 
            wire        Time2Reload_w;                  // the state machine trigger condition
        // the comparation of the acq_up_time_cnt_r and acq_down_time_cnt_r for the compensate algorithm
            wire        AcqUpNumberReachLimit_w;            // the acq_up_time_cnt_r has decreased to zero
            wire        AcqDownNumberReachLimit_w;          // the acq_down_time_cnt_r has decreased to zero 
            wire        AcqUpNumberLeftMore_w;              // determin the acquisition period width after first period
            wire        AcqUpNumberInitMore_w;              // determin the first acquisition period width
        // Some State trigger signal    
            wire        AcqRising_w;                        // the acq_period_counter_r reach the limit
            wire        BaudRising_w;                       // when round up time and round down time reach the limit 
            wire        AcqTimeUpSelected_w;                // the acq_period_counter_r should gain to equal with the acq_period_up_r
            wire        AcqNumberReload_w;                  // the acq_up_time_cnt_r and acq_down_time_cnt_r should return to their limit
        // Testwire
            wire [4:0]  Divivder_Cnt_w;
        // the 
    // Parameter definition
        // Default parameter
            parameter       DEFAULT_PERIOD      = 12'd20;
            parameter       DEFAULT_UP_TIME     = 4'd10;
            parameter       DEFAULT_DOWN_TIME   = 4'd5;
        // Byte width
            parameter       BYTEWIDTH   = 4'd10;       // the second compensated method define a byte width 
        // Bit Type Definition
            parameter       POSITIVE    = 1'b1;        // the compensated method made the bit a little over time than required bit time(baudrate)
            parameter       NEGATIVE    = 1'b0;        // the compensated method made the bit a little shorter than required bit time(baudrate)
        // The Round Up period and Round Down period
            parameter       UP_PERIOD   = 1'b1;
            parameter       DOWN_PERIOD = 1'b0;
        // The output signal level definition
            parameter       INVALID     = 1'b0;
            parameter       ACTIVE      = 1'b1;
    // Assign
        // State machine 
            assign Time2Reload_w    =   (acq_period_counter_r == 12'd0);
        // the comparation of the acq_up_time_cnt_r and acq_down_time_cnt_r
            assign AcqUpNumberReachLimit_w    = (acq_up_time_cnt_r == 4'd0);      // the register decrease to zero 
            assign AcqDownNumberReachLimit_w  = (acq_down_time_cnt_r == 4'd0);    // the register decrease to zero 
            assign AcqUpNumberLeftMore_w      = (acq_up_time_cnt_r > acq_down_time_cnt_r);
            assign AcqUpNumberInitMore_w      = (acq_up_time_limit_r > acq_down_time_limit_r);
        // the judge result combination of the comparation result     
            assign AcqRising_w          = (acq_period_counter_r == 12'd0);
            assign BaudRising_w         = AcqRising_w & (acq_up_time_cnt_r == 4'd0) & (acq_down_time_cnt_r == 4'd0);
            assign AcqTimeUpSelected_w  = (AcqUpNumberReachLimit_w & AcqDownNumberReachLimit_w & AcqUpNumberInitMore_w) 
                                        | (~AcqUpNumberReachLimit_w& AcqDownNumberReachLimit_w ) 
                                        | (~AcqUpNumberReachLimit_w&~AcqDownNumberReachLimit_w & AcqUpNumberLeftMore_w);
            assign AcqNumberReload_w    = AcqUpNumberReachLimit_w & AcqDownNumberReachLimit_w;
        // output signal assign
            assign AcqSig_o     = acqsig_r;
            assign BaudSig_o    = baudsig_r;
        // Test 
            assign Divivder_Cnt_w = acq_up_time_cnt_r + acq_down_time_cnt_r;
    // input data buffer opperation all register only available when the baud_en_r is disabled
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                acq_period_down_r           <= DEFAULT_PERIOD;
                acq_period_up_r             <= DEFAULT_PERIOD + 1'b1;
                acq_up_time_limit_r         <= DEFAULT_UP_TIME;
                acq_down_time_limit_r       <= DEFAULT_DOWN_TIME;
            end
            else if (BaudRising_w == 1'b1) begin  // only when the baudrate module is off
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
                acq_period_counter_r <= DEFAULT_PERIOD;
            end
            else if ((Time2Reload_w == 1'b1)) begin
                if (AcqTimeUpSelected_w == UP_PERIOD) begin
                    acq_period_counter_r <= acq_period_up_r;
                end
                else begin
                    acq_period_counter_r <= acq_period_down_r;
                end
            end
            else begin
                acq_period_counter_r <= acq_period_counter_r - 1'b1;
            end
        end 
    // the acq_up_time_cnt_r and acq_down_time_cnt_r fresh
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                acq_up_time_cnt_r   <= DEFAULT_UP_TIME;
                acq_down_time_cnt_r <= DEFAULT_DOWN_TIME;
            end
            else if (Time2Reload_w == 1'b1) begin
                if (AcqNumberReload_w == 1'b1) begin
                    acq_up_time_cnt_r   <= acq_up_time_limit_r;
                    acq_down_time_cnt_r <= acq_down_time_limit_r;
                end 
                else if (AcqTimeUpSelected_w == UP_PERIOD) begin
                    acq_up_time_cnt_r   <= acq_up_time_cnt_r - 1'b1;
                    acq_down_time_cnt_r <= acq_down_time_cnt_r;
                end
                else begin
                    acq_up_time_cnt_r   <= acq_up_time_cnt_r;
                    acq_down_time_cnt_r <= acq_down_time_cnt_r - 1'b1;
                end
            end
            else begin
                acq_up_time_cnt_r   <= acq_up_time_cnt_r;                   
                acq_down_time_cnt_r <= acq_down_time_cnt_r;                 
            end
        end
    // output register fresh
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                acqsig_r <= INVALID;              
            end
            else if (AcqRising_w == 1'b1) begin
                acqsig_r <= ACTIVE;
            end
            else begin
                acqsig_r <= INVALID;
            end
        end
    // baudrate signal generate
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                baudsig_r <= INVALID;                
            end
            else if (BaudRising_w == 1'b1) begin
                baudsig_r <= ACTIVE;
            end
            else begin
                baudsig_r <= INVALID;
            end
        end
endmodule

