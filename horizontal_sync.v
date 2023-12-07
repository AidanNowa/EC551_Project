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


module horizontal_sync #(parameter HSIZE=768)(
    clk,
    rst,
    hsync,
    R,G,B,
    buffer
    );
    
    input clk, rst, hsync;
    input [7:0] R, G, B;
    output reg [HSIZE-1:0] buffer;
    
    integer counter = 0;
    
    always @(posedge clk) begin
        if (!rst || hsync) begin
            buffer <= 0;
            counter <= 0;
        end else begin
            buffer[counter] <= R;
            buffer[counter+1] <= G;
            buffer[counter+2] <= B;
            counter <= counter + 3;
        end
    end
    
    
    
endmodule
