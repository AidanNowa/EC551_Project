`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2023 06:06:45 PM
// Design Name: 
// Module Name: horizontal_sync
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


module horizontal_sync #(parameter SYNC_SIZE=0)(
    clk,
    rst,
    hsync,
    R,G,B,
    bufferin,
    bufferout
    );
    
    input clk, rst, hsync;
    input [7:0] R, G, B;
    input [SYNC_SIZE-1:0] bufferin;
    output reg [SYNC_SIZE-1:0] bufferout;
    reg [23:0] pixel;
    
    always @(posedge clk) begin
        if (!rst || !hsync) begin
            bufferout <= 0;
        end else begin
            pixel[7:0] <= R;
            pixel[15:8] <= G;
            pixel[23:16] <= B;
            
            bufferout <= {bufferin[SYNC_SIZE-24:0],pixel};
        end
    end
    
endmodule
