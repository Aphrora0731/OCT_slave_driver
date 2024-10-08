//****************************************Copyright (c)***********************************//
//Copyright(C) Wayne Lu 2023-2123
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           top.v
// Last modified Date:  2023/12/29 20:56:10
// Last Version:        V1.0
// Descriptions:        top module
//----------------------------------------------------------------------------------------
// Created by:          Wayne Lu
// Created date:        2023/6/9 9:55:36
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module top(input sys_clk,
           input sys_rst_n,
           input uart_rxd,
           output uart_txd,
           output ClkA,
           output ClkB,
           output WRTA,
           output WRTB,
           output [13:0]DataA,
           output [13:0]DataB,
          // output sign_ccd,
           output lvds_ccd_p,
           output lvds_ccd_n,
           output acq);
    assign ClkA       = sys_clk;
    assign ClkB       = sys_clk;
    assign WRTA = sys_clk;
    assign WRTB = sys_clk;
    //parameter define
    parameter  CLK_FREQ = 50000000;
    parameter  UART_BPS = 115200;
    
    //wire define
    wire       uart_recv_done;
    wire [7:0] uart_recv_data;
    wire       uart_send_en;
    wire [7:0] uart_send_data;
    wire       uart_tx_busy;
    
    //*****************************************************
    //**                    main code
    //*****************************************************
    
    
    uart_recv #(
    .CLK_FREQ       (CLK_FREQ),
    .UART_BPS       (UART_BPS))
    u_uart_recv(
    .sys_clk        (sys_clk),
    .sys_rst_n      (sys_rst_n),
    
    .uart_rxd       (uart_rxd),
    .uart_done      (uart_recv_done),
    .uart_data      (uart_recv_data)
    );
    
    
    uart_send #(
    .CLK_FREQ       (CLK_FREQ),
    .UART_BPS       (UART_BPS))
    u_uart_send(
    .sys_clk        (sys_clk),
    .sys_rst_n      (sys_rst_n),
    
    .uart_en        (uart_send_en),
    .uart_din       (uart_send_data),
    .uart_tx_busy   (uart_tx_busy),
    .uart_txd       (uart_txd)
    );
    
    uart_handler uart_handler(
    .sys_clk        (sys_clk),
    .sys_rst_n      (sys_rst_n),
    
    .recv_done      (uart_recv_done),
    .recv_data      (uart_recv_data),
    
    .tx_busy        (uart_tx_busy),
    .send_en        (uart_send_en),
    .send_data      (uart_send_data)
    );
    
    
    reg proc_begin;
    wire ram_write_enable;
    wire[7:0]w_data;
    wire[13:0]w_addr;
    
    reg w_finished;
    reg[15:0]w_finish_cntr;
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n)
        begin
            w_finish_cntr <= 0;
            w_finished    <= 0;
        end
        else begin
            if (uart_recv_done)
            begin
                w_finish_cntr <= 0;
            end
            else begin
                if (proc_begin)
                begin
                    if (w_finish_cntr<10000)
                    begin
                        w_finish_cntr <= w_finish_cntr + 1;
                    end
                    else
                    begin
                        w_finished <= 1;
                    end
                end
                else begin
                    w_finish_cntr <= 0;
                    w_finished    <= 0;
                end
            end
        end
    end
    
    wire proc_finished;
    write_bram write_data(
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .proc_end(proc_finished),
    
    .data2write(uart_recv_data),
    .data_rdy(uart_recv_done),
    
    .ram_write_enable(ram_write_enable),
    .ram_addr (w_addr),
    .ram_w_data(w_data)
    
    );
    
    reg [15:0] frame_data;
    wire [12:0] frame_addr;
    wire frame_rdy;
    wire s_en;
    
    wire[13:0] x_addr,y_addr;
    wire[15:0] x_data,y_data;
    wire[15:0] xdata_points_number,xdata_block_number,ydata_points_number,cycles_per_points,da_delay_cycles,acq_delay_cycles,ccd_delay_cycles;
    
    FrameAnalyzer u_FrameAnalyzer(
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .data_rdy(w_finished),
    
    .data(frame_data),
    .addr(frame_addr),
    
    .FRAME_IS_DONE(frame_rdy),
    .xdata_points_number(xdata_points_number),
    .xdata_block_number(xdata_block_number),
    .ydata_points_number(ydata_points_number),
    .cycles_per_points(cycles_per_points),
    .da_delay_cycles(da_delay_cycles),
    .acq_delay_cycles(acq_delay_cycles),
    .ccd_delay_cycles(ccd_delay_cycles)
    );
    
    wire[13:0] sg_x_addr, sg_y_addr;
    reg[15:0] sg_x_data, sg_y_data;
    
    wire DA_generating,DA_finished,ccd_finished,acq_finished;
    DA_gen DA_gen(
    .clk(sys_clk),
    .rstn(sys_rst_n),
    .data_rdy(frame_rdy), // Assuming frame_rdy is the signal indicating data readiness for SignalGenerator
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
    .data_rdy(frame_rdy), // Assuming frame_rdy is the signal indicating data readiness for SignalGenerator
    .xdata_points_number(xdata_points_number),
    .xdata_block_number(xdata_block_number),
    .ydata_points_number(ydata_points_number),
    .cycles_per_points(cycles_per_points),
    .ccd_delay_cycles(ccd_delay_cycles),
    .ccd(ccd_o),
    .finished(ccd_finished)
    );
    //assign sign_ccd = ccd_o;
    

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
    .data_rdy(frame_rdy), // Assuming frame_rdy is the signal indicating data readiness for SignalGenerator
    .xdata_points_number(xdata_points_number),
    .xdata_block_number(xdata_block_number),
    .ydata_points_number(ydata_points_number),
    .cycles_per_points(cycles_per_points),
    .acq_delay_cycles(acq_delay_cycles),
    .acq(acq),
    .finished(acq_finished)
    );
    reg[31:0] proc_cntr;
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            proc_begin <= 0;
        end
        else
        begin
            if (uart_recv_done) begin
                proc_begin <= 1;
            end
            else begin
                //Just to cooperating stupid code formatter.
            end
            if (proc_finished)
            begin
                proc_begin <= 0;
            end
        end
    end
    counter_start proc_end(
    .clk(sys_clk),
    .rstn(sys_rst_n),
    .impulse_1(DA_finished),
    .impulse_2(acq_finished),
    .impulse_3(ccd_finished),
    .counted(proc_finished)
    );
    
    reg[13:0] addra,addrb;
    wire[15:0] douta,doutb;
    
    // Combinational logic for address selection
    always @(*) begin
        if (!w_finished) begin
            addra = w_addr; // Accepting serial data from PC
        end
        else if (DA_generating) begin
            addra = sg_x_addr; // Controlling devices
        end
        else begin
            addra = frame_addr; // Analyzing data frame
        end
    end
    always @(posedge sys_clk) begin
        if (DA_generating) begin
            // Route douta to sg_x_data when DA_generating is high
            sg_x_data <= douta;
            sg_y_data <= doutb;
            end else begin
            // Route douta to frame_data when DA_generating is low
            frame_data <= douta;
        end
    end
    
    blk_mem_gen_0 data_holder (
    .clka(sys_clk),    // input wire clka
    .wea(!w_finished),      // input wire [0 : 0] wea
    .addra(addra),  // input wire [13 : 0] addra
    .dina(w_data),    // input wire [7 : 0] dina
    .douta(douta),
    
    
    .clkb(sys_clk),    // input wire clkb
    .web(0),
    .addrb(sg_y_addr),  // input wire [12 : 0] addrb
    .doutb(doutb)  // output wire [15 : 0] doutb
    );
    
    ila_0 top_ila (
    .clk(sys_clk), // input wire clk
    
    
    .probe0(xdata_points_number), // input wire [15:0]  probe0
    .probe1(xdata_block_number), // input wire [15:0]  probe1
    .probe2(ydata_points_number), // input wire [15:0]  probe2
    .probe3(cycles_per_points), // input wire [15:0]  probe3
    .probe4(da_delay_cycles), // input wire [15:0]  probe4
    .probe5(w_finished), // input wire [0:0]  probe5
    .probe6(ccd_finished), // input wire [0:0]  probe6
    .probe7(DA_finished), // input wire [0:0]  probe7
    .probe8(acq_finished), // input wire [0:0]  probe8
    .probe9(proc_finished), // input wire [0:0]  probe9
    .probe10(proc_begin), // input wire [0:0]  probe10
    .probe11(frame_rdy), // input wire [0:0]  probe11
    .probe12(DA_generating), // input wire [0:0]  probe12
    .probe13(uart_recv_done), // input wire [0:0]  probe13
    .probe14(ccd), // input wire [0:0]  probe14
    .probe15(A),
    .probe16(B)
    );
    
endmodule
