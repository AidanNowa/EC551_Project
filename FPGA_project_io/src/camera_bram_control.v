`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2023 07:02:22 PM
// Design Name: 
// Module Name: bram_controller
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


module camera_bram_controller(
    input sysrst,
    input p_clk,
    input cmos_config_done,
    input cmos_frame_done,              // Signals end of one frame/start of another
    output reg bram_write_enable,
    output reg[18:0] bram_address
);
    /** FSM states */
    localparam IDLE = 0;                // Default case
    localparam WAIT_FRAME_START = 1;    // Frame has been completed, waiting for new frame input to start
    localparam START_WRITE_FRAME = 2;   // Start writing new frame from camera
    localparam WRITE_FRAME = 3;         // Continue writing frame, incrementing address each time

    /** Registers */
    reg[1:0] fsm_state = IDLE;

    /** FSM (combinational, as synchronization is handled in bram_memory) */
    always @ (posedge p_clk) begin
        case(fsm_state)
            IDLE: begin
                bram_write_enable <= 0;
                bram_address <= 19'b0;

                fsm_state <= cmos_frame_done ? WAIT_FRAME_START : IDLE;
            end
            WAIT_FRAME_START: begin
                bram_write_enable <= 0;
                bram_address <= 19'b0;

                fsm_state <= !cmos_frame_done ? START_WRITE_FRAME : IDLE;
            end
            START_WRITE_FRAME: begin
                bram_write_enable <= 1;
                bram_address <= 19'b0;
                fsm_state <= WRITE_FRAME;
            end
            WRITE_FRAME: begin
                bram_write_enable <= 1;
                bram_address <= bram_address + 1;  // Increment address
                fsm_state <= cmos_frame_done ? IDLE : WRITE_FRAME;
            end
        endcase
        
//        if(!cmos_config_done || sysrst) fsm_state <= IDLE;

    end









endmodule

