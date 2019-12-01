// -----------------------------------------------------------------------------
// Copyright (c) 2019-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author   :   Javen Peng, pengjaven@gmail.com
// File     :   FIFO_ver1.v
// Create   :   2019-10-19 11:23:02
// Revise   :   2019-10-19 11:23:02
// Editor   :   sublime text3, tab size (4)
// Comment  :   this fifo was built in the module the interface is similar with the 
//              IP core from the microsemi
// 
// Input Signal List:
//      1   :   clk, the system input clock signal, the frequency is greater than 40MHz
//      2   :   rst, the system reset signal, the module should be reset asynchronously,
//                   and must be released synchronously with the clock;
//      3   :   data_i, the data input 
//      4   :   we_i,   write signal
//      5   :   re_i,   read signal
// Output Signal List:
//      1   :   data_o, the data output
//      2   :   empty_o,  the fifo empty signal
//      3   :   full_o, the fifo full signal
// -----------------------------------------------------------------------------
module  FIFO_ver1
#(
    parameter DEPTH = 8'd128,
    )
(
    input           clk,
    input           rst,
    input [7:0]     data_i,
    input           n_we_i,
    input           n_re_i,
    output [7:0]    data_o,
    output          p_empty_o,
    output          p_full_o
    );
    // register definition
        reg [7:0]   memory [DEPTH-1:0];     // the memory
        reg [7:0]   pointer_wr_r;           // the memory pointer for write
        reg [7:0]   pointer_rd_r;           // the memory pointer for read
        reg [7:0]   next_pointer_wr_r;      // the next pointer of the wr pointer
        reg         p_empty_r;
        reg         p_full_r;
        reg [7:0]   output_data_r;
    // wire definition
        wire        p_full_w;
        wire        p_empty_w;
    // parameter definition

    // assign
        assign p_empty_w    = (pointer_wr_r == pointer_rd_r);
        assign p_full_w     = (next_pointer_wr_r == pointer_rd_r);
    // the write pointer fresh
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                pointer_wr_r <= 8'd0;                
            end
            else if ((n_we_i == 1'b0) && (p_full_w == 1'b0)) begin
                pointer_wr_r <= next_pointer_wr_r;
            end
            else begin
                pointer_wr_r <= pointer_wr_r;
            end
        end
    // the next write pointer fresh
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                next_pointer_wr_r <= 8'd1;                
            end
            else if ((n_we_i == 1'b0) && (p_full_w == 1'b0)) begin
                if (next_pointer_wr_r >= DEPTH-1) begin
                    next_pointer_wr_r <= 8'd0;
                end
                else begin
                    next_pointer_wr_r <= next_pointer_wr_r + 1'b1;
                end
            end
            else begin
                next_pointer_wr_r <= next_pointer_wr_r;
            end
        end
    // the read pointer fresh
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                pointer_rd_r <= 8'd1;                
            end
            else if ((n_re_i == 1'b0) && (p_empty_w == 1'b0)) begin
                if (pointer_rd_r >= DEPTH-1) begin
                    pointer_rd_r <= 8'd0;
                end
                else begin
                    pointer_rd_r <= pointer_rd_r + 1'b1;
                end
            end
            else begin
                pointer_rd_r <= pointer_rd_r;
            end
        end
    // Memory fresh
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                // it is too complex to initial the memory array                
            end
            else if ((n_we_i == 1'b0) && (p_full_w == 1'b0)) begin
                memory[pointer_wr_r] <= data_i;
            end
        end
    // output buffer
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                output_data_r <= 8'd0;                
            end
            else if ((n_re_i == 1'b0) && (p_empty_w == 1'b0)) begin
                output_data_r <= memory[pointer_rd_r];
            end
            else begin
                output_data_r <= output_data_r;
            end
        end
endmodule