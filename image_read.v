
`include "parameter.v" 						// Include definition file
module image_read
#(
  parameter WIDTH 	= 768, 					// Image width //640 from camera
			HEIGHT 	= 512, 						// Image height //480 from camera
			INFILE  = "/home/aidannow/EC551/Project/kodim23.hex", 	// image file
			START_UP_DELAY = 100, 				// Delay during start up time
			HSYNC_DELAY = 160,					// Delay between HSYNC pulses	
			VALUE= 100,								// value for Brightness operation
			THRESHOLD= 90,							// Threshold value for Threshold operation
			SIGN=0									// Sign value using for brightness operation
														// SIGN = 0: Brightness subtraction
														// SIGN = 1: Brightness addition
)
(
	input HCLK,										// clock					
	input HRESETn,									// Reset (active low)
	output VSYNC,								// Vertical synchronous pulse
	// This signal is often a way to indicate that one entire image is transmitted.
	// Just create and is not used, will be used once a video or many images are transmitted.
	output reg HSYNC,								// Horizontal synchronous pulse
	// An HSYNC indicates that one line of the image is transmitted.
	// Used to be a horizontal synchronous signals for writing bmp file.
    output reg [7:0]  DATA_R0,				// 8 bit Red data (even)
    output reg [7:0]  DATA_G0,				// 8 bit Green data (even)
    output reg [7:0]  DATA_B0,				// 8 bit Blue data (even)
    output reg [7:0]  DATA_R1,				// 8 bit Red  data (odd)
    output reg [7:0]  DATA_G1,				// 8 bit Green data (odd)
    output reg [7:0]  DATA_B1,				// 8 bit Blue data (odd)
	// Process and transmit 2 pixels in parallel to make the process faster, you can modify to transmit 1 pixels or more if needed
	output			  ctrl_done					// Done flag
);			
//-------------------------------------------------
// Internal Signals
//-------------------------------------------------

parameter sizeOfWidth = 8;						// data width
parameter sizeOfLengthReal = 1179648; 		// image data : 1179648 bytes: 512 * 768 *3 
// local parameters for FSM
localparam		ST_IDLE 	= 2'b00,		// idle state
				ST_VSYNC	= 2'b01,			// state for creating vsync 
				ST_HSYNC	= 2'b10,			// state for creating hsync 
				ST_DATA		= 2'b11;		// state for data processing 
reg [1:0] cstate, 						// current state
		  nstate;							// next state			
reg start;									// start signal: trigger Finite state machine beginning to operate
reg HRESETn_d;								// delayed reset signal: use to create start signal
reg 		ctrl_vsync_run; 				// control signal for vsync counter  
reg [8:0]	ctrl_vsync_cnt;			// counter for vsync
reg 		ctrl_hsync_run;				// control signal for hsync counter
reg [8:0]	ctrl_hsync_cnt;			// counter  for hsync
reg 		ctrl_data_run;					// control signal for data processing
reg [31 : 0]  in_memory    [0 : sizeOfLengthReal/4]; 	// memory to store  32-bit data image
reg [7 : 0]   total_memory [0 : sizeOfLengthReal-1];	// memory to store  8-bit data image
// temporary memory to save image data : size will be WIDTH*HEIGHT*3
integer temp_BMP   [0 : WIDTH*HEIGHT*3 - 1];			
integer org_R  [0 : WIDTH*HEIGHT - 1]; 	// temporary storage for R component
integer org_G  [0 : WIDTH*HEIGHT - 1];	// temporary storage for G component
integer org_B  [0 : WIDTH*HEIGHT - 1];	// temporary storage for B component
// counting variables
integer i, j;
// temporary signals for calculation: details in the paper.
integer tempR0,tempR1,tempG0,tempG1,tempB0,tempB1; // temporary variables in contrast and brightness operation

integer value,value1,value2,value4,value5,value6,value7,value8,value9,value10,value11,value12;// temporary variables in operations
reg [ 9:0] row; // row index of the image
reg [10:0] col; // column index of the image
reg [18:0] data_count; // data counting for entire pixels of the image


reg [7:0] window_R0 [0:2][0:2]; //used for methods that require knowledge of nearby pixels in a 3x3 grid
reg [7:0] window_G0 [0:2][0:2];
reg [7:0] window_B0 [0:2][0:2];
reg [7:0] window_R1 [0:2][0:2]; 
reg [7:0] window_G1 [0:2][0:2];
reg [7:0] window_B1 [0:2][0:2];

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
    
    
//-------------------------------------------------//
// -------- Reading data from input file ----------//
//-------------------------------------------------//
initial begin
    $readmemh(INFILE,total_memory,0,sizeOfLengthReal-1); // read file from INFILE
end
// use 3 intermediate signals RGB to save image data
always@(start) begin
    if(start == 1'b1) begin
        for(i=0; i<WIDTH*HEIGHT*3 ; i=i+1) begin
            temp_BMP[i] = total_memory[i+0][7:0]; 
        end
        
        for(i=0; i<HEIGHT; i=i+1) begin
            for(j=0; j<WIDTH; j=j+1) begin
                org_R[WIDTH*i+j] = temp_BMP[WIDTH*3*(HEIGHT-i-1)+3*j+0]; // save Red component
                org_G[WIDTH*i+j] = temp_BMP[WIDTH*3*(HEIGHT-i-1)+3*j+1];// save Green component
                org_B[WIDTH*i+j] = temp_BMP[WIDTH*3*(HEIGHT-i-1)+3*j+2];// save Blue component
            end
        end
    end
end
//----------------------------------------------------//
// ---Begin to read image file once reset was high ---//
// ---by creating a starting pulse (start)------------//
//----------------------------------------------------//
always@(posedge HCLK, negedge HRESETn)
begin
    if(!HRESETn) begin
        start <= 0;
		HRESETn_d <= 0;
    end
    else begin											//        		______ 				
        HRESETn_d <= HRESETn;							//       	|		|
		if(HRESETn == 1'b1 && HRESETn_d == 1'b0)		// __0___|	1	|___0____	: starting pulse
			start <= 1'b1;
		else
			start <= 1'b0;
    end
end

//-----------------------------------------------------------------------------------------------//
// Finite state machine for reading RGB888 data from memory and creating hsync and vsync pulses --//
//-----------------------------------------------------------------------------------------------//
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        cstate <= ST_IDLE;
    end
    else begin
        cstate <= nstate; // update next state 
    end
end
//-----------------------------------------//
//--------- State Transition --------------//
//-----------------------------------------//
// IDLE . VSYNC . HSYNC . DATA
always @(*) begin
	case(cstate)
		ST_IDLE: begin
			if(start)
				nstate = ST_VSYNC;
			else
				nstate = ST_IDLE;
		end			
		ST_VSYNC: begin
			if(ctrl_vsync_cnt == START_UP_DELAY) 
				nstate = ST_HSYNC;
			else
				nstate = ST_VSYNC;
		end
		ST_HSYNC: begin
			if(ctrl_hsync_cnt == HSYNC_DELAY) 
				nstate = ST_DATA;
			else
				nstate = ST_HSYNC;
		end		
		ST_DATA: begin
			if(ctrl_done)
				nstate = ST_IDLE;
			else begin
				if(col == WIDTH - 2)
					nstate = ST_HSYNC;
				else
					nstate = ST_DATA;
			end
		end
	endcase
end
// ------------------------------------------------------------------- //
// --- counting for time period of vsync, hsync, data processing ----  //
// ------------------------------------------------------------------- //
always @(*) begin
	ctrl_vsync_run = 0;
	ctrl_hsync_run = 0;
	ctrl_data_run  = 0;
	case(cstate)
		ST_VSYNC: 	begin ctrl_vsync_run = 1; end 	// trigger counting for vsync
		ST_HSYNC: 	begin ctrl_hsync_run = 1; end	// trigger counting for hsync
		ST_DATA: 	begin ctrl_data_run  = 1; end	// trigger counting for data processing
	endcase
end
// counters for vsync, hsync
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        ctrl_vsync_cnt <= 0;
		ctrl_hsync_cnt <= 0;
    end
    else begin
        if(ctrl_vsync_run)
			ctrl_vsync_cnt <= ctrl_vsync_cnt + 1; // counting for vsync
		else 
			ctrl_vsync_cnt <= 0;
			
        if(ctrl_hsync_run)
			ctrl_hsync_cnt <= ctrl_hsync_cnt + 1;	// counting for hsync		
		else
			ctrl_hsync_cnt <= 0;
    end
end
// counting column and row index  for reading memory 
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        row <= 0;
		col <= 0;
    end
	else begin
		if(ctrl_data_run) begin
			if(col == WIDTH - 2) begin
				row <= row + 1;
			end
			if(col == WIDTH - 2) 
				col <= 0;
			else 
				col <= col + 2; // reading 2 pixels in parallel
		end
	end
end
//-------------------------------------------------//
//----------------Data counting---------- ---------//
//-------------------------------------------------//
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        data_count <= 0;
    end
    else begin
        if(ctrl_data_run)
			data_count <= data_count + 1;
    end
end
assign VSYNC = ctrl_vsync_run;
assign ctrl_done = (data_count == 196607)? 1'b1: 1'b0; // done flag
//-------------------------------------------------//
//-------------  Image processing   ---------------//
//-------------------------------------------------//
always @(*) begin
	
	HSYNC   = 1'b0;
	DATA_R0 = 0;
	DATA_G0 = 0;
	DATA_B0 = 0;                                       
	DATA_R1 = 0;
	DATA_G1 = 0;
	DATA_B1 = 0;                                         
	if(ctrl_data_run) begin
	
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
		

		
		
		HSYNC   = 1'b1;
		`ifdef BRIGHTNESS_ADDITION_OPERATION	
		/**************************************/		
		/*		BRIGHTNESS ADDITION OPERATION */
		/**************************************/
		//if(SIGN == 1) begin
		// R0
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
		`endif
	//end
	//else begin
	/**************************************/		
	/*	BRIGHTNESS SUBTRACTION OPERATION */
	/**************************************/
	`ifdef BRIGHTNESS_SUBTRACTION_OPERATION
		// R0
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
	 //end
		`endif
	
		/**************************************/		
		/*		INVERT_OPERATION  			  */
		/**************************************/
		`ifdef INVERT_OPERATION	
			value2 = (org_B[WIDTH * row + col  ] + org_R[WIDTH * row + col  ] +org_G[WIDTH * row + col  ])/3;
			DATA_R0=255-value2;
			DATA_G0=255-value2;
			DATA_B0=255-value2;
			value4 = (org_B[WIDTH * row + col+1  ] + org_R[WIDTH * row + col+1  ] +org_G[WIDTH * row + col+1  ])/3;
			DATA_R1=255-value4;
			DATA_G1=255-value4;
			DATA_B1=255-value4;		
		`endif
		/**************************************/		
		/********THRESHOLD OPERATION  *********/
		/**************************************/
		`ifdef THRESHOLD_OPERATION

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
		`endif
		
		/**************************************/		
		/*		RED_OPERATION       	      */
		/**************************************/
		
		`ifdef RED_OPERATION
		DATA_R0=org_R[WIDTH * row + col  ];
		DATA_G0=0;
		DATA_B0=0;
		
		DATA_R1=org_R[WIDTH * row + col+1  ];
		DATA_G1=0;
		DATA_B1=0;
		`endif
		/**************************************/		
		/*		GREEN_OPERATION       	      */
		/**************************************/
		
		`ifdef GREEN_OPERATION
		DATA_R0=0;
		DATA_G0=org_G[WIDTH * row + col  ];
		DATA_B0=0;
		
		DATA_R1=0;
		DATA_G1=org_G[WIDTH * row + col+1  ];
		DATA_B1=0;
		`endif
		/**************************************/		
		/*		BLUE_OPERATION       	      */
		/**************************************/
		
		`ifdef BLUE_OPERATION
		DATA_R0=0;
		DATA_G0=0;
		DATA_B0=org_B[WIDTH * row + col  ];
		
		DATA_R1=0;
		DATA_G1=0;
		DATA_B1=org_B[WIDTH * row + col+1  ];
		`endif

		/**************************************/		
		/*		GRAYSCALE_OPERATION       	  */
		/**************************************/
		
		`ifdef GRAYSCALE_OPERATION
		value5 = (5'd30 * org_R[WIDTH * row + col   ] + 6'd59* org_G[WIDTH * row + col   ] + 4'd11 * org_B[WIDTH * row + col   ]) / 100;
		DATA_R0=value5;
		DATA_G0=value5;
		DATA_B0=value5;
		value6 = (5'd30 * org_R[WIDTH * row + col+1   ] + 6'd59* org_G[WIDTH * row + col+1   ] + 4'd11 * org_B[WIDTH * row + col+1   ]) / 100;
		DATA_R1=value6;
		DATA_G1=value6;
		DATA_B1=value6;	
		`endif
		
		/**************************************/		
		/*		TRIP_OPERATION       	      */
		/**************************************/
		
		`ifdef TRIP_OPERATION
		value5 = (5'd30 * org_R[WIDTH * row + col   ] + 6'd59* org_G[WIDTH * row + col   ] + 4'd11 * org_B[WIDTH * row + col   ]);
		DATA_R0=value5;
		DATA_G0=value5;
		DATA_B0=value5;
		value6 = (5'd30 * org_R[WIDTH * row + col+1   ] + 6'd59* org_G[WIDTH * row + col+1   ] + 4'd11 * org_B[WIDTH * row + col+1   ]);
		DATA_R1=value6;
		DATA_G1=value6;
		DATA_B1=value6;	
		`endif
		
		/**************************************/		
		/*		BLUR_OPERATION       	      */
		/**************************************/
		`ifdef BLUR_OPERATION

		//apply blur filter to pixels
        DATA_R0 = (window_R0[0][0] + window_R0[0][1] + window_R0[0][2] + window_R0[1][0] + window_R0[1][1] + window_R0[1][2] + window_R0[2][0] + window_R0[2][1] + window_R0[2][2]) / 9;
        DATA_G0 = (window_G0[0][0] + window_G0[0][1] + window_G0[0][2] + window_G0[1][0] + window_G0[1][1] + window_G0[1][2] + window_G0[2][0] + window_G0[2][1] + window_G0[2][2]) / 9;
        DATA_B0 = (window_B0[0][0] + window_B0[0][1] + window_B0[0][2] + window_B0[1][0] + window_B0[1][1] + window_B0[1][2] + window_B0[2][0] + window_B0[2][1] + window_B0[2][2]) / 9;
        DATA_R1 = (window_R1[0][0] + window_R1[0][1] + window_R1[0][2] + window_R1[1][0] + window_R1[1][1] + window_R1[1][2] + window_R1[2][0] + window_R1[2][1] + window_R1[2][2]) / 9;
        DATA_G1 = (window_G1[0][0] + window_G1[0][1] + window_G1[0][2] + window_G1[1][0] + window_G1[1][1] + window_G1[1][2] + window_G1[2][0] + window_G1[2][1] + window_G1[2][2]) / 9;
        DATA_B1 = (window_B1[0][0] + window_B1[0][1] + window_B1[0][2] + window_B1[1][0] + window_B1[1][1] + window_B1[1][2] + window_B1[2][0] + window_B1[2][1] + window_B1[2][2]) / 9;
		`endif
		
		/**************************************/		
		/*		SHARPEN_OPERATION       	  */
		/**************************************/
		`ifdef SHARPEN_OPERATION
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
		
		
		`endif
		
		/**************************************/		
		/*		OIL_OPERATION          	      */
		/**************************************/
		
		// create histogram with loose granularity and define colors based on that 
		`ifdef OIL_OPERATION
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
                $display("BO VALUE: %d", window_B0[i][j]);
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
        
        $display("BO color chart value 0: %d", color_chart_B0[0]);
        $display("BO color chart value 1: %d", color_chart_B0[1]);
        $display("BO color chart value 2: %d", color_chart_B0[2]);
        $display("BO color chart value 3: %d", color_chart_B0[3]);
        $display("BO color chart value 4: %d", color_chart_B0[4]);
        $display("BO color chart value 5: %d", color_chart_B0[5]);
        $display("BO color chart value 6: %d", color_chart_B0[6]);
        $display("BO color chart value 7: %d", color_chart_B0[7]);
        $display("BO color chart value 8: %d", color_chart_B0[8]);
        $display("BO color chart value 9: %d", color_chart_B0[9]);
        $display("BO color chart value 10: %d", color_chart_B0[10]);
        $display("BO color chart value 11: %d", color_chart_B0[11]);
        $display("BO color chart value 12: %d", color_chart_B0[12]);
        $display("BO color chart value 13: %d", color_chart_B0[13]);
        $display("BO color chart value 14: %d", color_chart_B0[14]);
        
        
        max_color = 0;
        for(i = 0; i <=14; i = i + 1) begin
            if (color_chart_B0[i] > max_color) begin
                max_color = i;
            end//if
        end // for
        $display("max color: %d", max_color);
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
		//$display("B1 VALUE: %d", DATA_B1);
		
		`endif
		
		
	end
end

//function [7:0] apply_oil_effect;
//    input [7:0] window_temp [0:2][0:2];
//    reg [7:0] result;
//    integer i, j;
//    reg[7:0] color_histogram [0:255];
//    reg[7:0] max_color;
//    begin
//    for(i=0; i <= 2; i= i + 1)begin
//        for(j = 0; j <= 2; j = j + 1) begin
//            color_histogram[window_temp[i][j]] = color_histogram[window_temp[i][j]] + 1;
//        end // for
//    end // for
    
//    max_color = 0;
//    for(i = 1; i <= 255; i = i + 1) begin
//        if (color_histogram[i] > color_histogram[max_color]) begin
//            max_color = i;
//        end//if
//    end // for
//    apply_oil_effect = result;
    
//    end//begin
//endfunction
    
//function [7:0] apply_blur_filter;
//    input [7:0] window [0:2][0:2];
//    reg  [7:0] result;
//    integer i, j;
//    begin
//    result = 0;
    
//    //convolve the windo with the blur kernel
//    for (i = 0; i<= 2; i = i + 1) begin
//        for (j= 0; j <= 2; j = j + 1) begin
//            result = result + (window[i][j] * blur_kernel[i][j]);
//        end // for
//    end // for
    
//    result = result / 9;
    
//    apply_blur_filter = result;
//    end // begin
//endfunction
endmodule