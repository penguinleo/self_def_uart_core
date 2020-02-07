// -----------------------------------------------------------------------------
// Copyright (c) 2014-2020 All rights reserved
// -----------------------------------------------------------------------------
// Author : Javen Peng, pengjaven@gmail.com
// File   : TimeStampModule.v
// Create : 2020-01-31 16:42:10
// Revise : 2020-01-31 16:42:10
// Editor : sublime text3, tab size (4)
// Comment: This module generate the time stamp for the data receving
// 
// Input Signal List:
//      1   :   clk, the system input clock signal, the frequency is greater than 40MHz
//      2   :   rst, the system reset signal, the module should be reset asynchronously,
//                   and must be released synchronously with the clock;
//      3   :   
// Output Signal List:
//      1   :   
// Note 
// -----------------------------------------------------------------------------
module TimeStampModule(
    input   clk,
    input   rst,
    // the 10Mhz signal 
        input   p_sig_10MHz_i,
    // the GNSS PPS signal 
        input   p_sig_pps_i,
    // the time stamp
        output [3:0]    acqurate_stamp_o,
        output [11:0]   millisecond_stamp_o,
        output [31:0]   second_stamp_o
    );
    // register definition
        // counter regsiter
            reg [11:0]  divider_10khz_r;    // divide the input 10Mhz signal to generate the 0.1ms signal
            reg         sig_10KHz_r;        // the 10KHz signal, to 
            reg [3:0]   divider_1khz_r;     // 0.1ms acquracy
            reg [11:0]  divider_1hz_r;      // ms
            reg [31:0]  second_cnt_r;     // accumulated second
        // shift register for the input signal detect
            reg [2:0]   shift_10MHz_r;      // the shift register for the input signal p_sig_10MHz_i
            reg [2:0]   shift_pps_r;        // the shift register for the input singal p_sig_pps_i
    // wire signal definition
        // the signal rising edge detect
            wire    rising_edge_sig_10MHz_w;
            wire    rising_edge_sig_pps_w;
        // the divider output 
            wire    sig_10KHz_w;
            wire    sig_1KHz_w;
            wire    sig_1Hz_w;
    // parameter definition
            parameter   PERIOD_10KHZ            = 12'd999; 
            parameter   PERIOD_1KHZ             = 4'd9;
            parameter   PERIOD_1HZ              = 12'd999;
    // wire assign part
        // output signal assign
            assign acqurate_stamp_o         = divider_1khz_r;
            assign millisecond_stamp_o      = divider_1hz_r;
            assign second_stamp_o           = second_cnt_r;
        // the rising signal
            assign rising_edge_sig_10MHz_w  = !shift_10MHz_r[2] & shift_10MHz_r[1];
            assign rising_edge_sig_pps_w    = !shift_pps_r[2] & shift_pps_r[1];
        // the divider out
            assign sig_10KHz_w  = (divider_10khz_r == PERIOD_10KHZ) & (rising_edge_sig_10MHz_w == 1'b1);
            assign sig_1KHz_w   = (divider_1khz_r == PERIOD_1KHZ) & (sig_10KHz_r == 1'b1);
            assign sig_1Hz_w    = (divider_1hz_r == PERIOD_1HZ) & (sig_10KHz_r == 1'b1);
    // input signal synchronize, shift register
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                shift_10MHz_r   <= 3'b000;
                shift_pps_r     <= 3'b000;        
            end
            else begin
                shift_10MHz_r   <= {shift_10MHz_r[1:0], p_sig_10MHz_i};
                shift_pps_r     <= {shift_pps_r[1:0], p_sig_pps_i};
            end
        end
    // 10MHz signal divider 
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                divider_10khz_r   <= 12'd0;
            end
            else if (rising_edge_sig_10MHz_w == 1'b1) begin
                if (divider_10khz_r == PERIOD_10KHZ) begin
                    divider_10khz_r <= 12'd0;
                end
                else begin
                    divider_10khz_r <= divider_10khz_r + 1'b1;
                end
            end
            else if (rising_edge_sig_pps_w == 1'b1) begin
                divider_10khz_r <= 12'd0;
            end
            else begin
                divider_10khz_r <= divider_10khz_r;
            end
        end
    // 10KHz signal
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                sig_10KHz_r <= 1'b0;
            end
            else begin
                sig_10KHz_r <= sig_10KHz_w;
            end
        end
    // divider_1khz_r 
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                divider_1khz_r    <= 4'd0;                
            end
            else if (sig_10KHz_r == 1'b1) begin
                if (divider_1khz_r == PERIOD_1KHZ) begin
                    divider_1khz_r <= 4'd0;
                end
                else begin
                    divider_1khz_r <= divider_1khz_r + 1'b1;
                end
            end
            else if (rising_edge_sig_pps_w == 1'b1) begin
                divider_1khz_r <= 4'd0;
            end
            else begin
                divider_1khz_r <= divider_1khz_r;
            end
        end
    // divider_1hz_r
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                divider_1hz_r <= 12'h000;                
            end
            else if (sig_1KHz_w == 1'b1) begin
                if (divider_1hz_r == PERIOD_1HZ) begin
                    divider_1hz_r <= 12'd0;
                end
                else begin
                    divider_1hz_r <= divider_1hz_r + 1'b1;
                end
            end
            else if (rising_edge_sig_pps_w == 1'b1) begin
                divider_1hz_r <= 12'd0;
            end
            else begin
                divider_1hz_r <= divider_1hz_r;
            end
        end
    // second_cnt_r fresh
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                second_cnt_r <= 32'd0;                
            end
            else if (sig_1Hz_w == 1'b1) begin
                second_cnt_r <= second_cnt_r + 1'b1;
            end
        end

endmodule