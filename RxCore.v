// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Javen   penguinleo@163.com
// File   : RxCore.v
// Create : 2019-11-17 10:19:33
// Revise : 2019-11-17 10:19:34
// Editor : sublime text3, tab size (4)
// Comment: this module is designed to receive the serial data from rx wire
//          Up module:
//              UartCore
//          Sub module:
//              ShiftRegister_Rx        Serial to byte module
//              FIFO_Ver1               Fifo module
//              FSM_Rx                  State machine of rx core
//               
//          Input
//              clk :   clock signal
//              rst :   reset signal
//          Output
//              
// -----------------------------------------------------------------------------
