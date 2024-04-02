`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/13 12:56:12
// Design Name: 
// Module Name: top_tb
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

`timescale 1ns / 1ps

module tb_process();

    // Testbench signals
    reg sys_clk;
    reg sys_rst_n;
    reg uart_rxd;
    wire uart_txd;

    // Instantiate the top module
    top uut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .uart_rxd(uart_rxd),
        .uart_txd(uart_txd)
    );

    // Clock generation (50MHz)
    initial begin
        sys_clk = 0;
        forever #10 sys_clk = ~sys_clk; // 50MHz clock
    end

    // Reset generation
    initial begin
        sys_rst_n = 0;
        #100;
        sys_rst_n = 1; // Release reset after 100ns
    end

    // UART receive data simulation
    task uart_write_byte;
        input [7:0] data;
        integer i;
        begin
            uart_rxd = 0; // Start bit
            #8680; // 1/115200 s in ns
            for (i = 0; i < 8; i = i + 1) begin
                uart_rxd = data[i];
                #8680; // Bit time
            end
            uart_rxd = 1; // Stop bit
            #8680; // Stop bit time
        end
    endtask
    
    task generate_byte_flow;
    input integer file;
    integer ch;
    begin
        // Assuming file is already opened and file descriptor is passed as an argument
        ch = $fgetc(file);
        $display(ch);
        while (ch != -1) begin
            uart_write_byte(ch);
            #1000;  // Delay between bytes, adjust as needed
            ch = $fgetc(file);
        end
    end
    endtask
    
    integer file;
    integer i;
    initial begin
        uart_rxd = 1; // UART idle state
        #200000; // Wait for some time after reset
        
        file = $fopen("D:\\XilinxProjects\\OCT_DDS_driver_verification\\bytes.bin","rb");
        if (file == 0) 
        begin
            $display("Error: Failed to open file");
            $finish;
        end

        // Call the task
    for (i = 0; i< 3; i=i + 1) begin
        $fseek(file, 0, 0); // Reset file pointer to beginning
        generate_byte_flow(file);
        #10000000; // Wait time between repetitions, adjust as needed
    end
    //uart_write_byte(8'h55);
        // Close the file
        $fclose(file);
        #60000
        
        
        $finish; // Finish the simulation
    end
endmodule
