`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/05/2023 11:43:54 PM
// Design Name: 
// Module Name: top
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

/**
 * Some notes on the clock signals:
 *  - OV7670 camera has it's own clock signal, which is inputted as cmos_pclk. This is 
 *      synchronized with its data output.
 *  - The VGA must have a clock speed of 25 MHz for 480x640 images
 *  - In the constraints, the default clock speed for the system is 100MHz
 */

module top(
    input sysclk,                                   // FPGA internal clock signal
    input sysrst,                                   // Reset button on FPGA

	// Camera pinouts
	input wire cmos_pclk,                           // Pixel clock 
	input wire cmos_href,                           // HREF signal for data read
	input wire cmos_vsync,                          // VSYNC signal for data read
	input wire[7:0] cmos_db,                        // Data in -> represents half of one pixel
    output wire cmos_sioc,                          // SCCB serial interface clock
    output wire cmos_siod,                          // SCCB serial interface data I/O
//	output reg cmos_rst_n,                          // Resets all camera registers to default values
//	output wire cmos_xclk,                           // System clock (this should be mapped to sysclk)

	//VGA output
	output wire[3:0] vga_out_r,                     // VGA Red signal
	output wire[3:0] vga_out_g,                     // VGA Blue signal
	output wire[3:0] vga_out_b,                     // VGA Green signal
	output wire vga_out_vs,                         // VGA VSYNC signal
	output wire vga_out_hs                          // VGA HSYNC signal
    );

    /** Wires */
    wire config_start = 0;                          // Signal to camera configuration
    wire config_done = 0;                           // Signal when configuration is complete

    wire [15:0] cmos_pixel_data;                    // RGB565 representation of a single pixel
    wire cmos_pixel_valid;                          // Signals if data in cmos_pixel_data is valid
    wire cmos_frame_done;                           // Signals an entire frame has been read

    wire[11:0] downsampled_pixel;                   // RGB444 representation of a single pixel

    wire bram_write_en;                             // Write enable for BRAM
    wire[18:0] bram_write_addr;                     // Write address for BRAM

    wire[11:0] bram_dataout;                        // Output from BRAM controller

    wire vga_frame_done;                            // Signals completion of VGA display
    wire vga_clk;                                   // 25MHz clock signal from VGA write

    /** Assignments */
//    assign cmos_xclk = sysclk;

    /** Modules */
    camera_configure config1 (
        .clk(sysclk),                               // Maybe need to use p_clock?
        .start(config_start),
        .sioc(cmos_sioc),                           // SCCB clock output
        .siod(cmos_siod),                           // SCCB data output
        .done(config_done)
    );

    camera_read read1 (
        .p_clock(cmos_pclk),
        .vsync(cmos_vsync),
        .href(cmos_href),
        .p_data(cmos_db),
        .pixel_data(cmos_pixel_data),
        .pixel_valid(cmos_pixel_valid),
        .frame_done(cmos_frame_done)
    );

    pixel_downsample ds1 (          // Downsamples a pixel from RGB565 to RGB444
        .pixel_data(cmos_pixel_data),
        .ds_pixel(downsampled_pixel)
     );

     bram_memory bram1 (
        .clk_read(vga_clk),
        .clk_write(cmos_pclk),
        .read_en(1'b1),
        .write_en(bram_write_en),
        .read_addr(bram_read_addr),
        .write_addr(bram_write_addr),
        .data_in(downsampled_pixel),
        .data_out(bram_dataout)
     );

    camera_bram_controller bc1 (         
        .sysclk(sysclk),
        .p_clk(cmos_pclk),
        .cmos_frame_done(cmos_frame_done),
        .bram_write_enable(bram_write_en),
        .bram_address(bram_write_addr)
    );

    vga_interface vga1 (
        .sysclk(sysclk),
        .sysrst(sysrst),
        .pixel_data(bram_controller_dout),
        .vga_out_clk(vga_clk),
        .vga_out_r(vga_out_r),
        .vga_out_g(vga_out_g),
        .vga_out_b(vga_out_b),
        .vga_out_vs(vga_out_vs),
        .vga_out_hs(vga_out_hs)
    );
    
endmodule