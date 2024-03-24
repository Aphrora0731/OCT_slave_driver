`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2023/12/12 22:08:48
// Design Name:
// Module Name: write_bram
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module write_bram(input clk,
                  input rst_n,
                  input proc_end,
                  input[7:0] data2write,
                  input data_rdy,
                  output reg ram_write_enable,
                  output reg[13:0] ram_addr,
                  output reg[7:0] ram_w_data
                  );
    reg[13:0] addr_cntr;
    reg data_rdy_d;
    
    wire data_rdy_posedge;
    assign data_rdy_posedge = data_rdy && !data_rdy_d;
    
    always@(posedge clk or negedge rst_n)
    begin
        if (!rst_n||proc_end)
        begin
            addr_cntr        <= 0;
            data_rdy_d       <= 0;
            ram_write_enable <= 0;
        end
        else begin
            data_rdy_d <= data_rdy;
            if (data_rdy_posedge)
            begin
                ram_write_enable <= 1;
                ram_addr         <= addr_cntr;
                ram_w_data       <= data2write;
                
                addr_cntr <= addr_cntr+1;
            end
        end
    end
   
endmodule
