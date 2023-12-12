`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/11/2023 06:21:01 PM
// Design Name: 
// Module Name: transformations
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


module transformations
#(
  parameter WIDTH 	= 768, 					// Image width //640 from camera
			HEIGHT 	= 512 						// Image height //480 from camera

)(clk, rst, sel, DATA_R0, org_R, org_G, org_B, DATA_G0, DATA_B0, DATA_R1, DATA_G1, DATA_B1);

input clk, rst;
input [3:0] sel;
input integer org_R  [0 : WIDTH*HEIGHT - 1]; 	// temporary storage for R component
input integer org_G  [0 : WIDTH*HEIGHT - 1];	// temporary storage for G component
input integer org_B  [0 : WIDTH*HEIGHT - 1];	// temporary storage for B component

output reg [7:0]  DATA_R0;				// 8 bit Red data (even)
output reg [7:0]  DATA_G0;				// 8 bit Green data (even)
output reg [7:0]  DATA_B0;				// 8 bit Blue data (even)
output reg [7:0]  DATA_R1;				// 8 bit Red  data (odd)
output reg [7:0]  DATA_G1;				// 8 bit Green data (odd)
output reg [7:0]  DATA_B1;				// 8 bit Blue data (odd)

reg [ 9:0] row; // row index of the image
reg [10:0] col; // column index of the image


reg [7:0] window_R0 [0:2][0:2]; //used for methods that require knowledge of nearby pixels in a 3x3 grid
reg [7:0] window_G0 [0:2][0:2];
reg [7:0] window_B0 [0:2][0:2];
reg [7:0] window_R1 [0:2][0:2]; 
reg [7:0] window_G1 [0:2][0:2];
reg [7:0] window_B1 [0:2][0:2];

integer tempR0,tempR1,tempG0,tempG1,tempB0,tempB1; // temporary variables in contrast and brightness operation

integer value,value1,value2,value4,value5,value6,value7,value8,value9,value10,value11,value12;// temporary variables in operations

reg [7:0] blurred_pixel_R, blurred_pixel_G, blurred_pixel_B;
reg [2:0] sharpening_kernel [0:2][0:2]; // laplacian filter
initial begin
    sharpening_kernel[0][0] = 0;
    sharpening_kernel[0][1] = -1;
    sharpening_kernel[0][2] = 0;
    sharpening_kernel[1][0] = -1;
    sharpening_kernel[1][1] = 2;
    sharpening_kernel[1][2] = -1;
    sharpening_kernel[2][0] = 0;
    sharpening_kernel[2][1] = -1;
    sharpening_kernel[2][2] = 0;
end//initial

//oil pianing variables
reg [7:0] result;
integer i, j, count;
reg[7:0] color_histogram [0:255];
reg[7:0] color_chart_R0 [0:14], color_chart_G0 [0:14], color_chart_B0 [0:14], color_chart_R1 [0:14], color_chart_G1 [0:14], color_chart_B1 [0:14];
reg[7:0] max_color;

always @ (*) begin

    DATA_R0 = 0;
	DATA_G0 = 0;
	DATA_B0 = 0;                                       
	DATA_R1 = 0;
	DATA_G1 = 0;
	DATA_B1 = 0;         

    //load windows for complicated functions
    window_R0[0][0] = org_R[WIDTH * row-1 + col-2];
    window_R0[0][1] = org_R[WIDTH * row-1 + col];
    window_R0[0][2] = org_R[WIDTH * row-1 + col+2];
    window_R0[1][0] = org_R[WIDTH * row + col-2];
    window_R0[1][1] = org_R[WIDTH * row + col];
    window_R0[1][2] = org_R[WIDTH * row + col+2];
    window_R0[2][0] = org_R[WIDTH * row+1 + col-2];
    window_R0[2][1] = org_R[WIDTH * row+1 + col];
    window_R0[2][2] = org_R[WIDTH * row+1 + col+2];
    
    window_G0[0][0] = org_G[WIDTH * row-1 + col-2];
    window_G0[0][1] = org_G[WIDTH * row-1 + col];
    window_G0[0][2] = org_G[WIDTH * row-1 + col+2];
    window_G0[1][0] = org_G[WIDTH * row + col-2];
    window_G0[1][1] = org_G[WIDTH * row + col];
    window_G0[1][2] = org_G[WIDTH * row + col+2];
    window_G0[2][0] = org_G[WIDTH * row+1 + col-2];
    window_G0[2][1] = org_G[WIDTH * row+1 + col];
    window_G0[2][2] = org_G[WIDTH * row+1 + col+2];
    
    window_B0[0][0] = org_B[WIDTH * row-1 + col-2];
    window_B0[0][1] = org_B[WIDTH * row-1 + col];
    window_B0[0][2] = org_B[WIDTH * row-1 + col+2];
    window_B0[1][0] = org_B[WIDTH * row + col-2];
    window_B0[1][1] = org_B[WIDTH * row + col];
    window_B0[1][2] = org_B[WIDTH * row + col+2];
    window_B0[2][0] = org_B[WIDTH * row+1 + col-2];
    window_B0[2][1] = org_B[WIDTH * row+1 + col];
    window_B0[2][2] = org_B[WIDTH * row+1 + col+2];
    
    window_R1[0][0] = org_R[WIDTH * row-1 + col-2];
    window_R1[0][1] = org_R[WIDTH * row-1 + col];
    window_R1[0][2] = org_R[WIDTH * row-1 + col+2];
    window_R1[1][0] = org_R[WIDTH * row + col-2];
    window_R1[1][1] = org_R[WIDTH * row + col];
    window_R1[1][2] = org_R[WIDTH * row + col+2];
    window_R1[2][0] = org_R[WIDTH * row+1 + col-2];
    window_R1[2][1] = org_R[WIDTH * row+1 + col];
    window_R1[2][2] = org_R[WIDTH * row+1 + col+2];
    
    window_G1[0][0] = org_G[WIDTH * row-1 + col-2];
    window_G1[0][1] = org_G[WIDTH * row-1 + col];
    window_G1[0][2] = org_G[WIDTH * row-1 + col+2];
    window_G1[1][0] = org_G[WIDTH * row + col-2];
    window_G1[1][1] = org_G[WIDTH * row + col];
    window_G1[1][2] = org_G[WIDTH * row + col+2];
    window_G1[2][0] = org_G[WIDTH * row+1 + col-2];
    window_G1[2][1] = org_G[WIDTH * row+1 + col];
    window_G1[2][2] = org_G[WIDTH * row+1 + col+2];
    
    window_B1[0][0] = org_B[WIDTH * row-1 + col-2];
    window_B1[0][1] = org_B[WIDTH * row-1 + col];
    window_B1[0][2] = org_B[WIDTH * row-1 + col+2];
    window_B1[1][0] = org_B[WIDTH * row + col-2];
    window_B1[1][1] = org_B[WIDTH * row + col];
    window_B1[1][2] = org_B[WIDTH * row + col+2];
    window_B1[2][0] = org_B[WIDTH * row+1 + col-2];
    window_B1[2][1] = org_B[WIDTH * row+1 + col];
    window_B1[2][2] = org_B[WIDTH * row+1 + col+2];
		

    case(sel)
        4'b0000: begin //BRIGHTNESS ADDITION OPERATION
            tempR0 = org_R[WIDTH * row + col   ] + VALUE;
            if (tempR0 > 255)
                DATA_R0 = 255;
            else
                DATA_R0 = org_R[WIDTH * row + col   ] + VALUE;
            // R1	
            tempR1 = org_R[WIDTH * row + col+1   ] + VALUE;
            if (tempR1 > 255)
                DATA_R1 = 255;
            else
                DATA_R1 = org_R[WIDTH * row + col+1   ] + VALUE;	
            // G0	
            tempG0 = org_G[WIDTH * row + col   ] + VALUE;
            if (tempG0 > 255)
                DATA_G0 = 255;
            else
                DATA_G0 = org_G[WIDTH * row + col   ] + VALUE;
            tempG1 = org_G[WIDTH * row + col+1   ] + VALUE;
            if (tempG1 > 255)
                DATA_G1 = 255;
            else
                DATA_G1 = org_G[WIDTH * row + col+1   ] + VALUE;		
            // B
            tempB0 = org_B[WIDTH * row + col   ] + VALUE;
            if (tempB0 > 255)
                DATA_B0 = 255;
            else
                DATA_B0 = org_B[WIDTH * row + col   ] + VALUE;
            tempB1 = org_B[WIDTH * row + col+1   ] + VALUE;
            if (tempB1 > 255)
                DATA_B1 = 255;
            else
                DATA_B1 = org_B[WIDTH * row + col+1   ] + VALUE;
        end
        4'b0001: begin //BRIGHTNESS SUBTRACTION OPERATION
        	tempR0 = org_R[WIDTH * row + col   ] - VALUE;
            if (tempR0 < 0)
                DATA_R0 = 0;
            else
                DATA_R0 = org_R[WIDTH * row + col   ] - VALUE;
            // R1	
            tempR1 = org_R[WIDTH * row + col+1   ] - VALUE;
            if (tempR1 < 0)
                DATA_R1 = 0;
            else
                DATA_R1 = org_R[WIDTH * row + col+1   ] - VALUE;	
            // G0	
            tempG0 = org_G[WIDTH * row + col   ] - VALUE;
            if (tempG0 < 0)
                DATA_G0 = 0;
            else
                DATA_G0 = org_G[WIDTH * row + col   ] - VALUE;
            tempG1 = org_G[WIDTH * row + col+1   ] - VALUE;
            if (tempG1 < 0)
                DATA_G1 = 0;
            else
                DATA_G1 = org_G[WIDTH * row + col+1   ] - VALUE;		
            // B
            tempB0 = org_B[WIDTH * row + col   ] - VALUE;
            if (tempB0 < 0)
                DATA_B0 = 0;
            else
                DATA_B0 = org_B[WIDTH * row + col   ] - VALUE;
            tempB1 = org_B[WIDTH * row + col+1   ] - VALUE;
            if (tempB1 < 0)
                DATA_B1 = 0;
            else
                DATA_B1 = org_B[WIDTH * row + col+1   ] - VALUE;
        end
        4'b0010: begin //INVERT OPERATION
        	value2 = (org_B[WIDTH * row + col  ] + org_R[WIDTH * row + col  ] +org_G[WIDTH * row + col  ])/3;
			DATA_R0=255-value2;
			DATA_G0=255-value2;
			DATA_B0=255-value2;
			value4 = (org_B[WIDTH * row + col+1  ] + org_R[WIDTH * row + col+1  ] +org_G[WIDTH * row + col+1  ])/3;
			DATA_R1=255-value4;
			DATA_G1=255-value4;
			DATA_B1=255-value4;	
        end
        4'b0011: begin //THRESHOLD OPERATION
            value = (org_R[WIDTH * row + col   ]+org_G[WIDTH * row + col   ]+org_B[WIDTH * row + col   ])/3;
            if(value > THRESHOLD) begin
                DATA_R0=255;
                DATA_G0=255;
                DATA_B0=255;
            end
            else begin
                DATA_R0=0;
                DATA_G0=0;
                DATA_B0=0;
            end
            value1 = (org_R[WIDTH * row + col+1   ]+org_G[WIDTH * row + col+1   ]+org_B[WIDTH * row + col+1   ])/3;
            if(value1 > THRESHOLD) begin
                DATA_R1=255;
                DATA_G1=255;
                DATA_B1=255;
            end
            else begin
                DATA_R1=0;
                DATA_G1=0;
                DATA_B1=0;
                
            end	
        end
        4'b0100: begin //RED OPERATION
            DATA_R0=org_R[WIDTH * row + col  ];
            DATA_G0=0;
            DATA_B0=0;
            
            DATA_R1=org_R[WIDTH * row + col+1  ];
            DATA_G1=0;
            DATA_B1=0;
        end
        4'b0101: begin //GREEN OPERATION
            DATA_R0=0;
            DATA_G0=org_G[WIDTH * row + col  ];
            DATA_B0=0;
            
            DATA_R1=0;
            DATA_G1=org_G[WIDTH * row + col+1  ];
            DATA_B1=0;
        end
        4'b0111: begin //BLUE OPERATION
            DATA_R0=0;
            DATA_G0=0;
            DATA_B0=org_B[WIDTH * row + col  ];
            
            DATA_R1=0;
            DATA_G1=0;
            DATA_B1=org_B[WIDTH * row + col+1  ];
        end
        4'b1000: begin //GRAYSCALE OPERATION
            value5 = (5'd30 * org_R[WIDTH * row + col   ] + 6'd59* org_G[WIDTH * row + col   ] + 4'd11 * org_B[WIDTH * row + col   ]) / 100;
            DATA_R0=value5;
            DATA_G0=value5;
            DATA_B0=value5;
            value6 = (5'd30 * org_R[WIDTH * row + col+1   ] + 6'd59* org_G[WIDTH * row + col+1   ] + 4'd11 * org_B[WIDTH * row + col+1   ]) / 100;
            DATA_R1=value6;
            DATA_G1=value6;
            DATA_B1=value6;	
        end
        4'b1001: begin //TRIP OPERATION
            value7 = (window_R0[0][0] * sharpening_kernel[0][0] + window_R0[0][1]  * sharpening_kernel[0][1] + window_R0[0][2]  * sharpening_kernel[0][2] + window_R0[1][0]  * sharpening_kernel[1][0] + window_R0[1][1]  * sharpening_kernel[1][1] + window_R0[1][2]  * sharpening_kernel[1][2] + window_R0[2][0]  * sharpening_kernel[2][0] + window_R0[2][1]  * sharpening_kernel[2][1] + window_R0[2][2] * sharpening_kernel[2][2]); 
            value8 = (window_G0[0][0] * sharpening_kernel[0][0] + window_G0[0][1]  * sharpening_kernel[0][1] + window_G0[0][2]  * sharpening_kernel[0][2] + window_G0[1][0]  * sharpening_kernel[1][0] + window_G0[1][1]  * sharpening_kernel[1][1] + window_G0[1][2]  * sharpening_kernel[1][2] + window_G0[2][0]  * sharpening_kernel[2][0] + window_G0[2][1]  * sharpening_kernel[2][1] + window_G0[2][2] * sharpening_kernel[2][2]); 
            value9 = (window_B0[0][0] * sharpening_kernel[0][0] + window_B0[0][1]  * sharpening_kernel[0][1] + window_B0[0][2]  * sharpening_kernel[0][2] + window_B0[1][0]  * sharpening_kernel[1][0] + window_B0[1][1]  * sharpening_kernel[1][1] + window_B0[1][2]  * sharpening_kernel[1][2] + window_B0[2][0]  * sharpening_kernel[2][0] + window_B0[2][1]  * sharpening_kernel[2][1] + window_B0[2][2] * sharpening_kernel[2][2]); 
            value10 = (window_R1[0][0] * sharpening_kernel[0][0] + window_R1[0][1]  * sharpening_kernel[0][1] + window_R1[0][2]  * sharpening_kernel[0][2] + window_R1[1][0]  * sharpening_kernel[1][0] + window_R1[1][1]  * sharpening_kernel[1][1] + window_R1[1][2]  * sharpening_kernel[1][2] + window_R1[2][0]  * sharpening_kernel[2][0] + window_R1[2][1]  * sharpening_kernel[2][1] + window_R1[2][2] * sharpening_kernel[2][2]); 
            value11 = (window_G1[0][0] * sharpening_kernel[0][0] + window_G1[0][1]  * sharpening_kernel[0][1] + window_G1[0][2]  * sharpening_kernel[0][2] + window_G1[1][0]  * sharpening_kernel[1][0] + window_G1[1][1]  * sharpening_kernel[1][1] + window_G1[1][2]  * sharpening_kernel[1][2] + window_G1[2][0]  * sharpening_kernel[2][0] + window_G1[2][1]  * sharpening_kernel[2][1] + window_G1[2][2] * sharpening_kernel[2][2]); 
            value12 = (window_B1[0][0] * sharpening_kernel[0][0] + window_B1[0][1]  * sharpening_kernel[0][1] + window_B1[0][2]  * sharpening_kernel[0][2] + window_B1[1][0]  * sharpening_kernel[1][0] + window_B1[1][1]  * sharpening_kernel[1][1] + window_B1[1][2]  * sharpening_kernel[1][2] + window_B1[2][0]  * sharpening_kernel[2][0] + window_B1[2][1]  * sharpening_kernel[2][1] + window_B1[2][2] * sharpening_kernel[2][2]); 
            
        end
        4'b1010: begin //BLUR OPERATION
            DATA_R0 = (window_R0[0][0] + window_R0[0][1] + window_R0[0][2] + window_R0[1][0] + window_R0[1][1] + window_R0[1][2] + window_R0[2][0] + window_R0[2][1] + window_R0[2][2]) / 9;
            DATA_G0 = (window_G0[0][0] + window_G0[0][1] + window_G0[0][2] + window_G0[1][0] + window_G0[1][1] + window_G0[1][2] + window_G0[2][0] + window_G0[2][1] + window_G0[2][2]) / 9;
            DATA_B0 = (window_B0[0][0] + window_B0[0][1] + window_B0[0][2] + window_B0[1][0] + window_B0[1][1] + window_B0[1][2] + window_B0[2][0] + window_B0[2][1] + window_B0[2][2]) / 9;
            DATA_R1 = (window_R1[0][0] + window_R1[0][1] + window_R1[0][2] + window_R1[1][0] + window_R1[1][1] + window_R1[1][2] + window_R1[2][0] + window_R1[2][1] + window_R1[2][2]) / 9;
            DATA_G1 = (window_G1[0][0] + window_G1[0][1] + window_G1[0][2] + window_G1[1][0] + window_G1[1][1] + window_G1[1][2] + window_G1[2][0] + window_G1[2][1] + window_G1[2][2]) / 9;
            DATA_B1 = (window_B1[0][0] + window_B1[0][1] + window_B1[0][2] + window_B1[1][0] + window_B1[1][1] + window_B1[1][2] + window_B1[2][0] + window_B1[2][1] + window_B1[2][2]) / 9;
        end
        4'b1011: begin
            value7 = (window_R0[0][0] * sharpening_kernel[0][0] + window_R0[0][1]  * sharpening_kernel[0][1] + window_R0[0][2]  * sharpening_kernel[0][2] + window_R0[1][0]  * sharpening_kernel[1][0] + window_R0[1][1]  * sharpening_kernel[1][1] + window_R0[1][2]  * sharpening_kernel[1][2] + window_R0[2][0]  * sharpening_kernel[2][0] + window_R0[2][1]  * sharpening_kernel[2][1] + window_R0[2][2] * sharpening_kernel[2][2]); 
            value8 = (window_G0[0][0] * sharpening_kernel[0][0] + window_G0[0][1]  * sharpening_kernel[0][1] + window_G0[0][2]  * sharpening_kernel[0][2] + window_G0[1][0]  * sharpening_kernel[1][0] + window_G0[1][1]  * sharpening_kernel[1][1] + window_G0[1][2]  * sharpening_kernel[1][2] + window_G0[2][0]  * sharpening_kernel[2][0] + window_G0[2][1]  * sharpening_kernel[2][1] + window_G0[2][2] * sharpening_kernel[2][2]); 
            value9 = (window_B0[0][0] * sharpening_kernel[0][0] + window_B0[0][1]  * sharpening_kernel[0][1] + window_B0[0][2]  * sharpening_kernel[0][2] + window_B0[1][0]  * sharpening_kernel[1][0] + window_B0[1][1]  * sharpening_kernel[1][1] + window_B0[1][2]  * sharpening_kernel[1][2] + window_B0[2][0]  * sharpening_kernel[2][0] + window_B0[2][1]  * sharpening_kernel[2][1] + window_B0[2][2] * sharpening_kernel[2][2]); 
            value10 = (window_R1[0][0] * sharpening_kernel[0][0] + window_R1[0][1]  * sharpening_kernel[0][1] + window_R1[0][2]  * sharpening_kernel[0][2] + window_R1[1][0]  * sharpening_kernel[1][0] + window_R1[1][1]  * sharpening_kernel[1][1] + window_R1[1][2]  * sharpening_kernel[1][2] + window_R1[2][0]  * sharpening_kernel[2][0] + window_R1[2][1]  * sharpening_kernel[2][1] + window_R1[2][2] * sharpening_kernel[2][2]); 
            value11 = (window_G1[0][0] * sharpening_kernel[0][0] + window_G1[0][1]  * sharpening_kernel[0][1] + window_G1[0][2]  * sharpening_kernel[0][2] + window_G1[1][0]  * sharpening_kernel[1][0] + window_G1[1][1]  * sharpening_kernel[1][1] + window_G1[1][2]  * sharpening_kernel[1][2] + window_G1[2][0]  * sharpening_kernel[2][0] + window_G1[2][1]  * sharpening_kernel[2][1] + window_G1[2][2] * sharpening_kernel[2][2]); 
            value12 = (window_B1[0][0] * sharpening_kernel[0][0] + window_B1[0][1]  * sharpening_kernel[0][1] + window_B1[0][2]  * sharpening_kernel[0][2] + window_B1[1][0]  * sharpening_kernel[1][0] + window_B1[1][1]  * sharpening_kernel[1][1] + window_B1[1][2]  * sharpening_kernel[1][2] + window_B1[2][0]  * sharpening_kernel[2][0] + window_B1[2][1]  * sharpening_kernel[2][1] + window_B1[2][2] * sharpening_kernel[2][2]); 
            
            //ensure values are legal
            if(value7 < 0) 
              value7 = 0;
            else if (value7 > 255) 
              value7 = 255;
            if(value8 < 0) 
              value8 = 0;
            else if (value8 > 255) 
              value8 = 255;
            if(value9 < 0) 
              value9 = 0;
            else if (value9 > 255) 
              value9 = 255;
            if(value10 < 0) 
              value10 = 0;
            else if (value10 > 255) 
              value10 = 255;
            if(value11 < 0) 
              value11 = 0;
            else if (value11 > 255) 
              value11 = 255;
            if(value12 < 0) 
              value12 = 0;
            else if (value12 > 255) 
              value12 = 255;  
              
            DATA_R0=value7 / 3;
            DATA_G0=value8 / 3;
            DATA_B0=value9 / 3;
            
            DATA_R1=value10 / 3;
            DATA_G1=value11 / 3;
            DATA_B1=value12 / 3;           
        end
        4'b1100: begin //OIL OPERATION  
            
            //R0 CASE
            
            for(i = 0; i < 15; i = i + i) begin
              color_chart_R0[i] = 8'b00000000;
            end //for
            
            for(i=0; i <= 2; i= i + 1)begin
                for(j = 0; j <= 2; j = j + 1) begin
                    if(window_R0[i][j] > 0 && window_R0[i][j] <= 17) begin
                        color_chart_R0[0] = color_chart_R0[0] + 1;
                    end //if
                    else if (window_R0[i][j] > 17 && window_R0[i][j] <= 34) begin
                        color_chart_R0[1] = color_chart_R0[1] + 1;
                    end //elif
                    else if (window_R0[i][j] > 34 && window_R0[i][j] <= 51) begin
                        color_chart_R0[2] = color_chart_R0[2] + 1;
                    end //elif
                    else if (window_R0[i][j] > 51 && window_R0[i][j] <= 68) begin
                        color_chart_R0[3] = color_chart_R0[3] + 1;
                    end //elif
                    else if (window_R0[i][j] > 68 && window_R0[i][j] <= 85) begin
                        color_chart_R0[4] = color_chart_R0[4] + 1;
                    end //elif
                    else if (window_R0[i][j] > 85 && window_R0[i][j] <= 102) begin
                        color_chart_R0[5] = color_chart_R0[5] + 1;
                    end //elif
                    else if (window_R0[i][j] > 102 && window_R0[i][j] <= 119) begin
                        color_chart_R0[6] = color_chart_R0[6] + 1;
                    end //elif
                    else if (window_R0[i][j] > 119 && window_R0[i][j] <= 136) begin
                        color_chart_R0[7] = color_chart_R0[7] + 1;
                    end //elif
                    else if (window_R0[i][j] > 136 && window_R0[i][j] <= 153) begin
                        color_chart_R0[8] = color_chart_R0[8] + 1;
                    end //elif
                    else if (window_R0[i][j] > 153 && window_R0[i][j] <= 170) begin
                        color_chart_R0[9] = color_chart_R0[9] + 1;
                    end //elif
                    else if (window_R0[i][j] > 170 && window_R0[i][j] <= 187) begin
                        color_chart_R0[10] = color_chart_R0[10] + 1;
                    end //elif
                    else if (window_R0[i][j] > 187 && window_R0[i][j] <= 204) begin
                        color_chart_R0[11] = color_chart_R0[11] + 1;
                    end //elif
                    else if (window_R0[i][j] > 204 && window_R0[i][j] <= 221) begin
                        color_chart_R0[12] = color_chart_R0[12] + 1;
                    end //elif
                    else if (window_R0[i][j] > 221 && window_R0[i][j] <= 238) begin
                        color_chart_R0[13] = color_chart_R0[13] + 1;
                    end //elif
                    else if (window_R0[i][j] > 238 && window_R0[i][j] <= 255) begin
                        color_chart_R0[14] = color_chart_R0[14] + 1;
                    end //elif
    
                end // for
            end // for
            
            max_color = 0;
            for(i = 0; i <=14; i = i + 1) begin
                //$display("values: %d", color_chart_R0);
                if (color_chart_R0[i] > max_color) begin
                    max_color = i;
                end//if
            end // for
            
            case(max_color)
                4'd0: DATA_R0 = 9;
                4'd1: DATA_R0 = 26;
                4'd2: DATA_R0 = 43;
                4'd3: DATA_R0 = 60;
                4'd4: DATA_R0 = 77;
                4'd5: DATA_R0 = 94;
                4'd6: DATA_R0 = 111;
                4'd7: DATA_R0 = 128;
                4'd8: DATA_R0 = 145;
                4'd9: DATA_R0 = 162;
                4'd10: DATA_R0 = 179;
                4'd11: DATA_R0 = 196;
                4'd12: DATA_R0 = 213;
                4'd13: DATA_R0 = 230;
                4'd14: DATA_R0 = 247;
            endcase
            //$display("RO VALUE: %d", DATA_R0);
            
            //G0 CASE
            for(i = 0; i < 15; i = i + i) begin
              color_chart_G0[i] = 8'b00000000;
            end //for
            
            for(i=0; i <= 2; i= i + 1)begin
                for(j = 0; j <= 2; j = j + 1) begin
                    if(window_G0[i][j] > 0 && window_G0[i][j] <= 17) begin
                        color_chart_G0[0] = color_chart_G0[0] + 1;
                    end //if
                    else if (window_G0[i][j] > 17 && window_G0[i][j] <= 34) begin
                        color_chart_G0[1] = color_chart_G0[1] + 1;
                    end //elif
                    else if (window_G0[i][j] > 34 && window_G0[i][j] <= 51) begin
                        color_chart_G0[2] = color_chart_G0[2] + 1;
                    end //elif
                    else if (window_G0[i][j] > 51 && window_G0[i][j] <= 68) begin
                        color_chart_G0[3] = color_chart_G0[3] + 1;
                    end //elif
                    else if (window_G0[i][j] > 68 && window_G0[i][j] <= 85) begin
                        color_chart_G0[4] = color_chart_G0[4] + 1;
                    end //elif
                    else if (window_G0[i][j] > 85 && window_G0[i][j] <= 102) begin
                        color_chart_G0[5] = color_chart_G0[5] + 1;
                    end //elif
                    else if (window_G0[i][j] > 102 && window_G0[i][j] <= 119) begin
                        color_chart_G0[6] = color_chart_G0[6] + 1;
                    end //elif
                    else if (window_G0[i][j] > 119 && window_G0[i][j] <= 136) begin
                        color_chart_G0[7] = color_chart_G0[7] + 1;
                    end //elif
                    else if (window_G0[i][j] > 136 && window_G0[i][j] <= 153) begin
                        color_chart_G0[8] = color_chart_G0[8] + 1;
                    end //elif
                    else if (window_G0[i][j] > 153 && window_G0[i][j] <= 170) begin
                        color_chart_G0[9] = color_chart_G0[9] + 1;
                    end //elif
                    else if (window_G0[i][j] > 170 && window_G0[i][j] <= 187) begin
                        color_chart_G0[10] = color_chart_G0[10] + 1;
                    end //elif
                    else if (window_G0[i][j] > 187 && window_G0[i][j] <= 204) begin
                        color_chart_G0[11] = color_chart_G0[11] + 1;
                    end //elif
                    else if (window_G0[i][j] > 204 && window_G0[i][j] <= 221) begin
                        color_chart_G0[12] = color_chart_G0[12] + 1;
                    end //elif
                    else if (window_G0[i][j] > 221 && window_G0[i][j] <= 238) begin
                        color_chart_G0[13] = color_chart_G0[13] + 1;
                    end //elif
                    else if (window_G0[i][j] > 238 && window_G0[i][j] <= 255) begin
                        color_chart_G0[14] = color_chart_G0[14] + 1;
                    end //elif
    
                end // for
            end // for
            
            max_color = 0;
            for(i = 0; i <=14; i = i + 1) begin
                if (color_chart_G0[i] > max_color) begin
                    max_color = i;
                end//if
            end // for
            
            case(max_color)
                4'd0: DATA_G0 = 9;
                4'd1: DATA_G0 = 26;
                4'd2: DATA_G0 = 43;
                4'd3: DATA_G0 = 60;
                4'd4: DATA_G0 = 77;
                4'd5: DATA_G0 = 94;
                4'd6: DATA_G0 = 111;
                4'd7: DATA_G0 = 128;
                4'd8: DATA_G0 = 145;
                4'd9: DATA_G0 = 162;
                4'd10: DATA_G0 = 179;
                4'd11: DATA_G0 = 196;
                4'd12: DATA_G0 = 213;
                4'd13: DATA_G0 = 230;
                4'd14: DATA_G0 = 247;
            endcase
            //$display("GO VALUE: %d", DATA_G0);
            
            //B0 CASE
            for(i = 0; i < 15; i = i + i) begin
              color_chart_B0[i] = 8'b00000000;
            end //for
            
            for(i=0; i <= 2; i= i + 1)begin
                for(j = 0; j <= 2; j = j + 1) begin
    //                $display("BO VALUE: %d", window_B0[i][j]);
                    if(window_B0[i][j] > 0 && window_B0[i][j] <= 17) begin
                        color_chart_B0[0] = color_chart_B0[0] + 1;
                    end //if
                    else if (window_B0[i][j] > 17 && window_B0[i][j] <= 34) begin
                        color_chart_B0[1] = color_chart_B0[1] + 1;
                    end //elif
                    else if (window_B0[i][j] > 34 && window_B0[i][j] <= 51) begin
                        color_chart_B0[2] = color_chart_B0[2] + 1;
                    end //elif
                    else if (window_B0[i][j] > 51 && window_B0[i][j] <= 68) begin
                        color_chart_B0[3] = color_chart_B0[3] + 1;
                    end //elif
                    else if (window_B0[i][j] > 68 && window_B0[i][j] <= 85) begin
                        color_chart_B0[4] = color_chart_B0[4] + 1;
                    end //elif
                    else if (window_B0[i][j] > 85 && window_B0[i][j] <= 102) begin
                        color_chart_B0[5] = color_chart_B0[5] + 1;
                    end //elif
                    else if (window_B0[i][j] > 102 && window_B0[i][j] <= 119) begin
                        color_chart_B0[6] = color_chart_B0[6] + 1;
                    end //elif
                    else if (window_B0[i][j] > 119 && window_B0[i][j] <= 136) begin
                        color_chart_B0[7] = color_chart_B0[7] + 1;
                    end //elif
                    else if (window_B0[i][j] > 136 && window_B0[i][j] <= 153) begin
                        color_chart_B0[8] = color_chart_B0[8] + 1;
                    end //elif
                    else if (window_B0[i][j] > 153 && window_B0[i][j] <= 170) begin
                        color_chart_B0[9] = color_chart_B0[9] + 1;
                    end //elif
                    else if (window_B0[i][j] > 170 && window_B0[i][j] <= 187) begin
                        color_chart_B0[10] = color_chart_B0[10] + 1;
                    end //elif
                    else if (window_B0[i][j] > 187 && window_B0[i][j] <= 204) begin
                        color_chart_B0[11] = color_chart_B0[11] + 1;
                    end //elif
                    else if (window_B0[i][j] > 204 && window_B0[i][j] <= 221) begin
                        color_chart_B0[12] = color_chart_B0[12] + 1;
                    end //elif
                    else if (window_B0[i][j] > 221 && window_B0[i][j] <= 238) begin
                        color_chart_B0[13] = color_chart_B0[13] + 1;
                    end //elif
                    else if (window_B0[i][j] > 238 && window_B0[i][j] <= 255) begin
                        color_chart_B0[14] = color_chart_B0[14] + 1;
                    end //elif
    
                end // for
            end // for
            
    //        $display("BO color chart value 0: %d", color_chart_B0[0]);
    //        $display("BO color chart value 1: %d", color_chart_B0[1]);
    //        $display("BO color chart value 2: %d", color_chart_B0[2]);
    //        $display("BO color chart value 3: %d", color_chart_B0[3]);
    //        $display("BO color chart value 4: %d", color_chart_B0[4]);
    //        $display("BO color chart value 5: %d", color_chart_B0[5]);
    //        $display("BO color chart value 6: %d", color_chart_B0[6]);
    //        $display("BO color chart value 7: %d", color_chart_B0[7]);
    //        $display("BO color chart value 8: %d", color_chart_B0[8]);
    //        $display("BO color chart value 9: %d", color_chart_B0[9]);
    //        $display("BO color chart value 10: %d", color_chart_B0[10]);
    //        $display("BO color chart value 11: %d", color_chart_B0[11]);
    //        $display("BO color chart value 12: %d", color_chart_B0[12]);
    //        $display("BO color chart value 13: %d", color_chart_B0[13]);
    //        $display("BO color chart value 14: %d", color_chart_B0[14]);
            
            
            max_color = 0;
            for(i = 0; i <=14; i = i + 1) begin
                if (color_chart_B0[i] > max_color) begin
                    max_color = i;
                end//if
            end // for
    //        $display("max color: %d", max_color);
            case(max_color)
                4'd0: DATA_B0 = 9;
                4'd1: DATA_B0 = 26;
                4'd2: DATA_B0 = 43;
                4'd3: DATA_B0 = 60;
                4'd4: DATA_B0 = 77;
                4'd5: DATA_B0 = 94;
                4'd6: DATA_B0 = 111;
                4'd7: DATA_B0 = 128;
                4'd8: DATA_B0 = 145;
                4'd9: DATA_B0 = 162;
                4'd10: DATA_B0 = 179;
                4'd11: DATA_B0 = 196;
                4'd12: DATA_B0 = 213;
                4'd13: DATA_B0 = 230;
                4'd14: DATA_B0 = 247;
            endcase      
            //$display("BO VALUE: %d", DATA_B0);
            
            //R1 CASE
            for(i = 0; i < 15; i = i + i) begin
              color_chart_R1[i] = 8'b00000000;
            end //for
            
            for(i=0; i <= 2; i= i + 1)begin
                for(j = 0; j <= 2; j = j + 1) begin
                    if(window_R1[i][j] > 0 && window_R1[i][j] <= 17) begin
                        color_chart_R1[0] = color_chart_R1[0] + 1;
                    end //if
                    else if (window_R1[i][j] > 17 && window_R1[i][j] <= 34) begin
                        color_chart_R1[1] = color_chart_R1[1] + 1;
                    end //elif
                    else if (window_R1[i][j] > 34 && window_R1[i][j] <= 51) begin
                        color_chart_R1[2] = color_chart_R1[2] + 1;
                    end //elif
                    else if (window_R1[i][j] > 51 && window_R1[i][j] <= 68) begin
                        color_chart_R1[3] = color_chart_R1[3] + 1;
                    end //elif
                    else if (window_R1[i][j] > 68 && window_R1[i][j] <= 85) begin
                        color_chart_R1[4] = color_chart_R1[4] + 1;
                    end //elif
                    else if (window_R1[i][j] > 85 && window_R1[i][j] <= 102) begin
                        color_chart_R1[5] = color_chart_R1[5] + 1;
                    end //elif
                    else if (window_R1[i][j] > 102 && window_R1[i][j] <= 119) begin
                        color_chart_R1[6] = color_chart_R1[6] + 1;
                    end //elif
                    else if (window_R1[i][j] > 119 && window_R1[i][j] <= 136) begin
                        color_chart_R1[7] = color_chart_R1[7] + 1;
                    end //elif
                    else if (window_R1[i][j] > 136 && window_R1[i][j] <= 153) begin
                        color_chart_R1[8] = color_chart_R1[8] + 1;
                    end //elif
                    else if (window_R1[i][j] > 153 && window_R1[i][j] <= 170) begin
                        color_chart_R1[9] = color_chart_R1[9] + 1;
                    end //elif
                    else if (window_R1[i][j] > 170 && window_R1[i][j] <= 187) begin
                        color_chart_R1[10] = color_chart_R1[10] + 1;
                    end //elif
                    else if (window_R1[i][j] > 187 && window_R1[i][j] <= 204) begin
                        color_chart_R1[11] = color_chart_R1[11] + 1;
                    end //elif
                    else if (window_R1[i][j] > 204 && window_R1[i][j] <= 221) begin
                        color_chart_R1[12] = color_chart_R1[12] + 1;
                    end //elif
                    else if (window_R1[i][j] > 221 && window_R1[i][j] <= 238) begin
                        color_chart_R1[13] = color_chart_R1[13] + 1;
                    end //elif
                    else if (window_R1[i][j] > 238 && window_R1[i][j] <= 255) begin
                        color_chart_R1[14] = color_chart_R1[14] + 1;
                    end //elif
    
                end // for
            end // for
            
            max_color = 0;
            for(i = 0; i <=14; i = i + 1) begin
                if (color_chart_R1[i] > max_color) begin
                    max_color = i;
                end//if
            end // for
            
            case(max_color)
                4'd0: DATA_R1 = 9;
                4'd1: DATA_R1 = 26;
                4'd2: DATA_R1 = 43;
                4'd3: DATA_R1 = 60;
                4'd4: DATA_R1 = 77;
                4'd5: DATA_R1 = 94;
                4'd6: DATA_R1 = 111;
                4'd7: DATA_R1 = 128;
                4'd8: DATA_R1 = 145;
                4'd9: DATA_R1 = 162;
                4'd10: DATA_R1 = 179;
                4'd11: DATA_R1 = 196;
                4'd12: DATA_R1 = 213;
                4'd13: DATA_R1 = 230;
                4'd14: DATA_R1 = 247;
            endcase
            //$display("R1 VALUE: %d", DATA_R1);
            
            //G1 CASE
            
            for(i = 0; i < 15; i = i + i) begin
              color_chart_G1[i] = 8'b00000000;
            end //for
            
            for(i=0; i <= 2; i= i + 1)begin
                for(j = 0; j <= 2; j = j + 1) begin
                    if(window_G1[i][j] > 0 && window_G1[i][j] <= 17) begin
                        color_chart_G1[0] = color_chart_G1[0] + 1;
                    end //if
                    else if (window_G1[i][j] > 17 && window_G1[i][j] <= 34) begin
                        color_chart_G1[1] = color_chart_G1[1] + 1;
                    end //elif
                    else if (window_G1[i][j] > 34 && window_G1[i][j] <= 51) begin
                        color_chart_G1[2] = color_chart_G1[2] + 1;
                    end //elif
                    else if (window_G1[i][j] > 51 && window_G1[i][j] <= 68) begin
                        color_chart_G1[3] = color_chart_G1[3] + 1;
                    end //elif
                    else if (window_G1[i][j] > 68 && window_G1[i][j] <= 85) begin
                        color_chart_G1[4] = color_chart_G1[4] + 1;
                    end //elif
                    else if (window_G1[i][j] > 85 && window_G1[i][j] <= 102) begin
                        color_chart_G1[5] = color_chart_G1[5] + 1;
                    end //elif
                    else if (window_G1[i][j] > 102 && window_G1[i][j] <= 119) begin
                        color_chart_G1[6] = color_chart_G1[6] + 1;
                    end //elif
                    else if (window_G1[i][j] > 119 && window_G1[i][j] <= 136) begin
                        color_chart_G1[7] = color_chart_G1[7] + 1;
                    end //elif
                    else if (window_G1[i][j] > 136 && window_G1[i][j] <= 153) begin
                        color_chart_G1[8] = color_chart_G1[8] + 1;
                    end //elif
                    else if (window_G1[i][j] > 153 && window_G1[i][j] <= 170) begin
                        color_chart_G1[9] = color_chart_G1[9] + 1;
                    end //elif
                    else if (window_G1[i][j] > 170 && window_G1[i][j] <= 187) begin
                        color_chart_G1[10] = color_chart_G1[10] + 1;
                    end //elif
                    else if (window_G1[i][j] > 187 && window_G1[i][j] <= 204) begin
                        color_chart_G1[11] = color_chart_G1[11] + 1;
                    end //elif
                    else if (window_G1[i][j] > 204 && window_G1[i][j] <= 221) begin
                        color_chart_G1[12] = color_chart_G1[12] + 1;
                    end //elif
                    else if (window_G1[i][j] > 221 && window_G1[i][j] <= 238) begin
                        color_chart_G1[13] = color_chart_G1[13] + 1;
                    end //elif
                    else if (window_G1[i][j] > 238 && window_G1[i][j] <= 255) begin
                        color_chart_G1[14] = color_chart_G1[14] + 1;
                    end //elif
    
                end // for
            end // for
            
            max_color = 0;
            for(i = 0; i <=14; i = i + 1) begin
                if (color_chart_G1[i] > max_color) begin
                    max_color = i;
                end//if
            end // for
            
            case(max_color)
                4'd0: DATA_G1 = 9;
                4'd1: DATA_G1 = 26;
                4'd2: DATA_G1 = 43;
                4'd3: DATA_G1 = 60;
                4'd4: DATA_G1 = 77;
                4'd5: DATA_G1 = 94;
                4'd6: DATA_G1 = 111;
                4'd7: DATA_G1 = 128;
                4'd8: DATA_G1 = 145;
                4'd9: DATA_G1 = 162;
                4'd10: DATA_G1 = 179;
                4'd11: DATA_G1 = 196;
                4'd12: DATA_G1 = 213;
                4'd13: DATA_G1 = 230;
                4'd14: DATA_G1 = 247;
            endcase
            //$display("G1 VALUE: %d", DATA_G1);
            
            //B1 CASE
            
            for(i = 0; i < 15; i = i + i) begin
              color_chart_B1[i] = 8'b00000000;
            end //for
            
            for(i=0; i <= 2; i= i + 1)begin
                for(j = 0; j <= 2; j = j + 1) begin
                    if(window_B1[i][j] > 0 && window_B1[i][j] <= 17) begin
                        color_chart_B1[0] = color_chart_B1[0] + 1;
                    end //if
                    else if (window_B1[i][j] > 17 && window_B1[i][j] <= 34) begin
                        color_chart_B1[1] = color_chart_B1[1] + 1;
                    end //elif
                    else if (window_B1[i][j] > 34 && window_B1[i][j] <= 51) begin
                        color_chart_B1[2] = color_chart_B1[2] + 1;
                    end //elif
                    else if (window_B1[i][j] > 51 && window_B1[i][j] <= 68) begin
                        color_chart_B1[3] = color_chart_B1[3] + 1;
                    end //elif
                    else if (window_B1[i][j] > 68 && window_B1[i][j] <= 85) begin
                        color_chart_B1[4] = color_chart_B1[4] + 1;
                    end //elif
                    else if (window_B1[i][j] > 85 && window_B1[i][j] <= 102) begin
                        color_chart_B1[5] = color_chart_B1[5] + 1;
                    end //elif
                    else if (window_B1[i][j] > 102 && window_B1[i][j] <= 119) begin
                        color_chart_B1[6] = color_chart_B1[6] + 1;
                    end //elif
                    else if (window_B1[i][j] > 119 && window_B1[i][j] <= 136) begin
                        color_chart_B1[7] = color_chart_B1[7] + 1;
                    end //elif
                    else if (window_B1[i][j] > 136 && window_B1[i][j] <= 153) begin
                        color_chart_B1[8] = color_chart_B1[8] + 1;
                    end //elif
                    else if (window_B1[i][j] > 153 && window_B1[i][j] <= 170) begin
                        color_chart_B1[9] = color_chart_B1[9] + 1;
                    end //elif
                    else if (window_B1[i][j] > 170 && window_B1[i][j] <= 187) begin
                        color_chart_B1[10] = color_chart_B1[10] + 1;
                    end //elif
                    else if (window_B1[i][j] > 187 && window_B1[i][j] <= 204) begin
                        color_chart_B1[11] = color_chart_B1[11] + 1;
                    end //elif
                    else if (window_B1[i][j] > 204 && window_B1[i][j] <= 221) begin
                        color_chart_B1[12] = color_chart_B1[12] + 1;
                    end //elif
                    else if (window_B1[i][j] > 221 && window_B1[i][j] <= 238) begin
                        color_chart_B1[13] = color_chart_B1[13] + 1;
                    end //elif
                    else if (window_B1[i][j] > 238 && window_B1[i][j] <= 255) begin
                        color_chart_B1[14] = color_chart_B1[14] + 1;
                    end //elif
    
                end // for
            end // for
            
            max_color = 0;
            for(i = 0; i <=14; i = i + 1) begin
                if (color_chart_B1[i] > max_color) begin
                    max_color = i;
                end//if
            end // for
            
            case(max_color)
                4'd0: DATA_B1 = 9;
                4'd1: DATA_B1 = 26;
                4'd2: DATA_B1 = 43;
                4'd3: DATA_B1 = 60;
                4'd4: DATA_B1 = 77;
                4'd5: DATA_B1 = 94;
                4'd6: DATA_B1 = 111;
                4'd7: DATA_B1 = 128;
                4'd8: DATA_B1 = 145;
                4'd9: DATA_B1 = 162;
                4'd10: DATA_B1 = 179;
                4'd11: DATA_B1 = 196;
                4'd12: DATA_B1 = 213;
                4'd13: DATA_B1 = 230;
                4'd14: DATA_B1 = 247;
            endcase    
        
        end
        default: begin
            DATA_R0 = 0;
            DATA_G0 = 0;
            DATA_B0 = 0;
            DATA_R1 = 0;
            DATA_G1 = 0;
            DATA_B1 = 0;
        end
    
    endcase


end //always



endmodule
