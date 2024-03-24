`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2023/12/26 20:42:37
// Design Name:
// Module Name: counter_start
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

module counter_start(input clk,
                     input rstn,
                     input impulse_1,
                     input impulse_2,
                     input impulse_3,
                     output reg counted);
    reg i1_set, i2_set, i3_set;  // Flags to track if each impulse has been set
    reg [31:0] post_finish_counter; // Counter after all_finished is set
    parameter COUNT_LIMIT = 100; // Number of cycles to count after all_finished
    wire all_finished;
    assign all_finished = i1_set && i2_set && i3_set;

    always @(posedge clk or negedge rstn) begin
        if(!rstn)
        begin
            i1_set              <= 0;
            i2_set              <= 0;
            i3_set              <= 0;
            post_finish_counter <= 0;
            counted             <= 0;
        end
        else if(all_finished) 
        begin
        //counting 
           post_finish_counter <= post_finish_counter + 1;
           counted <= 1;
           if(post_finish_counter > COUNT_LIMIT)
           begin
            //count finished,reset module
            i1_set              <= 0;
            i2_set              <= 0;
            i3_set              <= 0;
            post_finish_counter <= 0;
            counted             <= 0;
           end
        end
        else 
        begin
        //waiting
            if (impulse_1)
                i1_set <= 1;
            if (impulse_2)
                i2_set <= 1;
            if (impulse_3)
                i3_set <= 1;
        end
    end
    /*
    ila_1 counter_start_ila(
    .clk(clk), // input wire clk
    
    
    .probe0(impulse_1), // input wire [0:0]  probe0
    .probe1(impulse_2), // input wire [0:0]  probe1
    .probe2(impulse_3), // input wire [0:0]  probe2
    .probe3(i1_set), // input wire [0:0]  probe3
    .probe4(i2_set), // input wire [0:0]  probe4
    .probe5(i3_set), // input wire [0:0]  probe5
    .probe6(all_finished), // input wire [0:0]  probe6
    .probe7(counted), // input wire [0:0]  probe7
    .probe8(post_finish_counter) // input wire [31:0]  probe8
    );
    */
endmodule
