`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/05/2023 07:50:04 PM
// Design Name: 
// Module Name: ebc_dec_1bit
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


module ecb_dec_1bit(
    K,
    PT,
    CT
    );
    
    // basically this module decrypts one by one
    input K;
    input CT;
    output PT;
    
    assign PT = CT ^ K;

endmodule
