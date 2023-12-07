`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/05/2023 11:43:54 PM
// Design Name: 
// Module Name: vga_write
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


module vga_write(
    input clk,  // IMPORTANT: For 480x640 image the clock must be 25MHz and main clock is 100MHz
    //input [11:0] bram_readport,
    output wire [3:0] vga_out_r, vga_out_g, vga_out_b,
    output wire vga_out_vs, vga_out_hs
    );

    always @ (*) begin



    end

endmodule