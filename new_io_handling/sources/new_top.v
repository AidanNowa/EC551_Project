`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2023 09:02:28 PM
// Design Name: 
// Module Name: new_top
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

module new_top(
    input clk,                // FPGA internal clock. Ensure this is correctly set in your FPGA constraints.
    input rst,                // Reset button. Active when pressed.

    // Camera pinouts
    input cmos_sda,           // I2C data line for camera configuration.
    input cmos_scl,           // I2C clock line for camera configuration.
    input wire cmos_pclk,     // Pixel clock from camera. Synchronize data capture with this clock.
    input wire cmos_href,     // HREF signal from camera, indicates valid data in each row.
    input wire cmos_vsync,    // VSYNC signal from camera, indicates the start/end of a frame.
    input wire [7:0] cmos_db, // Data bus from camera. Carries pixel data.
    output reg cmos_rst_n,    // Reset signal for camera. Active low.
    output reg cmos_pwdn,     // Power down signal for camera. Active high.
    output reg cmos_xclk,     // External clock signal for camera. Can be derived from FPGA clock.

    // VGA output
    output wire [3:0] vga_out_r, // 4-bit Red channel for VGA output.
    output wire [3:0] vga_out_g, // 4-bit Green channel for VGA output.
    output wire [3:0] vga_out_b, // 4-bit Blue channel for VGA output.
    output wire vga_out_vs,      // Vertical sync for VGA.
    output wire vga_out_hs       // Horizontal sync for VGA.
);

    // Internal signals
    reg read_enable;    // Enable signal for reading from frame buffer to VGA.
    reg write_enable;   // Enable signal for writing to frame buffer from camera.
    reg take_img;       // Signal to start image capture process.
    reg [18:0] mem_addr;   // Address for BRAM (frame buffer).
    reg [11:0] write_data; // Data to be written to BRAM.
    wire [11:0] read_data;  // Data read from BRAM.

    // Configuration signals
    wire config_done, config_start; // Signals to start and acknowledge configuration of camera.

    // Camera outputs
    wire ready, pixel_valid, frame_done; // Status signals from camera reading module.
    wire [15:0] pixel_data;              // 16-bit RGB565 pixel data from camera.
    wire [11:0] ds_pixel;                // Downsampled 12-bit RGB444 pixel data.

    // State machine states for controlling the flow of operation
    localparam IDLE = 2'b00,
               READ_FRAME = 2'b01,
               PROCESS_FRAME = 2'b10,
               WRITE_FRAME = 2'b11;

    reg [1:0] current_state, next_state;
    reg [9:0] row_counter = 0; // 10 bits for 480 rows (0 to 479)
    reg [9:0] col_counter = 0; // 10 bits for 640 columns (0 to 639)

    // BRAM for frame buffer - stores image data
    // Replace 'bram' with your actual BRAM module
    // Ensure that memory size and data width match your requirements
    bram memory(
        .clk_read(cmos_pclk),   // Read clock synchronized with camera pixel clock.
        .clk_write(clk),        // Write clock synchronized with FPGA clock.
        .read(read_enable),     // Read enable signal.
        .write(write_enable),   // Write enable signal.
        .addr(mem_addr),        // Address for read/write operations.
        .data_in(ds_pixel),   // Data input for write operations.
        .data_out(read_data)    // Data output for read operations.
    );

    // Camera configuration module
    // Replace 'camera_configure' with your actual module
    // Ensure that all necessary configurations are included for your camera model
//    camera_configure m0(
//        .clk(clk),
//        .start(config_start),
//        .sioc(cmos_sda),
//        .siod(cmos_scl),
//        .done(config_done)
//    );

    // Camera reading module - captures data from camera
    // Replace 'camera_read' with your actual module
    // Make sure it correctly interprets HREF, VSYNC, and pixel data
    camera_read m1 (
        .p_clock(cmos_pclk),
        .vsync(cmos_vsync),
        .href(cmos_href),
        .p_data(cmos_db),
        .pixel_data(pixel_data),
        .pixel_valid(pixel_valid),
        .frame_done(frame_done)
    );

    // Pixel downsampling module - converts RGB565 to RGB444
    // Replace 'pixel_downsample' with your actual module
    // Ensure that the conversion maintains color fidelity as much as possible
    pixel_downsample m2 (
        .pixel_data(pixel_data),
        .ds_pixel(ds_pixel)
    );
    
    // VGA Interface Module - sends image data to VGA output
    vga_interface vga_display (
        .clk(clk),
        .rst(rst),
        .display_enable(read_enable), // Control signal to enable VGA display
        .bram_readport(read_data),       // Connect to BRAM read port
        .vga_out_r(vga_out_r),
        .vga_out_g(vga_out_g),
        .vga_out_b(vga_out_b),
        .vga_out_vs(vga_out_vs),
        .vga_out_hs(vga_out_hs)
    );

//    // Main State Machine Logic - controls the overall operation flow
//    initial begin
//        config_start <= 1;  // Start camera configuration at initialization
//        config_done <= 0;   // Flag to indicate when configuration is complete
//    end

    always @(posedge clk) begin
        if (rst) current_state <= IDLE;  // Reset to IDLE state on reset signal
        else current_state <= next_state;
    end

    always @(posedge clk) begin
        if (rst) begin
            // Reset logic
            current_state <= IDLE;
            col_counter <= 0;
            row_counter <= 0;
            read_enable <= 0;
            write_enable <= 0;
        end
        else begin
            case (current_state)
                IDLE: begin
                    if (take_img) begin
                        // Start image capture
                        take_img <= 0;
                        next_state = READ_FRAME;
                    end
                    else 
                        next_state = IDLE;
                end
                READ_FRAME: begin
                    if (pixel_valid) begin
                        // Capture pixel data and downsample it
                        write_enable <= 1;
                        write_data <= ds_pixel; // Downsampled data
                        mem_addr <= row_counter * 640 + col_counter;
                        // Update row and column counters
                        col_counter <= (col_counter < 639) ? col_counter + 1 : 0;
                        row_counter <= (col_counter == 639) ? ((row_counter < 479) ? row_counter + 1 : 0) : row_counter;
                    end
                    if (frame_done) begin
                        // Frame capture complete
                        write_enable <= 0;
                        next_state = PROCESS_FRAME;
                    end
                    else 
                        next_state = READ_FRAME;
                end
                PROCESS_FRAME: begin
                    // Additional image processing (if any)
                    // Set display_enable to start showing the image
                    read_enable <= 1;
                    next_state = WRITE_FRAME;
                end
                WRITE_FRAME: begin
                    // Currently displaying the frame
                    // Wait for the end of frame display or a condition to load the next frame
                    // For simplicity, let's return to IDLE
                    // In a real application, you might want to wait for a signal to load the next frame
                    next_state = IDLE;
                    read_enable <= 0; // Reset display_enable for the next frame
                end
                default: next_state = IDLE;
            endcase
        end
    end
    
    
    
endmodule
