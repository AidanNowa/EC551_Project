`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2023 07:02:22 PM
// Design Name: 
// Module Name: bram
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


module bram_memory(
    input clk_read,
    input clk_write,
    input cmos_pixel_valid,
    input read_en,
    input write_en,
    input [18:0] read_addr,
    input [18:0] write_addr,
    input [11:0] data_in,
    output reg [11:0] data_out
);

    //reg [11:0] memory [0:30199]; // Adjusted size for 640x480 image
    reg [11:0] memory [307199:0]; // Adjusted size for 640x480 image


    /** Read port */
    always @(posedge clk_read) begin
        if (read_en) data_out <= memory[read_addr];
    end

    /** Write port */
    always @(posedge clk_write) begin
        if (write_en && cmos_pixel_valid) memory[write_addr] <= data_in;
        else if (write_en && !cmos_pixel_valid) memory[write_addr] <= 12'b0;
    end

endmodule

