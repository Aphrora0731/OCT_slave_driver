`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2023/12/22 16:11:44
// Design Name:
// Module Name: DA_gen
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


module DA_gen(input clk,
              input rstn,
              input data_rdy,
              input[15:0] xdata_points_number,
              input[15:0] ydata_points_number,
              input[15:0] cycles_per_points,
              input[15:0] da_delay_cycles,
              output[13:0] x_addr,
              input[15:0] x_data,
              output[13:0] y_addr,
              input[15:0] y_data,
              output reg[13:0] dx,
              output reg[13:0] dy,
              output DA_generating,
              output reg finished);
    
    reg[3:0] curr,next;
    reg waited;
    
    localparam IDLE       = 0;
    localparam WAITING    = 1;
    localparam GENERATING = 2;
    
    
    reg[15:0] xnum_cntr,ynum_cntr;
    reg[15:0] x_addr_cntr,y_addr_cntr;
    reg[15:0] point_cntr;
    reg[31:0] wait_cntr;
    always @(posedge clk or negedge rstn) begin
        if (!rstn)curr <= IDLE;
        else curr      <= next;
    end
    always @(*) begin
        case (curr)
            IDLE:next       = data_rdy?WAITING:IDLE;
            WAITING:next    = waited?GENERATING:WAITING;
            GENERATING:next = finished?IDLE:GENERATING;
        endcase
    end
    always @(posedge clk) begin
        case (curr)
            IDLE:
            begin
                finished    <= 0;
                xnum_cntr   <= 0;
                ynum_cntr   <= 0;
                x_addr_cntr <= 0;
                y_addr_cntr <= 0;
                point_cntr  <= 0;
                wait_cntr   <= 0;
                waited      <= 0;
                //should be at original point
                dx<=8192;
                dy<=8192;
            end
            WAITING:
            begin
                wait_cntr <= wait_cntr + 1;
                if (wait_cntr == da_delay_cycles*cycles_per_points)
                begin
                    waited <= 1;
                end
            end
            GENERATING:
            begin
                dx <= x_data[13:0];
                dy <= y_data[13:0];
                if (xnum_cntr <xdata_points_number)
                begin
                    point_cntr <= point_cntr + 1;
                    if (point_cntr == cycles_per_points)
                    begin
                        point_cntr  <= 0;
                        xnum_cntr   <= xnum_cntr+1;
                        x_addr_cntr <= x_addr_cntr+2;
                    end
                end
                else if (ynum_cntr<ydata_points_number-1)
                begin
                    xnum_cntr   <= 0;
                    x_addr_cntr <= 0;
                    ynum_cntr   <= ynum_cntr+1;
                    y_addr_cntr <= y_addr_cntr+2;
                end
                else begin
                    finished <= 1;
                end
            end
        endcase
    end
    localparam HeaderLength = 16;
    assign x_addr           = x_addr_cntr+HeaderLength;
    assign y_addr           = y_addr_cntr+HeaderLength+xdata_points_number*2+1;
    assign DA_generating    = !(curr == IDLE);
endmodule
