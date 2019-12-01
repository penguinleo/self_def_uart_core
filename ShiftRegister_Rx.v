// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Javen   penguinleo@163.com
// File   : ShiftRegister_Rx.v
// Create : 2019-11-26 16:53:42
// Revise : 2019-11-26 16:53:42
// Editor : sublime text3, tab size (4)
// Comment: this module is designed to 
//          Up module:
//              RxCore
//          Sub module:
//                  
// Input Signal List:
//      1   |   clk         :   clock signal
//      2   |   rst         :   reset signal
//      3   |   AcqSig_i    :   the acquisition signal 
// Output Signal List:
//      1   |     
//              
// -----------------------------------------------------------------------------
module ShiftRegister_Rx(
    // System signal definition
        input           clk,
        input           rst,
    // the interface with the BaudrateModule
        input           AcqSig_i,
    // the interface of the RX core
        input           Rx_i,
    // the interface with the FSM_Rx module
        input   [4:0]   State_i,
        input   [3:0]   BitCounter_i,   // the index of the bit in the byte
        input           p_BigEnd_i,     // the Big end or the Little end
    // the output of the module
        output  [11:0]  Byte_o,     // the output of the shift register, including the data bits and the parity bit
    // the sychronization signal
        output          Rx_Synch_o // at the falling edge of the RX when the state machine is idle
    );
    // register definition
        reg [2:0]   shift_reg_r;
        reg [15:0]  serial_reg_r;
        reg [3:0]   bit_width_cnt_r;   // this register was applied to measure the width of the rx signal 
        reg [11:0]  byte_r;
    // wire definition 
        wire        falling_edge_rx_w;  // the falling edge of the rx port
        wire        rising_edge_rx_w;   // the rising edge of the rx port(reserved maybe no applied)
    // parameter definition
        // Receiving state machine definition  
            parameter   IDLE        = 5'b0_0001;   
            parameter   STARTBIT    = 5'b0_0010;
            parameter   DATABITS    = 5'b0_0100;
            parameter   PARITYBIT   = 5'b0_1000;
            parameter   STOPBIT     = 5'b1_0000;
            parameter   ACQSITION_POINT = 4'd7;
        // Big end and littel end definition
            parameter BIGEND    = 1'b1;
            parameter LITTLEEND = 1'b0;
    // wire assign 
        assign falling_edge_rx_w    = shift_reg_r[2] & !shift_reg_r[1]; // falling edge of the rx
        assign rising_edge_rx_w     = !shift_reg_r[2]&  shift_reg_r[1];
        assign Rx_Synch_o           = falling_edge_rx_w & (State_i == IDLE);
    // Shift register operation definition
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                shift_reg_r <= 3'b000;            
            end
            else if (AcqSig_i == 1'b1) begin
                shift_reg_r <= {shift_reg_r[1:0],Rx_i};
            end
            else begin
                shift_reg_r <= shift_reg_r;
            end
        end
    // serial data register operation  *the acquisition point* 
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                serial_reg_r <= 16'd0;                
            end
            else if (AcqSig_i == 1'b1) begin
                serial_reg_r <= {serial_reg_r[14:0],shift_reg_r[2]};
            end
            else begin
                serial_reg_r <= serial_reg_r;
            end
        end
    // bit width counter,Once the system was synchronized the counter is started until the end of the byte
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                bit_width_cnt_r <= 4'd0;                
            end
            else if (Rx_Synch_o == 1'b1) begin // Once the system was synchronized
                bit_width_cnt_r <= 4'd1;
            end
            else if ((State_i != IDLE) && (AcqSig_i == 1'b1)) begin
                bit_width_cnt_r <= bit_width_cnt_r + 1'b1;
            end
            else begin
                bit_width_cnt_r <= bit_width_cnt_r;
            end
        end
    // byte register refresh
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                byte_r <= 12'b0000_0000_0000;                
            end
            else if ((State_i == IDLE)) begin
                byte_r <= 12'b0000_0000_0000;
            end
            else if ((State_i == STARTBIT) && (bit_width_cnt_r == ACQSITION_POINT)) begin
                byte_r <= {byte_r[11:1],shift_reg_r[2]};
            end
            else if ((State_i == DATABITS) && (bit_width_cnt_r == ACQSITION_POINT) && (BitCounter_i == 4'd0)) begin  // the first data bit 
                byte_r <= {byte_r[11:2],    shift_reg_r[2],     byte_r[0]};
            end
            else if ((State_i == DATABITS) && (bit_width_cnt_r == ACQSITION_POINT) && (BitCounter_i == 4'd1)) begin
                byte_r <= {byte_r[11:3],    shift_reg_r[2],     byte_r[1:0]};
            end
            else if ((State_i == DATABITS) && (bit_width_cnt_r == ACQSITION_POINT) && (BitCounter_i == 4'd2)) begin
                byte_r <= {byte_r[11:4],    shift_reg_r[2],     byte_r[2:0]};
            end
        end
endmodule
