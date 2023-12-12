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
    output [SYNC_SIZE-1:0] data_encrypted;
    
    genvar i;
    
    for(i=0;i<SYNC_SIZE;i=i+1) begin
        ecb_enc_1bit ECB_ENC_1B(.K(key[i%BLOCK_SIZE]), .PT(data_plain[i]), .CT(data_encrypted[i]));
    end
    

		  
endmodule
