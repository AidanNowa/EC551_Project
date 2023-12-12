`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/05/2023 11:43:54 PM
// Design Name: 
// Module Name: pixel_downsample
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


module pixel_downsample(
    input [15:0] pixel_data,
    output wire [11:0] ds_pixel
    );


    assign ds_pixel[11:8] = pixel_data[15:12];    // Red
    assign ds_pixel[7:4] = pixel_data[10:7];      // Green
    assign ds_pixel[3:0] = pixel_data[4:1];       // Blue


endmodule
