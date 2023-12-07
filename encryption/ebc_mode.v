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


module ebc_mode
    #(
    parameter BLOCK_SIZE=32,
    parameter HSIZE=768
    )
    (
    key,
    enable,
    image_row,
    ciphertext_enc,
    plaintext_dec
    );
    
    input [BLOCK_SIZE-1:0] key;
    input enable;
    input [HSIZE-1:0] image_row;
    output [HSIZE-1:0] ciphertext_enc;
    output [HSIZE-1:0] plaintext_dec;
    
    genvar i;
    
        for(i=0;i<HSIZE;i=i+1) begin
            ebc_enc_1bit EBC_ENC_1B(.K(key[i%BLOCK_SIZE]), .PT(image_row[i]), .CT(ciphertext_enc[i]));
        end     
    
        for(i=0;i<HSIZE;i=i+1) begin
            ebc_enc_1bit EBC_DEC_1B(.K(key[i%BLOCK_SIZE]), .PT(ciphertext_enc[i]), .CT(plaintext_dec[i]));
        end     
endmodule
