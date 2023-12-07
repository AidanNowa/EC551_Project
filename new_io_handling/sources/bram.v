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


module bram(
    input clk_read,
    input clk_write,
    input read,
    input write,
    input [18:0] addr,
    input [11:0] data_in,
    output reg [11:0] data_out
);

    reg [11:0] memory [0:307199]; // Adjusted size for 640x480 image

    always @(posedge clk_read) begin
        if (read) data_out <= memory[addr];
    end

    always @(posedge clk_write) begin
        if (write) memory[addr] <= data_in;
    end

endmodule

