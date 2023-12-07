`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/05/2023 11:43:54 PM
// Design Name: 
// Module Name: frame_buffer
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


module frame_buffer(
    input p_clk, rst,
    input frame_done, pixel_valid, clear_buffer,
    input [11:0] pixel_data,
    input [11:0] fb_bram,
    output reg buffer_full,
    output wire [11:0] bram_readport
    );

    parameter frame_size = 480*640;   // 480x640p
    parameter pixel_size = 12;
    localparam frame_pixels = frame_size * pixel_size;

    // Initialize block RAM
//    reg [11:0] frame_buffer [0:frame_pixels-1];  // block ram for data
    reg [18:0] fb_index;    // 19-bit counter to keep track of frame buffer location
    assign bram_readport = fb_bram[0]; // Set read port to be the first bit of frame_buffer

    // Set up FSM
    localparam  CLEAR_BUF=0, // FSM names
                BUF_WRITE=1, 
                BUF_FULL=2;
    reg [1:0] fsm_state=0;

    // FSM
    // FS
    // always @ (posedge p_clk, posedge rst) begin  // Handling synchronization in top module
    always @ (*) begin
        if (rst) begin
            fb_index <= 0;
            buffer_full <= 0;
            fb_bram <= {(frame_size){12'b0}};  // Fill frame_buffer with zeros
        end
        else begin
            case (fsm_state) 
                CLEAR_BUF: begin
                    fb_index <= 0;
                    buffer_full <= 0;
                    fb_bram <= {(frame_size){12'b0}};  // Fill frame_buffer with zeros

                    fsm_state <= clear_buffer ? CLEAR_BUF : BUF_WRITE;
                end
                BUF_WRITE: begin
                    fb_bram[fb_index] <= pixel_valid ? pixel_data : 12'b0;  // If pixel not valid, fill with 0s
                    fb_index <= fb_index + 1;

                    fsm_state <= clear_buffer ? CLEAR_BUF : (fb_index == frame_size-1) || (frame_done) ? BUF_FULL : BUF_WRITE;
                end
                BUF_FULL: begin
                    buffer_full <= 1;

                    fsm_state <= clear_buffer ? CLEAR_BUF : BUF_FULL;   // Wait for input to clear buffer
                end
                default: begin
                    fsm_state <= CLEAR_BUF;
                end
            endcase
        end 
    end


endmodule
