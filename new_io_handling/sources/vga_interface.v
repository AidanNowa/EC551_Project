`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//  Code taken from: 
//      https://github.com/AngeloJacobo/FPGA_OV7670_Camera_Interface/blob/main/src/vga_interface.v
//
//  Largely modified to work specifically with our implementation
//
//////////////////////////////////////////////////////////////////////////////////

module vga_interface(
	input wire clk,rst, display_enable,
    input [11:0] bram_readport, // Wire pointing to 0'th index of bram
	//VGA output
	output reg[3:0] vga_out_r,
	output reg[3:0] vga_out_g,
	output reg[3:0] vga_out_b,
	output wire vga_out_vs,vga_out_hs,
	output wire [11:0] pixel_x, pixel_y
    );

    // FSM setup
    localparam  IDLE=0,
                DISPLAY=1;
    reg fsm_state=0;
    wire clk_out;
    wire locked_clk;
    reg rst_clk;
    
    	//module instantiations
	vga_core m0
	(
		.clk(clk_out), //clock must be 25MHz for 640x480
		.rst_n(rst),  
		.hsync(vga_out_hs),
		.vsync(vga_out_vs),
		.video_on(),
		.pixel_x(pixel_x),
		.pixel_y(pixel_y)
	);	
	
    dcm_25MHz m1 (//clock for vga(620x480 60fps) 
        // Clock in ports
        .clk(clk),      // IN
        
        // Clock out ports
        .clk_out(clk_out),     // OUT
    
        // Status and control signals
        .RESET(rst_clk),      // IN
        .LOCKED(locked_clk)      // OUT
    );

    // Need to iterate through bram. If index % 640 ==0, this is end of line and we set vga_out_hs
    // This is where we can do pixel-wise transformations!
    always @(posedge clk_out) begin


        case (fsm_state)
            IDLE: begin // Waiting on camera read
                vga_out_r=0;
                vga_out_g=0;
                vga_out_b=0;    
                
                fsm_state <= display_enable ? DISPLAY : IDLE;
            end

            DISPLAY: begin
                // Iterate throught bram. When index%640==0, set href signal.
                // When index == num_pixels, set vsync
                //mem_addr <= pixel_y * 640 + pixel_x; // Calculate BRAM address
                {vga_out_r, vga_out_g, vga_out_b} <= bram_readport; // Read and display pixel
            end

        endcase


    end	

	 


endmodule