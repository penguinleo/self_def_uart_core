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
//      1   |   clk :   clock signal
//      2   |   rst :   reset signal
// Output Signal List:
//      1   |     
//              
// -----------------------------------------------------------------------------
module ShiftRegister_Rx(
    input           clk,
    input           rst,
    // the interface with the BaudrateModule
    input           AcqSig_i,
    // the interface with the FSM_Rx module
    input   [4:0]   State_i,
    input   [3:0]   


    );
    // register definition
        reg [2:0]   shift_reg_r;
        reg [15:0]  serial_reg_r;
        reg [15:0]  bit_width_cnt_r;   // this register was applied to measure the width of the rx signal 
    // wire definition 
        wire        falling_edge_rx_w;  // the falling edge of the rx port
        wire        rising_edge_rx_w;   // the rising edge of the rx port(reserved maybe no applied)
    // parameter definition
        parameter   IDLE    = 5'b0_0000;
    // wire assign 
        assign falling_edge_rx_w    = shift_reg_r[2] & !shift_reg_r[1]; // falling edge of the rx
        assign rising_edge_rx_w     = !shift_reg_r[2]&  shift_reg_r[1];
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
    // serial data 
endmodule