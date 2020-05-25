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
//      1   |   BaudRateGen_o       :   The acquisite perid control register output. This period is the round-down
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
// Register Map:
//   Address | ConfigEn |IrqConfigEn| IrqLvlEn | Dir |         Name          |                                       Bit Definition                                          | 
//   --------|----------|-----------|----------|-----|-----------------------|     B7    |     B6    |     B5    |    B4     |     B3    |     B2    |    B1     |     B0    |
//    3'b000 |     X    |     X     |     X    | R/W |      UartControl      | ConfigEn  |IrqConfigEn|  IrqLvlEn |   ClkSel  |   RxEn    |    TxEn   |   RxRst   |   TxRst   |
//    3'b001 |     1    |     0     |     0    | R/W |       UartMode        |                   ModeSel                     |   EndSel  |   ParEn   |  ParSel   |  Reserved |  
//    3'b010 |     1    |     0     |     0    | R/W |   BaudGeneratorHigh   |   High 8 bits of the Baudrate generator register, write access enabled when ConfigEn == 1     | 
//    3'b011 |     1    |     0     |     0    | R/W |   BaudGeneratorLow    |   Low 8 bits of the Baudrate generator register, write access enabled when ConfigEn == 1      |
//    3'b100 |     1    |     0     |     0    | R/W |  BitCompensateMethod  |         Round Up Period number in a bit       |       Round Down Period number in a bit       |
//    3'b001 |     1    |     1     |     0    |  W  |    InterrputEnable1   | Reserved  | Reserved  |   RBRK    |   TOVR    |   TNFUL   |   TTRIG   | Reserved  |   TOUT    |
//    3'b010 |     1    |     1     |     0    |  W  |    InterrputEnable2   |   PARITY  |  FRAMING  |   OVER    |   TXFUL   |  TXEMPTY  |   RXFULL  |  RXEMPTY  |   RXOVR   | 
//    3'b011 |     1    |     1     |     0    |  R  |    InterruptMask1     | Reserved  | Reserved  |   RBRK    |   TOVR    |   TNFUL   |   TTRIG   | Reserved  |   TOUT    |
//    3'b100 |     1    |     1     |     0    |  R  |    InterruptMask2     |   PARITY  |  FRAMING  |   OVER    |   TXFUL   |  TXEMPTY  |   RXFULL  |  RXEMPTY  |   RXOVR   |
//    3'b001 |     1    |     1     |     1    | R/W |    RxTrigLevelHigh    |     High 8 bits of the rx fifo trigger level                                                         |      
//    3'b010 |     1    |     1     |     1    | R/W |    RxTrigLevelLow     |     Low 8 bits of the rx fifo trigger level                                                   |
//    3'b011 |     1    |     1     |     1    | R/W |    TxTrigLevelHigh    |     High 8 bits of the tx fifo trigger level                                                  |    
//    3'b100 |     1    |     1     |     1    | R/W |    TxTrigLevelLow     |     Low 8 bits of the tx fifo trigger level                                                   |
//    3'b001 |     0    |     0     |     0    | R/W |   InterruptStatus1    | Reserved  | Reserved  |   RBRK    |   TOVR    |   TNFUL   |   TTRIG   | Reserved  |   TOUT    |     
//    3'b010 |     0    |     0     |     0    | R/W |   InterruptStatus2    |   PARITY  |  FRAMING  |   OVER    |   TXFUL   |  TXEMPTY  |   RXFULL  |  RXEMPTY  |   RXOVR   | 
//    3'b011 |     0    |     0     |     0    |  R  | BytesNumberReceived1  |   High 8 bits of the bytes' number in receive fifo                                            |
//    3'b100 |     0    |     0     |     0    |  R  | BytesNumberReceived2  |   Low 8 bits of the bytes' number in receive fifo                                             |
//    3'b101 |     X    |     X     |     X    |  R  |      UartStatus1      | Reserved  |   TNFUL   |   TTRIG   | Reserved  |  TACTIVE  |  RACTIVE  | Reserved  | Reserved  |
//    3'b110 |     X    |     X     |     X    |  R  |      UartStatus2      | Reserved  | Reserved  | Reserved  |   TXFUL   |  TXEMPTY  |   RXFULL  |  RXEMPTY  |   RXOVR   |
//    3'b111 |     X    |     X     |     X    |  R  |      RxDataPort       |     8 bit receive data read port
//    3'b111 |     X    |     X     |     X    |  W  |      TxDataPort       |     8 bit transmite data send port
// Note:  
// 
// -----------------------------------------------------------------------------   
module CtrlCore(
    input   clk,
    input   rst,
    // The bus interface
        input  [2:0]    AddrBus_i,                  // the input address bus
        input           n_ChipSelect_i,             // the chip select signal
        input           n_rd_i,                     // operation direction control signal read direction, negative enable
        input           n_we_i,                     // operation direction control signal write direction, negative enable
        input  [7:0]    DataBus_i,                  // data bus input direction write data into the registers
        output [7:0]    DataBus_o,                  // data bus output direction read data from the registers
    // baudrate module interface
        output [15:0]   BaudRateGen_o,              // The divider data for the acquisite period
        output [3:0]    RoundUpNum_o,               // The compensate method high 4 bits, round up acquisite period
        output [3:0]    RoundDownNum_o,             // The compensate method low 4 bits, round down acquisite period
        output [3:0]    BaudDivider_o,              // The divider for the baudrate signal and the acquisite signal
    // tx module interface
        output          p_TxCoreEn_o,               // The Tx core enable signal. Positive effective 
        // fifo control signal
            output [7:0]    TxData_o,               // Tx Fifo write data port
            input           p_TxFIFO_Full_i,        // Tx Fifo full signal, positive the fifo full
            output          n_TxFIFO_We_o,          // Tx Fifo write control singal, negative effective
            output          n_TxFIFO_Clr_o,         // Tx Fifo clear signal, negative effective
            input [15:0]    TxFIFO_Level_i,         // The bytes number in the Tx fifo 
    // rx module interface
        output          p_RxCoreEn_o,               //The Rx core enable signal. Positive effective
        // error signal
            input           p_RxParityErr_i,        // RX parity check fail, positive error occur
            input           p_RxFrameErr_i,         // Rx stop bit missing, positive error occur
        // fifo control signal
            input [7:0]     RxData_i,               // Rx Fifo read port
            input           p_RxFIFO_Empty_i,       // Rx Fifo empty, status signal, positive effective
            output          n_RxFIFO_Rd_o,          // Rx Fifo read control signal, negative effective
            output          n_RxFIFO_Clr_o,         // Rx Fifo clear signal
            input [15:0]    RxFIFO_Level_i,         // bytes number in the Rx fifo
        // extend function signal(Data link level)
            output          p_RxFrame_Func_En_o,    // Data link level protocol function enable control
            input [27:0]    RxFrameInfo_i,          // Data link level protocol function extension
            input           p_RxFrame_Empty_i,      // No Received frame
            output          n_RxFrameInfo_Rd_o,     // Read frame informatoin control signal, negative enable     
    // Rx & Tx encode control control output
        output          p_ParityEnable_o,
        output          p_BigEnd_o,
        output          ParityMethod_o
    );
    // Register definition //trip-modesynthesis syn_preserve=1
        reg [7:0]   UartControl_r1              /*synthesis syn_preserve = 1*/;  // W module control
        reg [7:0]   UartMode_r1                 /*synthesis syn_preserve = 1*/;  // R/W mode  
        reg [15:0]  BaudGenerator_r             /*synthesis syn_preserve = 1*/;  // R/W the acquisite signal divide from the the system clock signal
        reg [7:0]   BitCompensateMethod_r1      /*synthesis syn_preserve = 1*/;  // R/W round up and down acquisition period, the sum of this two is the divider of acquisite signal and baud signal    
        reg [15:0]  InterrputEnable_r1          /*synthesis syn_preserve = 1*/;  // W   interrupt enable and disable control
        reg [15:0]  InterruptMask_r1            /*synthesis syn_preserve = 1*/;  // R the interrupt enable signal controlled 
        reg [15:0]  InterruptState_r1           /*synthesis syn_preserve = 1*/;  // R/W the interrupt signal and clear control register 
        reg [15:0]  UartState_r1                /*synthesis syn_preserve = 1*/;  // R the uart state register
        reg [3:0]   BaudDivider_r1;
    // Logic definition
        // page control signal definition
            wire        ConfigEn_w;
            wire        IrqConfigEn_w;
            wire        IrqLvlEn_w;
        // control signal definition
            wire        ClkSel_w;
            wire        RxEn_w;
            wire        TxEn_w;
            wire [3:0]  ModeSel_w;
            wire        EndSel_w;
            wire        ParEn_w;
            wire        ParSel_w;
        // Bus control signal logic
            wire        ChipWriteAccess_w;      // The chip selected signal and write signal available together.
            wire        ChipReadAccess_w;       // The chip selected signal and read signal available together.
        // Register write access available
            wire        UartControl_Write_Access_w;   
            wire        UartMode_Write_Access_w;
            wire        BaudGeneratorHigh_Write_Access_w;
            wire        BaudGeneratorLow_Write_Access_w;
            wire        BitCompensateMethod_Write_Access_w;
            wire        InterrputEnable1_Write_Access_w;
            wire        InterrputEnable2_Write_Access_w;
            wire        InterruptMask1_Write_Access_w;
            wire        InterruptMask2_Write_Access_w;
            wire        RxTrigLevelHigh_Write_Access_w;
            wire        RxTrigLevelLow_Write_Access_w;
            wire        TxTrigLevelHigh_Write_Access_w;
            wire        TxTrigLevelLow_Write_Access_w;
            wire        InterruptStatus1_Write_Access_w;
            wire        InterruptStatus2_Write_Access_w;
            wire        BytesNumberReceived1_Write_Access_w;
            wire        BytesNumberReceived2_Write_Access_w;
            wire        UartStatus1_Write_Access_w;
            wire        UartStatus2_Write_Access_w;
            wire        RxDataPort_Write_Access_w;
            wire        TxDataPort_Write_Access_w;         
    // parameter
        // Address definition
            parameter   ADDR_UartControl                = 3'b000;
            parameter   ADDR_UartMode                   = 3'b001;
            parameter   ADDR_BaudGeneratorHigh          = 3'b010;
            parameter   ADDR_BaudGeneratorLow           = 3'b011;
            parameter   ADDR_BitCompensateMethod        = 3'b100;
            parameter   ADDR_InterrputEnable1           = 3'b001;
            parameter   ADDR_InterrputEnable2           = 3'b010;
            parameter   ADDR_InterruptMask1             = 3'b011;
            parameter   ADDR_InterruptMask2             = 3'b100;
            parameter   ADDR_RxTrigLevelHigh            = 3'b001;
            parameter   ADDR_RxTrigLevelLow             = 3'b010;
            parameter   ADDR_TxTrigLevelHigh            = 3'b011;
            parameter   ADDR_TxTrigLevelLow             = 3'b100;
            parameter   ADDR_InterruptStatus1           = 3'b001;
            parameter   ADDR_InterruptStatus2           = 3'b010;
            parameter   ADDR_BytesNumberReceived1       = 3'b011;
            parameter   ADDR_BytesNumberReceived2       = 3'b100;
            parameter   ADDR_UartStatus1                = 3'b101;
            parameter   ADDR_UartStatus2                = 3'b110;
            parameter   ADDR_RxDataPort                 = 3'b111;
            parameter   ADDR_TxDataPort                 = 3'b111;
        // Function definition
            parameter   ON      = 1'b1;
            parameter   OFF     = 1'b0;
            parameter   N_ON    = 1'b0;
            parameter   N_OFF   = 1'b1;
            //  UartControl bit 
                // ConfigEN
                    parameter       UartControl_ConfigEn_ON     = 1'b1;   // In this state the cpu cound access the uart port configuration register
                    parameter       UartControl_ConfigEn_OFF    = 1'b0;   // In this state the cpu access the uart port normal opperation register
                // IrqConfigEn
                    parameter       UartControl_IrqConfigEn_ON  = 1'b1;
                    parameter       UartControl_IrqConfigEn_OFF = 1'b0;
                // IrqLvlEn
                    parameter       UartControl_IrqLvlEn_ON     = 1'b1;
                    parameter       UartControl_IrqLvlEn_OFF    = 1'b0;
                // ClkSel
                    parameter       UartControl_ClkSel_Time1    = 1'b0;
                    parameter       UartControl_ClkSel_Time8    = 1'b1;
                // TxEn
                    parameter       UartControl_TxEn_ON         = 1'b1;
                    parameter       UartControl_TxEn_OFF        = 1'b0;
                // RxEn
                    parameter       UartControl_RxEn_On         = 1'b1;
                    parameter       UartControl_RxEn_OFF        = 1'b0;
            // UartMode bit definition
                // ModeSel  --UartMode Definition 
                    parameter       UartMode_NORMAL             = 4'b0001;    // Normal mode, tx port sends data and rx port receives data
                    parameter       UartMode_AUTO_ECHO          = 4'b0010;    // Automatic echo mode, rx port receives data and transfer to tx port
                    parameter       UartMode_LOCAL_LOOPBACK     = 4'b0100;    // Local loopback mode, rx port connected to the tx port directly would not send out
                    parameter       UartMode_REMOTE_LOOPBACK    = 4'b1000;    // Remote loopback mode, the input io and output io of uart was connected directly  
                // EndSel
                    parameter       UartMode_BIGEND             = 1'b1;
                    parameter       UartMode_LITTLEEND          = 1'b0;    
                // ParEn
                    parameter       UartMode_Parity_ENABLE      = 1'b1;
                    parameter       UartMode_Parity_DISABLE     = 1'b0;
                // ParSel
                    parameter       UartMode_ParSel_EVEN        = 1'b0;
                    parameter       UartMode_ParSel_ODD         = 1'b1;
        // Default parameter -- BaudRateGen & BitCompensateMethod
            parameter       DEFAULT_PERIOD      = 16'd20;
            parameter       DEFAULT_UP_TIME     = 4'd10;
            parameter       DEFAULT_DOWN_TIME   = 4'd5;
    // Logic assign definition
        // page control signal definition
            assign ConfigEn_w       = UartControl_r1[7];
            assign IrqConfigEn_w    = UartControl_r1[6];
            assign IrqLvlEn_w       = UartControl_r1[5];
        // control signal definition
            assign ClkSel_w         = UartControl_r1[4];
            assign RxEn_w           = UartControl_r1[3];
            assign TxEn_w           = UartControl_r1[2];
            assign ModeSel_w        = UartMode_r1[7:4];
            assign EndSel_w         = UartMode_r1[3];
            assign ParEn_w          = UartMode_r1[2];
            assign ParSel_w         = UartMode_r1[1];
        // Bus control signal logic 
            assign ChipWriteAccess_w                    = (n_ChipSelect_i == 1'b0) && (n_we_i == 1'b0);\

        // Register write access available
            assign UartControl_Write_Access_w           = ChipWriteAccess_w && (AddrBus_i == ADDR_UartControl);  
            assign UartMode_Write_Access_w              = ChipWriteAccess_w && (AddrBus_i == ADDR_UartMode              ) && (ConfigEn_w == ON ) && (IrqConfigEn_w == OFF) && (IrqLvlEn_w == OFF);   
            assign BaudGeneratorHigh_Write_Access_w     = ChipWriteAccess_w && (AddrBus_i == ADDR_BaudGeneratorHigh     ) && (ConfigEn_w == ON ) && (IrqConfigEn_w == OFF) && (IrqLvlEn_w == OFF);
            assign BaudGeneratorLow_Write_Access_w      = ChipWriteAccess_w && (AddrBus_i == ADDR_BaudGeneratorLow      ) && (ConfigEn_w == ON ) && (IrqConfigEn_w == OFF) && (IrqLvlEn_w == OFF);
            assign BitCompensateMethod_Write_Access_w   = ChipWriteAccess_w && (AddrBus_i == ADDR_BitCompensateMethod   ) && (ConfigEn_w == ON ) && (IrqConfigEn_w == OFF) && (IrqLvlEn_w == OFF);
            assign InterrputEnable1_Write_Access_w      = ChipWriteAccess_w && (AddrBus_i == ADDR_InterrputEnable1      ) && (ConfigEn_w == ON ) && (IrqConfigEn_w == ON ) && (IrqLvlEn_w == OFF);
            assign InterrputEnable2_Write_Access_w      = ChipWriteAccess_w && (AddrBus_i == ADDR_InterrputEnable2      ) && (ConfigEn_w == ON ) && (IrqConfigEn_w == ON ) && (IrqLvlEn_w == OFF);
            assign RxTrigLevelHigh_Write_Access_w       = ChipWriteAccess_w && (AddrBus_i == ADDR_RxTrigLevelHigh       ) && (ConfigEn_w == ON ) && (IrqConfigEn_w == ON ) && (IrqLvlEn_w == ON );
            assign RxTrigLevelLow_Write_Access_w        = ChipWriteAccess_w && (AddrBus_i == ADDR_RxTrigLevelLow        ) && (ConfigEn_w == ON ) && (IrqConfigEn_w == ON ) && (IrqLvlEn_w == ON );
            assign TxTrigLevelHigh_Write_Access_w       = ChipWriteAccess_w && (AddrBus_i == ADDR_TxTrigLevelHigh       ) && (ConfigEn_w == ON ) && (IrqConfigEn_w == ON ) && (IrqLvlEn_w == ON );
            assign TxTrigLevelLow_Write_Access_w        = ChipWriteAccess_w && (AddrBus_i == ADDR_TxTrigLevelLow        ) && (ConfigEn_w == ON ) && (IrqConfigEn_w == ON ) && (IrqLvlEn_w == ON );
            assign InterruptStatus1_Write_Access_w      = ChipWriteAccess_w && (AddrBus_i == ADDR_InterruptStatus1      ) && (ConfigEn_w == OFF) && (IrqConfigEn_w == OFF) && (IrqLvlEn_w == OFF);
            assign InterruptStatus2_Write_Access_w      = ChipWriteAccess_w && (AddrBus_i == ADDR_InterruptStatus2      ) && (ConfigEn_w == OFF) && (IrqConfigEn_w == OFF) && (IrqLvlEn_w == OFF);
            assign TxDataPort_Write_Access_w            = ChipWriteAccess_w && (AddrBus_i == ADDR_TxDataPort);  
    // UartControl register fresh 
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                UartControl_r1 <= { UartControl_ConfigEn_ON,    UartControl_IrqConfigEn_OFF, 
                                    UartControl_IrqLvlEn_OFF,   UartControl_ClkSel_Time1,
                                    UartControl_RxEn_OFF,       UartControl_TxEn_OFF,
                                    2'b00
                                    }                
            end
            else if (UartControl_Write_Access_w == ON ) begin
                
            end
        end
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
