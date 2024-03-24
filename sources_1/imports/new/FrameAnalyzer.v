`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2023/12/19 21:15:02
// Design Name:
// Module Name: FrameAnalyzer
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
/*
 Data Format
 Data Points Number - Processing Cycles Per Points - ACQ Delay - CCD delay
 */

module FrameAnalyzer(input clk,
                     input rst_n,
                     input data_rdy,                       //PC has finished writing BRAM
                     input [15:0] data,
                     output reg [12:0] addr,
                     output reg FRAME_IS_DONE,
                     output reg[15:0] xdata_points_number,
                     output reg[15:0] xdata_block_number,
                     output reg[15:0] ydata_points_number,
                     output reg[15:0] cycles_per_points,
                     output reg[15:0] da_delay_cycles,
                     output reg[15:0] acq_delay_cycles,
                     output reg[15:0] ccd_delay_cycles,
                     output reg[15:0] system_state);
    
    wire is_start;
    reg data_rdy_d0,data_rdy_d1;
    assign is_start = data_rdy_d0 & (~data_rdy_d1);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_rdy_d0 <= 1'b0;
            data_rdy_d1 <= 1'b0;
        end
        else begin
            data_rdy_d0 <= data_rdy;
            data_rdy_d1 <= data_rdy_d0;
        end
    end
    
    reg [4:0] curr,next;  // State variable to manage the read process
    localparam IDLE               = 4'd0;
    localparam waitCycles         = 4'd1;
    localparam xDataPointsNumber  = 4'd2;
    localparam xDataBlockNumber   = 4'd3;
    localparam yDataPointsNumber  = 4'd4;
    localparam CyclesPerPoints    = 4'd5;
    localparam DADelayCycles      = 4'd6;
    localparam AcqDelayCycles     = 4'd7;
    localparam CcdDelayCycles     = 4'd8;
    localparam SysStateDescriptor = 4'd9;
    localparam DONE               = 4'd15;
    reg read_enable;  // Flag to enable reading from BRAM
    reg[31:0] waiting_cntr;
    reg waited;
    localparam CyclePPoints1k = 50000;
    //Transition Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
        begin
            curr <= IDLE;
        end
        else
        begin
            curr <= next;
        end
    end
    //State Jump Table
    always @(*)begin
        case (curr)
            IDLE:next               = is_start?waitCycles:IDLE;
            waitCycles:next         = waited?xDataPointsNumber:waitCycles;
            xDataPointsNumber:next  = xDataBlockNumber;
            xDataBlockNumber:next   = yDataPointsNumber;
            yDataPointsNumber:next  = CyclesPerPoints;
            CyclesPerPoints:next    = DADelayCycles;
            DADelayCycles:next      = AcqDelayCycles;
            AcqDelayCycles:next     = CcdDelayCycles;
            CcdDelayCycles:next     = SysStateDescriptor;
            SysStateDescriptor:next = DONE;
            DONE:next               = IDLE;
        endcase
    end
    
    //Behaviour Logic
    always @(posedge clk) begin
        case(curr)
            IDLE:
            begin
                FRAME_IS_DONE <= 0;
                if (is_start)
                begin
                    addr         <= 0;
                    waiting_cntr <= 0;
                    waited       <= 0;
                end
            end
            waitCycles:
            begin
                if (waiting_cntr == 0)
                begin
                    waited <= 1;
                    addr   <= addr + 2;
                end
                else waiting_cntr <= waiting_cntr+1;
            end
            xDataPointsNumber:
            begin
                addr                <= addr+2;
                xdata_points_number <= data;
            end
            xDataBlockNumber:
            begin
                addr               <= addr +2;
                xdata_block_number <= data;
            end
            yDataPointsNumber:
            begin
                addr                <= addr+2;
                ydata_points_number <= data;
            end
            CyclesPerPoints:
            begin
                addr              <= addr+2;
                cycles_per_points <= data;
            end
            DADelayCycles:
            begin
                addr            <= addr+2;
                da_delay_cycles <= data;
            end
            AcqDelayCycles:
            begin
                addr             <= addr;
                acq_delay_cycles <= data;
            end
            CcdDelayCycles:
            begin
                addr             <= addr;
                ccd_delay_cycles <= data;
            end
            SysStateDescriptor:
            begin
                addr         <= addr;
                system_state <= data;
            end
            DONE:
            begin
                FRAME_IS_DONE <= 1;
            end
        endcase
    end
endmodule
