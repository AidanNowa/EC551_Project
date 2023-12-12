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


module ecb_mode
    #(
    parameter BLOCK_SIZE=0,
    parameter SYNC_SIZE=0
    )
    (
    key,
    enable,
    data_plain,
    data_encrypted,
    );
    
    input [BLOCK_SIZE-1:0] key;
    input enable;
    input [SYNC_SIZE-1:0] data_plain;
    output reg [SYNC_SIZE-1:0] data_encrypted;
    reg [SYNC_SIZE-1:0] previous;
    integer i;
    
    always @(*) begin
        if (enable == 1'b1) begin
            for(i=0;i<SYNC_SIZE;i=i+1) begin
                data_encrypted[i] = data_plain[i] ^ key[i%BLOCK_SIZE];
            end  
        end 
    end
    

		  
endmodule
