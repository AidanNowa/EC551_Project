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
    input clk,                                      //fpga internal clock
    input rst,                                      // button (?)

	// Camera pinouts
	input cmos_sda,                                 //camera config?
	input cmos_scl,                                 //camera config?
	input wire cmos_pclk,                           //camera internal clock
	input wire cmos_href,                           // For reading data- change low->high->low at end of line
	input wire cmos_vsync,                          // signals end of frame - stay low until high @ end of frame (?)
	input wire[7:0] cmos_db,                        // data input (!!) note: two clock cycles needed to input full pixel data
	output reg cmos_rst_n,                          //reset
	output reg cmos_pwdn,                           // ?
	output reg cmos_xclk,                           // ? maybe system clock

	//VGA output
	output wire[3:0] vga_out_r,                     //4-bit r in rbg; per pixel
	output wire[3:0] vga_out_g,                     //"" g
	output wire[3:0] vga_out_b,                     //"" b
	output wire vga_out_vs,                            
	output wire vga_out_hs
    );
    
    reg read_enable;                               // Control signal for VGA controller
    reg write_enable;
    
    reg take_img;
    
    reg [18:0] mem_addr;
    reg [11:0] write_data;
    wire [11:0] read_data;
    
    // Config wires
    reg config_done, config_start;
    
    //camera outputs
    wire ready, pixel_valid, frame_done;            // Control signals from camera read
    wire [15:0] pixel_data;                         // pixel read from camera in RGB565
    wire [11:0] ds_pixel;                           // pixel downsampled to RGB444 (req. for VGA)

    localparam IDLE = 2'b00,
               READ_FRAME = 2'b01,
               PROCESS_FRAME = 2'b10,
               WRITE_FRAME = 2'b11;

    reg [1:0] current_state, next_state;

        
    bram memory(
        .clk_read(cmos_pclk),                       //sync read with camera clock
        .clk_write(clk),                            //sync write with vga clock
        .read(read_enable),                         //set read
        .write(write_enable),                       //set write
        .addr(mem_addr),                            //address to read or write
        .data_in(write_data),                       //data from camera
        .data_out(read_data)                        //data to output to vga
    );
        
    camera_configure m0(
        .clk(clk),
        .start(config_start),
        .sioc(cmos_sda),
        .siod(cmos_scl),
        .done(config_done)
    );

    
     camera_read m1 (                             // Read a single pixel from the camera
         .p_clock(cmos_pclk),
         .vsync(cmos_vsync),
         .href(cmos_href),
         .p_data(cmos_db),
         .pixel_data(pixel_data),
         .pixel_valid(pixel_valid),
         .frame_done(frame_done)
     );
    
     pixel_downsample m2 (                        // Module to downsample a pixel from 16-bit RGB565 to 12-bit RGB444
         .pixel_data(pixel_data),
         .ds_pixel(ds_pixel)
     );
        
    
    vga_write m5 (                                // VGA controller - gets passed bram ports, then writes frame to VGA port
        .clk(clk),
        .rst(rst),
        .display_enable(read_enable),
        //.bram_readport(bram_readport),
        .vga_out_r(vga_out_r),
        .vga_out_g(vga_out_g),
        .vga_out_b(vga_out_b),
        .vga_out_vs(vga_out_vs),
        .vga_out_hs(vga_out_hs)
    );
    


    /**
     * Main always block:
     *  1. Read pixels from camera into frame_buffer until frame_done output is 1
     *  2. Image transformations are performed on the frame_buffer
     *  3. Send transformed images to VGA out
     */

    
    initial begin                                   // Configure camera module
        config_start <= 1;
        config_done <= 0;


    end

    always @(posedge clk) begin
        if (rst) current_state <= IDLE;
        else current_state <= next_state;
    end
    
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (take_img) 
                    next_state = READ_FRAME;
                else 
                    next_state = IDLE;
            end
            READ_FRAME: begin
                if (frame_done) begin
                    next_state = PROCESS_FRAME;
                    take_img <= 0;
                end
                else 
                    next_state = READ_FRAME;
            end
            PROCESS_FRAME: begin
                // Processing logic here
                next_state = WRITE_FRAME;
            end
            WRITE_FRAME: begin
                // Writing to VGA logic here
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Logic for handling read_enable, write_enable, etc., based on the current state
    always @(posedge clk) begin
        case (current_state)
            READ_FRAME: begin
                read_enable <= 0;
                write_enable <= 1;
                // Additional logic for reading a frame
            end
            PROCESS_FRAME: begin
                // Logic for processing the frame
            end
            WRITE_FRAME: begin
                read_enable <= 1;
                write_enable <= 0;
                // Additional logic for writing the frame
            end
            default: begin
                read_enable <= 0;
                write_enable <= 0;
            end
        endcase
    end
    
        
        


        // An entire frame has been read from the camera
        // Do transformations and write to VGA out

        // Eventually this should get covered in transformations module!!
            // transformations m4 (
            //     // Transformations module
            //     // Pulls image from bram, does transformations, and writes back to bram
            //     // Should be a case statement, with FPGA switched used to determine operation
            // );

        // Reset signals once frame has been written to VGA
        //    frame_done <= 0;
        //    clear_buffer <= 1;


    
    
endmodule