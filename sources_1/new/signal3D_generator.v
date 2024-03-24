`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2024/03/24 17:55:28
// Design Name:
// Module Name: signal3D_generator
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


module signal3D_generator(input sys_clk,
                          input sys_rst_n,
                          input frame_rdy,
                          input [15:0]xdata_points_number,
                          input [15:0]xdata_block_number,
                          input [15:0]ydata_points_number,
                          input [15:0]cycles_per_points,
                          input [15:0]da_delay_cycles,
                          input [15:0]acq_delay_cycles,
                          input [15:0]ccd_delay_cycles,
                          input [15:0]system_state,
                          input [15:0]sg_x_data,
                          input [15:0]sg_y_data,
                          output [15:0]sg_x_addr,
                          output [15:0]sg_y_addr,
                          output DA_generating,
                          output [13:0] DataA,
                          output [13:0] DataB,
                          output lvds_ccd_p,
                          output lvds_ccd_n,
                          output acq,
                          output proc_finished);
    wire frame3d_rdy;
    localparam scan3d = 3;
    assign frame3d_rdy = system_state==scan3d?frame_rdy:0; 
    DA_gen DA_gen(
    .clk(sys_clk),
    .rstn(sys_rst_n),
    .data_rdy(frame3d_rdy), // Assuming frame3d_rdy is the signal indicating data readiness for SignalGenerator
    .xdata_points_number(xdata_points_number),
    .ydata_points_number(ydata_points_number),
    .cycles_per_points(cycles_per_points),
    .da_delay_cycles(da_delay_cycles),
    .x_addr(sg_x_addr), // sg_x_addr should be declared as a wire in the top module
    .x_data(sg_x_data), // sg_x_data should be connected or processed as required
    .y_addr(sg_y_addr), // sg_y_addr should be declared as a wire in the top module
    .y_data(sg_y_data), // sg_y_data should be connected or processed as required
    .dx(DataA),         // sg_dx should be connected or processed as required
    .dy(DataB),         // sg_dy should be connected or processed as required
    .DA_generating(DA_generating),
    .finished(DA_finished)
    );
    wire ccd_o;
    ccd_gen ccd_gen(
    .clk(sys_clk),
    .rstn(sys_rst_n),
    .data_rdy(frame3d_rdy), // Assuming frame3d_rdy is the signal indicating data readiness for SignalGenerator
    .xdata_points_number(xdata_points_number),
    .xdata_block_number(xdata_block_number),
    .ydata_points_number(ydata_points_number),
    .cycles_per_points(cycles_per_points),
    .ccd_delay_cycles(ccd_delay_cycles),
    .ccd(ccd_o),
    .finished(ccd_finished)
    );
    
    
    OBUFDS #(
    .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
    .SLEW("SLOW")           // Specify the output slew rate
    ) OBUFDS_inst (
    .O(lvds_ccd_p),     // Diff_p output (connect directly to top-level port)
    .OB(lvds_ccd_n),   // Diff_n output (connect directly to top-level port)
    .I(ccd_o)      // Buffer input
    );
    
    acq_gen acq_gen(
    .clk(sys_clk),
    .rstn(sys_rst_n),
    .data_rdy(frame3d_rdy), // Assuming frame3d_rdy is the signal indicating data readiness for SignalGenerator
    .xdata_points_number(xdata_points_number),
    .xdata_block_number(xdata_block_number),
    .ydata_points_number(ydata_points_number),
    .cycles_per_points(cycles_per_points),
    .acq_delay_cycles(acq_delay_cycles),
    .acq(acq),
    .finished(acq_finished)
    );
    counter_start proc_end(
    .clk(sys_clk),
    .rstn(sys_rst_n),
    .impulse_1(DA_finished),
    .impulse_2(acq_finished),
    .impulse_3(ccd_finished),
    .counted(proc_finished)
    );
    
endmodule
