// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Javen   penguinleo@163.com
// File   : CtrlCore.v
// Create : 2019-12-17 15:19:59
// Revise : 2019-12-17 15:19:59
// Editor : sublime text3, tab size (4)
// Comment: this module is designed to control the uart port.
//          The uart module is designed a compensate method to implement an acqurate bit width
//          I call this method acquisite period compensate method.
//          In further, the bit width compensate method would be introduced to reduce the accumulate
//          error in the last bit of a byte during transmitte.
//          Up module:
//              UartCore
//          Sub module:
//              None
// Input Signal List:
//      1   |   clk                 :   clock signal
//      2   |   rst                 :   reset signal
//      3   |   p_We_i              :   control register write enable signal, positive effective.
//      4   |   CtrlReg1_i          :   Control parameter register,
//                                      Bit 7 controls the big end or little end format;
//                                      Bit 6 controls the parity function, 1-enable,0-disable;
//                                      Bit 5 choose the parity method, 0-even,1-odd;
//                                      Bit 4 reserved bit;
//                                      Bit 3 ~ 0 are the high 4 bits of acquisite period control reg;
//      6   |   BitCompensateMethod :   Compensation control register
//                                      Bit 7 ~ 4 are the number of round-up acquisite period in a bit time;
//                                      Bit 3 ~ 0 are the number of round-down period in a bit time;
//                                      The acquisite period control reg is the round-down period data.
// Output Signal List:      
//      1   |   BaudRateGen_o         :   The acquisite perid control register output. This period is the round-down
//                                      period. This data is sent to the BaudGenerate module to generate the AcqSig
//      2   |   BitCompensation_o   :   The compensate control register, which would help the BaudGenerate module
//                                      reduce the bit width error less than a system clk;
//                                      Bit 7 ~ 4 are the number of round-up acquisite period in a bit time
//                                      Bit 3 ~ 0 are the number of round-down acquisite period in a bit time
//      3   |   AcqNumPerBit_o      :   The number to acquisite opperation in a bit time. This data is the sum of
//                                      the BitCompensation_o[7:4] + BitCompensation_o[3:0]
//      4   |   p_ParityEnable_o    :   The parity enable signal output for other uart submodules, 1-enable,0-disable;
//      5   |   p_BigEnd_o          :   The format control signal output for other uart submodules, 0-even,1-odd;
//      6   |   ParityMethod_o      :   The parity method select signal output for other uart submodule, 0-even,1-odd;
// Note:  
// 
// -----------------------------------------------------------------------------   
module CtrlCore(
    input   clk,
    input   rst,
    // The address bus 
        input [2:0]     AddrBus_i,              // the input address bus
        input           n_ChipSelect_i,         // the chip select signal
        input           n_rd_i,                 // operation direction control signal read direction, negative enable
        input           n_we_i,                 // operation direction control signal write direction, negative enable
        input [7:0]     DataBus_i,              // data bus input direction
        output [7:0]    DataBus_o,
    // baudrate module interface

    // tx module interface

    // rx module interface
        // error signal
            input           p_RxParityErr_i,        // RX parity check fail, positive error occur
            input           p_RxFrameErr_i,         // Rx stop bit missing, positive error occur
        // fifo control signal
            input [7:0]     RxData_i,               // Rx Fifo read port
            input           p_RxFIFO_Empty_i,       // Rx Fifo empty, status signal, positive enable
            output          n_RxFIFO_Rd_o,          // Rx Fifo read control signal, negative enable
            output          n_RxFIFO_Clr_o,         // Rx Fifo clear signal
            input [15:0]    n_RxFIFO_Level_i,       // Rx Fifo bytes in fifo
        // extend function signal(Data link level)
            output          p_RxFrame_Func_En_o,    // Data link level protocol function enable control
            input [27:0]    RxFrameInfo_i,          // Data link level protocol function extension
            input           p_RxFrame_Empty_i,      // No Received frame
            output          n_RxFrameInfo_Rd_o,     // Read frame informatoin control signal, negative enable
            
    // Rx & Tx encode control control output
        output [3:0]    AcqNumPerBit_o,
        output          p_ParityEnable_o,
        output          p_BigEnd_o,
        output          ParityMethod_o
    );
    // Register definition //trip-modesynthesis syn_preserve=1
        reg [7:0]   UartControl_r1              /*synthesis syn_preserve = 1*/;  // W module control
        reg [7:0]   UartMode_r1                 /*synthesis syn_preserve = 1*/;  // R/W mode  
        reg [15:0]  BaudRateGen_r1              /*synthesis syn_preserve = 1*/;  // R/W the acquisite signal divide from the the system clock signal
        reg [7:0]   BitCompensateMethod_r1      /*synthesis syn_preserve = 1*/;  // R/W round up and down acquisition period, the sum of this two is the divider of acquisite signal and baud signal    
        reg [15:0]  InterrputEnable_r1          /*synthesis syn_preserve = 1*/;  // W   interrupt enable and disable control
        reg [15:0]  InterruptMask_r1            /*synthesis syn_preserve = 1*/;  // R the interrupt enable signal controlled 
        reg [15:0]  InterruptState_r1           /*synthesis syn_preserve = 1*/;  // R/W the interrupt signal and clear control register 
        reg [15:0]  UartState_r1                /*synthesis syn_preserve = 1*/;  // R the uart state register
        
    //
        reg [3:0]   AcqNumPerBit_r;
    // Logic definition

    // parameter
        // Default parameter
            parameter       DEFAULT_PERIOD      = 16'd20;
            parameter       DEFAULT_UP_TIME     = 4'd10;
            parameter       DEFAULT_DOWN_TIME   = 4'd5;
        // Uart mode parameter
            parameter       NORMAL_MODE         = 4'b0001;    // Normal mode, tx port sends data and rx port receives data
            parameter       AUTO_ECHO_MODE      = 4'b0010;    // Automatic echo mode, rx port receives data and transfer to tx port
            parameter       LOCAL_LOOPBACK_MODE = 4'b0100;    // Local loopback mode, rx port connected to the tx port directly would not send out
            parameter       REMOTE_LOOPBACK_MODE= 4'b1000;    // Remote loopback mode, the input io and output io of uart was connected directly 
        // Parity Enable definition
            parameter ENABLE    = 1'b1;
            parameter DISABLE   = 1'b0;
        // Big end and littel end definition
            parameter BIGEND    = 1'b1;
            parameter LITTLEEND = 1'b0;
        // parity method definition
            parameter EVEN      = 1'b0;
            parameter ODD       = 1'b1;
    // assign
        assign BaudRateGen_o        = BaudRateGen_r;
        assign BitCompensation_o    = BitCompensation_r;
        assign p_ParityEnable_o     = p_ParityEnable_r;
        assign p_BigEnd_o           = p_BigEnd_r;
        assign ParityMethod_o       = p_ParityEnable_r;
        assign AcqNumPerBit_o       = AcqNumPerBit_r;
    // register fresh 
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                BaudRateGen_r       <= DEFAULT_PERIOD;
                BitCompensation_r   <= {DEFAULT_UP_TIME,DEFAULT_DOWN_TIME};
                p_ParityEnable_r    <= ENABLE;
                p_BigEnd_r          <= LITTLEEND;
                ParityMethod_r      <= ODD;
                AcqNumPerBit_r      <= DEFAULT_UP_TIME + DEFAULT_DOWN_TIME;     
                UartMode_r          <= NORMAL_MODE; 
            end
            else if (p_We_i == 1'b1) begin
                BaudRateGen_r       <= BaudRateGen_i;
                BitCompensation_r   <= BitCompensateMethod;
                p_ParityEnable_r    <= ModeCtrl_i[6];
                p_BigEnd_r          <= ModeCtrl_i[7];
                ParityMethod_r      <= ModeCtrl_i[5];
                UartMode_r          <= ModeCtrl_i[3:0];
                AcqNumPerBit_r      <= BitCompensateMethod[7:4] + BitCompensateMethod[3:0];
            end
            else begin
                BaudRateGen_r       <= BaudRateGen_r;
                BitCompensation_r   <= BitCompensation_r;
                p_ParityEnable_r    <= p_ParityEnable_r;
                p_BigEnd_r          <= p_BigEnd_r;
                ParityMethod_r      <= ParityMethod_r;
                UartMode_r          <= UartMode_r;
                AcqNumPerBit_r      <= AcqNumPerBit_r;
            end
        end
endmodule
