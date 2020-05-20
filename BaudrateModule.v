// -----------------------------------------------------------------------------
// Copyright (c) 2019-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author   :   Javen Peng, pengjaven@gmail.com
// File     :   BaudrateModule.v
// Create   :   2019-08-22 16:58:57
// Revise   :   2019-08-22 16:58:57
// Editor   :   sublime text3, tab size (4)
// Comment  :   This module input the baudrate setting and clock signal,
//              send out the baudrate.
// Input Signal List:
//      1   :   clk, the system input clock signal, the frequency is greater than 40MHz
//      2   :   rst, the system reset signal, the module should be reset asynchronously,
//                   and must be released synchronously with the clock;
//      3   :   Divisor_i, the divisor register, the baudrater generator is based on 
//                           the value.
//      4   :   BaudEn_i, The baudrate enable signal. To reduce the power consumption
// Output Signal List:
//      1   :   BaudSig_o, the baudrate signal, positive pulse, the pulse width is a clk
//      2   :   AcqSig_o, the acquisition signal for the RX port, the frequency is 8 times of BaudSig_o.
// -----------------------------------------------------------------------------
module BaudrateModule(
    input               clk,            //System input clock signal
    input               rst,            //System reset signal
    // The Acquisition Parameter definition
        input   [12:0]  AcqPeriod_i,        //The acquisition period base on the system clk
    // The relationship between Acq and Baudrate
        input   [7:0]   PosCompensation_i,  //The compensation method, which result in bit width over limit
        input   [7:0]   NegCompensation_i,  //The compensation method, which result in bit width below limit
    // The Byte compensation method
        input   [7:0]   ByteCompensation_i, //The second level compensation method,which would made the byte more precision
    // The input and output control signal
        input           BaudEn_i,    //Baudrate enable signal
        output          AcqSig_o,    //Rx port acquisite signal
        output          BaudSig_o    //Tx port singal frequency
    );
    // Register definition
        // input buffer
            reg     [12:0]  acq_period_r;           // divider 
            reg     [12:0]  compensate_period_r;    // the compensated period                
            reg             baud_en_r;
        // divider to generate the baudrate signal from the acquisition signal, the baud_divider_r = acq_num_counter_r + comp_num_counter_r
            reg     [3:0]   baud_divider_r;         // the divider for the baud sig(1~16 divid, acq sig), it is the sum of acq_num_counter_r and comp_num_counter_r
            reg     [3:0]   acq_num_counter_r;      // the divider for the baud sig, count the normal acq signal
            reg     [3:0]   comp_num_counter_r;     // the divider for the baud sig, count the compensated acq signal 
            reg     [12:0]  acq_period_counter_r;   // the counter for the acquisition signal divide from the system clock signal
            reg             acqsig_r;               // the register of acquisition signal, which only last 1 clock
            reg             baudsig_r;              // the register of the baudrate signal, which only last 1 clock
        // bits index in a byte, the secondary level of compensation, we define that the pos_bit_num_r + neg_bit_num_r = 12
            reg     [3:0]   bit_index_r;            // the bits index, used as a state machine.
            reg     [3:0]   pos_bit_num_r;          // the number of positive compensation method bits in a byte left to send
            reg     [3:0]   neg_bit_num_r;          // the number of negative compensation method bits in a byte left to send
        // bit type 
            reg             bit_type_r;             // the bit type in byte, positive compensated bit or negative compensated bit
    // Wire definition
        // Acquisition signal and Baudrate signal trigger
            wire            AcqRising_w; 
            wire            BaudRising_w;
        // The bit type choosing a properial compensation method according to the left bit number in the byte 
            wire            BitType_w;              // the data bit compensation type
            wire            InputBitType_w;         // the start bit compensation type.
        // The input data
            wire    [3:0]   PosBitsNum_w;           // the number of bits using positive compensation method in the byte
            wire    [3:0]   NegBitsNum_w;           // the number of bits using negative compensation method in the byte
            wire    [3:0]   PosNormAcqNum_w;        // the positive compensation method normal acquisition point number in a bit
            wire    [3:0]   PosCompAcqNum_w;        // the positive compensation method compensated acquisition point number in a bit
            wire    [3:0]   NegNormAcqNum_w;        // the negative compensation method normal acquisition point number in a bit
            wire    [3:0]   NegCompAcqNum_w;        // the negative compensation method compensated acquisition point number in a bit
            
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
        // output assign
            assign BaudSig_o        = baudsig_r;
            assign AcqSig_o         = acqsig_r;
        // wire 
            assign AcqRising_w      = acq_period_counter_r == acq_period_r;     // the acquisition period counter gain to the limit set by top module
            assign BaudRising_w     = AcqRising_w & (acq_num_counter_r == 4'd0) & (comp_num_counter_r == 4'd0); // normal acquisition period and compensated period all finished
            assign BitType_w        = pos_bit_num_r > neg_bit_num_r;   // if now the positive bits' number left in the cycle is bigger than the negatives' the next bit should be a positive compensated bit
        // input data
            assign PosBitsNum_w     = ByteCompensation_i[7:4];
            assign NegBitsNum_w     = ByteCompensation_i[3:0];
            assign PosNormAcqNum_w  = PosCompensation_i[7:4];
            assign PosCompAcqNum_w  = PosCompensation_i[3:0];
            assign NegNormAcqNum_w  = NegCompensation_i[7:4];
            assign NegCompAcqNum_w  = NegCompensation_i[3:0];
            assign InputBitType_w   = PosBitsNum_w > NegBitsNum_w; // if now the positive bits' number left in the cycle is bigger than the negatives' the start bit should be a positive compensated bit
    // Bit index in byte. Used as a compensation state machine
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                bit_index_r <= 4'd0;                
            end
            else if (BaudRising_w == 1'b1) begin
                if (bit_index_r == BYTEWIDTH) begin
                    bit_index_r <= 4'd0;
                end
                else begin
                    bit_index_r <= bit_index_r + 1'b1;
                end
            end
            else begin
                bit_index_r <= bit_index_r;
            end
        end
    // Positive bit number and Negative bit number fresh
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                pos_bit_num_r <= 4'd0;
                neg_bit_num_r <= 4'd0;                
            end
            else if (BaudRising_w == 1'b1) begin
                if ((pos_bit_num_r == 4'd0) && (neg_bit_num_r == 4'd0)) begin  // that means a cycle(12bits Cycle) is over, new Start
                    if (InputBitType_w == POSITIVE) begin   // the first bit in the Cycle is positive or negative using different compensation method
                        pos_bit_num_r <= PosBitsNum_w - 1'b1;
                        neg_bit_num_r <= NegBitsNum_w;
                    end
                    else begin  // if the first bit should be negative
                        pos_bit_num_r <= PosBitsNum_w;
                        neg_bit_num_r <= NegBitsNum_w - 1'b1;
                    end
                end
                else begin
                    if (BitType_w == POSITIVE) begin   // the next bit in the Cycle is positive or negative using different compensation method
                        pos_bit_num_r <= PosBitsNum_w - 1'b1;
                        neg_bit_num_r <= NegBitsNum_w;
                    end
                    else begin  // if the first bit should be negative
                        pos_bit_num_r <= PosBitsNum_w;
                        neg_bit_num_r <= NegBitsNum_w - 1'b1;
                    end
                end
            end
            else begin
                pos_bit_num_r <= pos_bit_num_r;
                neg_bit_num_r <= neg_bit_num_r;
            end
        end
    // Bit divid register fresh
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                acq_num_counter_r   <= 4'd15;
                comp_num_counter_r  <= 4'd15;
            end
            else if () begin
                
            end
        end
endmodule
