`timescale 1ns / 1ps

module top(
    input clk_i,
    input reset_n,
    input hrclk_mode,
    input BTNC,
    input BTNU,
    input BTNL,
    input BTNR,
    input BTND,
    
    output wire [3:0] VGA_R,
    output wire [3:0] VGA_G,
    output wire [3:0] VGA_B,
    output wire VGA_HS,
    output wire VGA_VS
    );
    reg [35:0] top_square_counter;
    wire [35:0] clockCounter, swCounter, timerCounter;
    reg [2:0] editDigit;
    wire [1:0] clockDigit;
    wire [2:0] timerDigit;
    reg [1:0] mode;
    wire am_pm, format, clock_edit, timer_edit, timer_done;
    reg [9:0] hit = 0;
    reg hrD, hrL, hrR, hrC, edit_in;
    reg tL, tC, tR, tD;        //tBTNC = start or increment, depending on toggle mode
    reg swStart, swStop, swReset;
    wire clk_khz;
    wire debBTNU, debBTNL, debBTNC, debBTNR, debBTND;
    
    top_square ts(.CLK(clk_i), 
                  .RST_BTN(reset_n), 
                  .random_num(top_square_counter), 
                  .mode(mode),
                  .clockfmt(format),
                  .am_pm(am_pm),
                  .editmode(edit_in),
                  .editDigit(editDigit),
                  .timer_done(timer_done),
                  .VGA_HS_O(VGA_HS), 
                  .VGA_VS_O(VGA_VS), 
                  .VGA_R(VGA_R), 
                  .VGA_G(VGA_G), 
                  .VGA_B(VGA_B));
                  
    clock12_24 clock(.clk(clk_khz), 
                     .m_sw(hrclk_mode), 
                     .bD(hrD), 
                     .bL(hrL), 
                     .bR(hrR), 
                     .bC(hrC), 
                     .fmt(format), 
                     .ampm(am_pm), 
                     .edit(clock_edit),
                     .currDigit(clockDigit), 
                     .outReg(clockCounter));
    
    stopwatch sw(.clk_i(clk_i), 
                 .resetn(swReset), 
                 .start(swStart), 
                 .stop(swStop), 
                 .out_o(swCounter));
                 
    timer timer(.clk(clk_khz), 
                .bC(tC), 
                .bL(tL), 
                .bD(tD), 
                .bR(tR), 
                .out_o(timerCounter), 
                .curr_digit(timerDigit), 
                .edit(timer_edit), 
                .done(timer_done));
    
    debouncer debU(.clk_i(clk_khz), .resetn_btn_i(reset_n), .increment_counter_btn_i(BTNU), .btn_o(debBTNU));
    debouncer debL(.clk_i(clk_khz), .resetn_btn_i(reset_n), .increment_counter_btn_i(BTNL), .btn_o(debBTNL));
    debouncer debC(.clk_i(clk_khz), .resetn_btn_i(reset_n), .increment_counter_btn_i(BTNC), .btn_o(debBTNC));
    debouncer debR(.clk_i(clk_khz), .resetn_btn_i(reset_n), .increment_counter_btn_i(BTNR), .btn_o(debBTNR));
    debouncer debD(.clk_i(clk_khz), .resetn_btn_i(reset_n), .increment_counter_btn_i(BTND), .btn_o(debBTND));
    
    clock_divider cd0(.clk(clk_i), .div_clk(clk_khz));
//    counter36(.clk_i(clk_khz), .resetn_i(reset_n), .count_o(clockCounter)); 
    
    // start at hour clock mode
    initial begin
        mode <= 2'b00;
    end //initial
    
    // BTNU is used to cycle between the modes, and choose which wires the input buttons will map to
    // mode 0 = 12hr clock, mode 1 = 24hr clock, mode 2 = timer, mode 3 = stopwatch
    always @(posedge clk_khz) begin
        if (debBTNU == 1) begin
            case (mode)
                2'b00: mode <= 2'b01;
                2'b01: mode <= 2'b10;
                2'b10: mode <= 2'b00;
                default: mode <= 2'b00;
            endcase
        end
    end //always
    
    // On every change, update the input ports of the current mode
    always @(*) begin
        case (mode) 
            2'b00: begin
                hrD <= debBTND;
                hrL <= debBTNL;
                hrR <= debBTNR;
                hrC <= debBTNC;
                edit_in <= clock_edit;
                editDigit <= clockDigit;
                top_square_counter <= clockCounter;
            end
            2'b01: begin
                swStart <= debBTNL;
                swStop <= debBTNR;
                swReset <= debBTND;
                top_square_counter <= swCounter;
            end
            2'b10: begin
                tC <= debBTNC;
                tD <= debBTND;
                tL <= debBTNL;
                tR <= debBTNR;
                edit_in <= timer_edit;
                editDigit <= timerDigit;
                top_square_counter <= timerCounter;
            end
        endcase
    end //always
    
    
endmodule
