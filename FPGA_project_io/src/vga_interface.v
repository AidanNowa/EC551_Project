`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//  Code taken from: 
//      https://github.com/AngeloJacobo/FPGA_OV7670_Camera_Interface/blob/main/src/vga_interface.v
//
//  Largely modified to work specifically with our implementation
//
//////////////////////////////////////////////////////////////////////////////////

module vga_interface(
    input sysclk,
    input sysrst,
    input[11:0] pixel_data,

    output wire vga_out_clk,        // VGA clock, 25MHz
    output wire[18:0] read_address, // Address for BRAM read
    output reg[3:0] vga_out_r,
	output reg[3:0] vga_out_g,
	output reg[3:0] vga_out_b,
    output reg vga_out_vs,         // VSYNC signal
    output reg vga_out_hs         // HSYNC signal
    );

    /** FSM Setup */
    localparam START_FRAME=0;
    localparam END_FRAME=1;
    localparam END_LINE=2;
    localparam DISPLAY=3;

    /** Registers */
    reg[1:0] fsm_state = END_FRAME;
    reg rst_clk;

    reg[18:0] px_counter; // Keeps track of how many pixels have been read

    /** Wires */
    wire vga_clk;
    wire locked_clk;
    
    /** Module Instantiations */
    dcm_25MHz m1 (              // clock for vga(620x480 60fps), from Xilinx
        .clk(sysclk),  
        .clk_out(vga_clk),
        .RESET(rst_clk),
        .LOCKED(locked_clk)
    );

    /** VGA clock output assignment */
    assign vga_out_clk = vga_clk;
    assign read_address = px_counter;

    /** VGA write state machine */
    always @(posedge vga_clk) begin
        case (fsm_state)
            START_FRAME: begin // Start of frame - return VSYNC and HSYNC to high
                px_counter <= 0;    // Reinitialize px_counter
                vga_out_vs <= 1;
                vga_out_hs <= 1;
            end
            END_FRAME: begin    // End of frame, pulse vsync low, keep hsync high
                vga_out_vs <= 0;
                vga_out_hs <= 1;
                fsm_state <= START_FRAME;
            end
            END_LINE: begin     // End of line, pulse hsync low, keep vsync high, don't touch px_counter
                vga_out_vs <= 1;
                vga_out_hs <= 0;
                fsm_state <= DISPLAY;
            end
            DISPLAY: begin
                px_counter <= px_counter + 1;       // Increment pixel counter
                vga_out_vs <= 1;
                vga_out_hs <= 1;

                {vga_out_r, vga_out_g, vga_out_b} <= pixel_data;    // Display pixel

                if (px_counter % 640 == 0 && px_counter != 307199) fsm_state <= END_LINE;
                else if (px_counter == 307199) fsm_state <= END_FRAME;
                else fsm_state <= DISPLAY;
            end
            default: fsm_state <= START_FRAME;
        endcase
    end
endmodule