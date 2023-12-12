`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/05/2023 12:59:56 PM
// Design Name: 
// Module Name: param_lsfr
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


// using a 32 bit Left Shift Feed Back Register as PRNG
// this will spit out psuedo-random numbers for keys
module param_lfsr #(parameter BLOCK_SIZE=0)(clk, rst, enable, Y);
    // coeff tap seed is just alternating ones
    // I just put a random vector
    parameter tap_coeff = {12'b1000100111,12'b1010100100,8'b10111001};
    parameter initial_state = 32'h0ad4eaf31;
    integer i;
    
    input clk;
    input rst;
    input enable;
    output reg [BLOCK_SIZE-1:0] Y;
        
    always @(posedge clk) begin
        if (!rst || !enable)
            Y <= initial_state;
        else begin
            for (i=1;i<BLOCK_SIZE;i=i+1) begin
                if (tap_coeff[i] == 1'b1)
                    Y[i] <= Y[i-1] ^ Y[BLOCK_SIZE-1];
                else
                    Y[i] <= Y[i-1];
                    Y[0] <= Y[BLOCK_SIZE-1];
            end
        end
    end //always block
endmodule
