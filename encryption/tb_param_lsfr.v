`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/05/2023 01:34:52 PM
// Design Name: 
// Module Name: tb_param_lsfr
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


module tb_param_lsfr(

    );
    
    parameter BLOCK_SIZE = 32;
    reg clk;
    reg reset;
    reg enable;
    wire [BLOCK_SIZE:0] Y;
    
    param_lfsr #(.BLOCK_SIZE(BLOCK_SIZE))LSFR(.clk(clk), .reset(reset), .enable(enable), .Y(Y));
    
    initial begin
        clk = 1'b1;
        reset = 1'b0;
        enable = 1'b1;

//        // ACTIVE LOW RESET
        #5 reset = 1'b1;
    end
    
    // clock is 10ns
    always begin
        #5 clk = ~clk;
    end
    
endmodule
