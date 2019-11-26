// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Javen   penguinleo@163.com
// File   : FSM_Rx.v
// Create : 2019-11-26 16:32:59
// Revise : 2019-11-26 16:32:59
// Editor : sublime text3, tab size (4)
// Comment: this module is the state machine of the rxcore, state is below
//          IDLE    :   the  IDEL state, the UART port is idle, nothing was
//                      sent on the bus.
//          BUSY    :   The Rxcore is receiving data from the data bus.
//          This state machine moving from IDLE to BUSY was triggled by the falling edge on Rx port.
//          The moving from BUSY to IDLE was accorded to the acqsig counter.
//          Up module:
//              RxCore
//          Sub module:
//              --  
//          Input
//              clk :   clock signal
//              rst :   reset signal
//          Output
//              
// -----------------------------------------------------------------------------
