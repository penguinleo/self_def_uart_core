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
            reg     [15:0]  divider_r;  // divider 
            reg             bauden_r;
        // opperate register
            reg     [2:0]   div_baud_r; // the divider for the baud sig(1:8, acq sig)
            reg     [15:0]  counter_r;
            reg             acqsig_r;
            reg             baudsig_r;
    // Wire definition
        wire            AcqRising_w; 
        wire            BaudRising_w;
        wire            CounterZero_w;
    // Parameter definition
        // Enable Definition
            parameter       BAUD_ON = 1'b1;
            parameter       BAUD_OFF= 1'b0;
        // The divider between the baudrate sig and the acquisition sig
            parameter       BAUD_DIV = 3'b111;
    // Assign
        assign AcqRising_w      = (counter_r == divider_r);
        assign BaudRising_w     = div_baud_r[2] & div_baud_r[1] & div_baud_r[0];
        assign BaudSig_o        = baudsig_r;
        assign AcqSig_o         = acqsig_r;
        assign CounterZero_w    = (counter_r == 16'd0);
    // Module definition
        // enable register buffer
            always @(posedge clk or negedge rst) begin
                if (!rst) begin
                    bauden_r <= BAUD_OFF;                    
                end
                else begin
                    bauden_r <= BaudEn_i;
                end
            end
        // module input buffer
            always @(posedge clk or negedge rst) begin
                if (!rst) begin
                    divider_r <= 16'd0;         // reset the baudrate is zero
                end
                else if (CounterZero_w) begin
                    divider_r <= Divisor_i;
                end
            end
        // counter gain & acquisition sig generator
            always @(posedge clk or negedge rst) begin
                    if (!rst || (bauden_r == BAUD_ON)) begin
                        counter_r   <= 16'd0;
                        acqsig_r    <= 1'b0;                                
                    end
                    else if (AcqRising_w) begin
                        counter_r   <= 16'd0;
                        acqsig_r    <= 1'b1; 
                    end
                    else begin
                        counter_r   <= counter_r + 1'b1;
                        acqsig_r    <= 1'b0; 
                    end
                end   
        // baud div register gain and baud sig generate
            always @(posedge clk or negedge rst) begin
                       if (!rst || (bauden_r == BAUD_ON)) begin
                           div_baud_r   <= 3'b000;
                           baudsig_r    <= 1'b0;
                       end
                       else if (BaudRising_w) begin
                           div_baud_r   <= 3'b000;
                           baudsig_r    <= 1'b1;
                       end
                       else begin
                           div_baud_r   <= div_baud_r + acqsig_r;
                           baudsig_r    <= 1'b0;
                       end
                   end     
endmodule
