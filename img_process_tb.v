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

wire [47:0] data_encrypted_ecb;
wire [47:0] data_encrypted_cbc;
//reg [47:0] data_plain;
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

//image_write 
//#(.INFILE("/ProgramFiles/ECE/EC551/EC551_Project/images/original_muhabda.bmp"))
//	u_image_write1
//(
//	.HCLK(HCLK),
//	.HRESETn(HRESETn),
//	.hsync(hsync),
//    .DATA_WRITE_R0(data_R0),
//    .DATA_WRITE_G0(data_G0),
//    .DATA_WRITE_B0(data_B0),
//    .DATA_WRITE_R1(data_R1),
//    .DATA_WRITE_G1(data_G1),
//    .DATA_WRITE_B1(data_B1),
//	.Write_Done()
//);	

image_write 
#(.INFILE("/ProgramFiles/ECE/EC551/EC551_Project/images/ecb_muhabda.bmp"))
	u_image_write2
(
	.HCLK(HCLK),
	.HRESETn(HRESETn),
	.hsync(hsync),
	.DATA_WRITE_R0(data_encrypted_ecb[47:40]),
    .DATA_WRITE_G0(data_encrypted_ecb[39:32]),
    .DATA_WRITE_B0(data_encrypted_ecb[31:24]),
    .DATA_WRITE_R1(data_encrypted_ecb[23:16]),
    .DATA_WRITE_G1(data_encrypted_ecb[15:8]),
    .DATA_WRITE_B1(data_encrypted_ecb[7:0]),
	.Write_Done()
);	

image_write 
#(.INFILE("/ProgramFiles/ECE/EC551/EC551_Project/images/cbc_muhabda.bmp"))
	u_image_write3
(
	.HCLK(HCLK),
	.HRESETn(HRESETn),
	.hsync(hsync),
	.DATA_WRITE_R0(data_encrypted_cbc[47:40]),
    .DATA_WRITE_G0(data_encrypted_cbc[39:32]),
    .DATA_WRITE_B0(data_encrypted_cbc[31:24]),
    .DATA_WRITE_R1(data_encrypted_cbc[23:16]),
    .DATA_WRITE_G1(data_encrypted_cbc[15:8]),
    .DATA_WRITE_B1(data_encrypted_cbc[7:0]),
	.Write_Done()
);

parameter BLOCK_SIZE = 32;
reg enable_ebc;
reg enable_cbc;
wire [BLOCK_SIZE-1:0] key;
wire [HSIZE-1:0] image_row;
wire [47:0] vector;


param_lfsr 
#(.BLOCK_SIZE(BLOCK_SIZE))
     RNG_KEY_TB
 (
     .clk(HCLK), 
     .rst(HRESETn), 
     .enable(enable_ebc), 
     .Y(key)
 );
 
param_lfsr 
#(.BLOCK_SIZE(48))
     RNG_IV_TB
 (
     .clk(HCLK), 
     .rst(HRESETn), 
     .enable(1'b1), 
     .Y(vector)
);
 
horizontal_sync 
    #(
    .SYNC_SIZE(768)
    )
    H_SYNC_TB
    (
    .clk(HCLK),
    .rst(HRESETn),
    .hsync(hsync),
    .R(data_R0),
    .G(data_G0),
    .B(data_B0),
    .bufferin(image_row),
    .bufferout(image_row)
    );

ecb_mode
    #(
    .BLOCK_SIZE(32),
    .SYNC_SIZE(48)
    )
    ECB_TB
    (
    .key(key),
    .enable(enable_ebc),
    .data_plain({data_R0,data_G0,data_B0,data_R1,data_G1,data_B1}),
    .data_encrypted(data_encrypted_ecb)
    );
    
cbc_mode
    #(
    .BLOCK_SIZE(32),
    .SYNC_SIZE(48)
    )
    CBC_TB
    (
    .key(key),
    .IV(vector),
    .enable(enable_cbc),
    .data_plain({data_R0,data_G0,data_B0,data_R1,data_G1,data_B1}),
    .data_encrypted(data_encrypted_cbc)
    );
    
//-------------------------------------------------
// Test Vectors
//-------------------------------------------------
initial begin 
    HCLK = 0;
    forever #5 HCLK = ~HCLK;
end

initial begin
    HRESETn     = 0;
    enable_cbc=0;
    enable_ebc=0;
    
    #5 HRESETn = 1;
    #5 enable_cbc=1;
    #5 enable_ebc=1;
end

endmodule
