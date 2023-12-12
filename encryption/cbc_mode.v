`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/05/2023 08:42:37 PM
// Design Name: 
// Module Name: cbc_mode
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


module cbc_mode
    #(
    parameter BLOCK_SIZE=0,
    parameter SYNC_SIZE=0
    )
    (
    key,
    IV,
    enable,
    data_plain,
    data_encrypted,
    );
    
    input [BLOCK_SIZE-1:0] key;
    input enable;
    input [SYNC_SIZE-1:0] IV;
    input [SYNC_SIZE-1:0] data_plain;
    output reg [SYNC_SIZE-1:0] data_encrypted;
    reg [SYNC_SIZE-1:0] previous;
    reg xorimm;
    integer i;
    
    always @(*) begin
        if (enable == 1'b0) begin
            previous = 0;
            xorimm = 0;
        end else begin
            xorimm = 0;
            for(i=0;i<SYNC_SIZE;i=i+1) begin
                // XOR the previous value with the current
                xorimm = data_plain[i] ^ previous[i];
                
                //XOR the xor'd value with the key to make CT
                data_encrypted[i] = xorimm ^ key[i%BLOCK_SIZE];
            end
            
            // store the CT in a reg
            previous = data_encrypted;   
        end 
    end
    
endmodule
