`timescale 1ns/1ps 

//`include "parameter.v"// include definition file

module tb_simulation;

//-------------------------------------------------
// Internal Signals
//-------------------------------------------------
parameter HSIZE = 768;
parameter VSIZE = 512;

reg HCLK, HRESETn;
wire          vsync;
wire          hsync;
wire [ 7 : 0] data_R0;
wire [ 7 : 0] data_G0;
wire [ 7 : 0] data_B0;
wire [ 7 : 0] data_R1;
wire [ 7 : 0] data_G1;
wire [ 7 : 0] data_B1;
wire enc_done;

//-------------------------------------------------
// Components
//-------------------------------------------------

image_read 
#(.INFILE("/ProgramFiles/ECE/EC551/EC551_Project/images/kodim23.hex"))
	u_image_read
( 
    .HCLK	                (HCLK    ),
    .HRESETn	            (HRESETn ),
    .VSYNC	                (vsync   ),
    .HSYNC	                (hsync   ),
    .DATA_R0	            (data_R0 ),
    .DATA_G0	            (data_G0 ),
    .DATA_B0	            (data_B0 ),
    .DATA_R1	            (data_R1 ),
    .DATA_G1	            (data_G1 ),
    .DATA_B1	            (data_B1 ),
	.ctrl_done				(enc_done)
); 

image_write 
#(.INFILE("/ProgramFiles/ECE/EC551/EC551_Project/images/output_muhabda.bmp"))
	u_image_write
(
	.HCLK(HCLK),
	.HRESETn(HRESETn),
	.hsync(hsync),
   .DATA_WRITE_R0(data_R0),
   .DATA_WRITE_G0(data_G0),
   .DATA_WRITE_B0(data_B0),
   .DATA_WRITE_R1(data_R1),
   .DATA_WRITE_G1(data_G1),
   .DATA_WRITE_B1(data_B1),
	.Write_Done()
);	

parameter BLOCK_SIZE = 32;
reg enable_ebc;
wire [BLOCK_SIZE-1:0] key;
wire [HSIZE-1:0] image_row;
wire [HSIZE-1:0] ciphertext_enc;
wire [HSIZE-1:0] plaintext_dec;


//param_lsfr 
//#(.BLOCK_SIZE(BLOCK_SIZE))
//     RNG
// (
//     .clk(HCLK), 
//     .reset(HRESETn), 
//     .enable(1), 
//     .Y(key)
// );
 
horizontal_sync 
    #(
    .HSIZE(32)
    )
    H_SYNC
    (
    .clk(HCLK),
    .rst(HRESETn),
    .hsync(hsync),
    .R(data_R0),
    .G(data_G0),
    .B(data_B0),
    .buffer(image_row)
    );

//ebc_mode
//    #(
//    .BLOCK_SIZE(32),
//    .HSIZE(HSIZE)
//    )
//    EBC_TB
//    (
//    .key(key),
//    .enable(enable_ebc),
//    .image_row(image_row),
//    .ciphertext_enc(ciphertext_enc),
//    .plaintext_dec(plaintext_dec)
//    );
    
//-------------------------------------------------
// Test Vectors
//-------------------------------------------------
initial begin 
    HCLK = 0;
    forever #2.5 HCLK = ~HCLK;
end

initial begin
    HRESETn     = 0;
    #5 HRESETn = 1;
end



endmodule
