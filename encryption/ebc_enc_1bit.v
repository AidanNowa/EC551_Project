`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/05/2023 07:49:09 PM
// Design Name: 
// Module Name: ebc_enc_1bit
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


module ebc_enc_1bit(
    K,
    PT,
    CT
    );
    
    // basically this module encrypts one by one
    input K;
    input PT;
    output CT;
    
    assign CT = PT ^ K;
endmodule
