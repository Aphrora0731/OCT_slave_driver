`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/25 19:04:22
// Design Name: 
// Module Name: interconnect
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

//signal NEED to manage:
//condition:
//addr:
//data:
module interconnect(
    input clk,
    input rstn, 

    input w_finished,
    input DA_2Dgenerating,
    input DA_3Dgenerating,

    input[15:0] w_addr,
    input[15:0] addr3d,
    input[15:0] addr2d,
    input[15:0] addr_frame,

    output[15:0] addra,
    output[15:0] addrb,

    input[15:0] douta,
    input[15:0] doutb,

    output[15:0] data2d,
    output[15:0] data3d,
    output[15:0] data_frame
    );
    localparam IDLE=0;
    localparam FrameAnalyzer=1;
    localparam scan2d=2;
    localparam scan3d=3;
    localparam write_bram=4;
    reg[1:0] current_state,next_state;
    always @(*) begin
      if(!w_finished)
      begin
         addra= w_addr;
      end
    end
endmodule
