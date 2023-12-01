`timescale 1ns / 1ps

module top_square(
    input wire CLK,             // board clock: 100 MHz on Arty/Basys3/Nexys
    input wire RST_BTN,
    input wire [35:0] random_num,
    input wire [1:0] mode,
    input wire clockfmt,
    input wire am_pm,
    input wire editmode,
    input wire [2:0] editDigit,
    input wire timer_done,
    output wire VGA_HS_O,       // horizontal sync output
    output wire VGA_VS_O,       // vertical sync output
    output wire [3:0] VGA_R,    // 4-bit VGA red output
    output wire [3:0] VGA_G,    // 4-bit VGA green output
    output wire [3:0] VGA_B     // 4-bit VGA blue output
    );

    wire rst = ~RST_BTN;    // reset is active low on Arty & Nexys Video
    

    // generate a 25 MHz pixel strobe
    reg [15:0] cnt;
    reg pix_stb;
    always @(posedge CLK)
        {pix_stb, cnt} <= cnt + 16'h4000;  // divide by 4: (2^16)/4 = 0x4000

    wire [9:0] x;  // current pixel x position: 10-bit value: 0-1023
    wire [8:0] y;  // current pixel y position:  9-bit value: 0-511

    vga640x480 display (
        .i_clk(CLK),
        .i_pix_stb(pix_stb),
        .i_rst(rst),
        .o_hs(VGA_HS_O), 
        .o_vs(VGA_VS_O), 
        .o_x(x), 
        .o_y(y)
    );

    // Wires to hold regions on FPGA
    wire fullscreen;
    wire [8:0] leftdigit_blank;
    wire [7:0] leftdigit_ss;
    wire [6:0] h2, h1, m2, m1, s2, s1, ms3, ms2, ms1;
    wire [6:0] PA, M, clk5, clk4, clk3, clk2, clk1, sw9, sw8, sw7, sw6, sw5, sw4, sw3, sw2, sw1, t5, t4, t3, t2, t1;
    wire [1:0] c2, c1;
	
    //Registers for entities
	reg green,red, blue;
	reg [10:0] sumred, sumwhite, sumgreen;
	
	// Creating Regions on the VGA Display represented as wires (640x480)
	
	// fullscreen encompasses the full area of action
    assign fullscreen = ((x > 52 ) & (x < 573) & (y > 179) & (y < 311)) ? 1 : 0;
    assign h2[0] = ((x > 52) & (x < 111) & (y > 179) & (y < 194)) ? 1 : 0;
    assign h2[1] = ((x > 95) & (x < 111) & (y > 179) & (y < 229)) ? 1 : 0;
    assign h2[2] = ((x > 95) & (x < 111) & (y > 214) & (y < 262)) ? 1 : 0;
    assign h2[3] = ((x > 52) & (x < 111) & (y > 249) & (y < 264)) ? 1 : 0;
    assign h2[4] = ((x > 52) & (x < 69) & (y > 214) & (y < 262)) ? 1 : 0;
    assign h2[5] = ((x > 52) & (x < 69) & (y > 179) & (y < 229)) ? 1 : 0;
    assign h2[6] = ((x > 52) & (x < 111) & (y > 214) & (y < 229)) ? 1 : 0;
    
    assign h1[0] = ((x > 69 + 52) & (x < 69 + 111) & (y > 179) & (y < 194)) ? 1 : 0;
    assign h1[1] = ((x > 69 + 95) & (x < 69 + 111) & (y > 179) & (y < 229)) ? 1 : 0;
    assign h1[2] = ((x > 69 + 95) & (x < 69 + 111) & (y > 214) & (y < 262)) ? 1 : 0;
    assign h1[3] = ((x > 69 + 52) & (x < 69 + 111) & (y > 249) & (y < 264)) ? 1 : 0;
    assign h1[4] = ((x > 69 + 52) & (x < 69 + 69) & (y > 214) & (y < 262)) ? 1 : 0;
    assign h1[5] = ((x > 69 + 52) & (x < 69 + 69) & (y > 179) & (y < 229)) ? 1 : 0;
    assign h1[6] = ((x > 69 + 52) & (x < 69 + 111) & (y > 214) & (y < 229)) ? 1 : 0;
    
    assign m2[0] = ((x > 166 + 52) & (x < 166 + 111) & (y > 179) & (y < 194)) ? 1 : 0;
    assign m2[1] = ((x > 166 + 95) & (x < 166 + 111) & (y > 179) & (y < 229)) ? 1 : 0;
    assign m2[2] = ((x > 166 + 95) & (x < 166 + 111) & (y > 214) & (y < 262)) ? 1 : 0;
    assign m2[3] = ((x > 166 + 52) & (x < 166 + 111) & (y > 249) & (y < 264)) ? 1 : 0;
    assign m2[4] = ((x > 166 + 52) & (x < 166 + 69) & (y > 214) & (y < 262)) ? 1 : 0;
    assign m2[5] = ((x > 166 + 52) & (x < 166 + 69) & (y > 179) & (y < 229)) ? 1 : 0;
    assign m2[6] = ((x > 166 + 52) & (x < 166 + 111) & (y > 214) & (y < 229)) ? 1 : 0;
    
    assign m1[0] = ((x > 235 + 52) & (x < 235 + 111) & (y > 179) & (y < 194)) ? 1 : 0;
    assign m1[1] = ((x > 235 + 95) & (x < 235 + 111) & (y > 179) & (y < 229)) ? 1 : 0;
    assign m1[2] = ((x > 235 + 95) & (x < 235 + 111) & (y > 214) & (y < 262)) ? 1 : 0;
    assign m1[3] = ((x > 235 + 52) & (x < 235 + 111) & (y > 249) & (y < 264)) ? 1 : 0;
    assign m1[4] = ((x > 235 + 52) & (x < 235 + 69) & (y > 214) & (y < 262)) ? 1 : 0;
    assign m1[5] = ((x > 235 + 52) & (x < 235 + 69) & (y > 179) & (y < 229)) ? 1 : 0;
    assign m1[6] = ((x > 235 + 52) & (x < 235 + 111) & (y > 214) & (y < 229)) ? 1 : 0;
    
    assign s2[0] = ((x > 332 + 52) & (x < 332 + 111) & (y > 179) & (y < 194)) ? 1 : 0;
    assign s2[1] = ((x > 332 + 95) & (x < 332 + 111) & (y > 179) & (y < 229)) ? 1 : 0;
    assign s2[2] = ((x > 332 + 95) & (x < 332 + 111) & (y > 214) & (y < 262)) ? 1 : 0;
    assign s2[3] = ((x > 332 + 52) & (x < 332 + 111) & (y > 249) & (y < 264)) ? 1 : 0;
    assign s2[4] = ((x > 332 + 52) & (x < 332 + 69) & (y > 214) & (y < 262)) ? 1 : 0;
    assign s2[5] = ((x > 332 + 52) & (x < 332 + 69) & (y > 179) & (y < 229)) ? 1 : 0;
    assign s2[6] = ((x > 332 + 52) & (x < 332 + 111) & (y > 214) & (y < 229)) ? 1 : 0;
    
    assign s1[0] = ((x > 401 + 52) & (x < 401 + 111) & (y > 179) & (y < 194)) ? 1 : 0;
    assign s1[1] = ((x > 401 + 95) & (x < 401 + 111) & (y > 179) & (y < 229)) ? 1 : 0;
    assign s1[2] = ((x > 401 + 95) & (x < 401 + 111) & (y > 214) & (y < 262)) ? 1 : 0;
    assign s1[3] = ((x > 401 + 52) & (x < 401 + 111) & (y > 249) & (y < 264)) ? 1 : 0;
    assign s1[4] = ((x > 401 + 52) & (x < 401 + 69) & (y > 214) & (y < 262)) ? 1 : 0;
    assign s1[5] = ((x > 401 + 52) & (x < 401 + 69) & (y > 179) & (y < 229)) ? 1 : 0;
    assign s1[6] = ((x > 401 + 52) & (x < 401 + 111) & (y > 214) & (y < 229)) ? 1 : 0;

    assign ms3[0] = ((x > 518) & (x < 535) & (y > 240) & (y < 245)) ? 1 : 0 ;
    assign ms3[1] = ((x > 530) & (x < 535) & (y > 240) & (y < 254)) ? 1 : 0 ;
    assign ms3[2] = ((x > 530) & (x < 535) & (y > 250) & (y < 264)) ? 1 : 0 ;
    assign ms3[3] = ((x > 518) & (x < 535) & (y > 259) & (y < 264)) ? 1 : 0 ;
    assign ms3[4] = ((x > 518) & (x < 523) & (y > 250) & (y < 264)) ? 1 : 0 ;
    assign ms3[5] = ((x > 518) & (x < 523) & (y > 240) & (y < 254)) ? 1 : 0 ;
    assign ms3[6] = ((x > 518) & (x < 535) & (y > 250) & (y < 254)) ? 1 : 0 ;
    
    assign ms2[0] = ((x > 19 + 518) & (x < 19 + 535) & (y > 240) & (y < 245)) ? 1 : 0 ;
    assign ms2[1] = ((x > 19 + 530) & (x < 19 + 535) & (y > 240) & (y < 254)) ? 1 : 0 ;
    assign ms2[2] = ((x > 19 + 530) & (x < 19 + 535) & (y > 250) & (y < 264)) ? 1 : 0 ;
    assign ms2[3] = ((x > 19 + 518) & (x < 19 + 535) & (y > 259) & (y < 264)) ? 1 : 0 ;
    assign ms2[4] = ((x > 19 + 518) & (x < 19 + 523) & (y > 250) & (y < 264)) ? 1 : 0 ;
    assign ms2[5] = ((x > 19 + 518) & (x < 19 + 523) & (y > 240) & (y < 254)) ? 1 : 0 ;
    assign ms2[6] = ((x > 19 + 518) & (x < 19 + 535) & (y > 250) & (y < 254)) ? 1 : 0 ;
    
    assign ms1[0] = ((x > 38 + 518) & (x < 38 + 535) & (y > 240) & (y < 245)) ? 1 : 0 ;  
    assign ms1[1] = ((x > 38 + 530) & (x < 38 + 535) & (y > 240) & (y < 254)) ? 1 : 0 ;
    assign ms1[2] = ((x > 38 + 530) & (x < 38 + 535) & (y > 250) & (y < 264)) ? 1 : 0 ;
    assign ms1[3] = ((x > 38 + 518) & (x < 38 + 535) & (y > 259) & (y < 264)) ? 1 : 0 ;
    assign ms1[4] = ((x > 38 + 518) & (x < 38 + 523) & (y > 250) & (y < 264)) ? 1 : 0 ;
    assign ms1[5] = ((x > 38 + 518) & (x < 38 + 523) & (y > 240) & (y < 254)) ? 1 : 0 ;
    assign ms1[6] = ((x > 38 + 518) & (x < 38 + 535) & (y > 250) & (y < 254)) ? 1 : 0 ;

    assign PA[0] = ((x > 19 + 518) & (x < 19 + 535) & (y > 240 - 61) & (y < 245 - 61)) ? 1 : 0 ;
    assign PA[1] = ((x > 19 + 530) & (x < 19 + 535) & (y > 240 - 61) & (y < 254 - 61)) ? 1 : 0 ;
    assign PA[2] = ((x > 19 + 530) & (x < 19 + 535) & (y > 250 - 61) & (y < 264 - 61)) ? 1 : 0 ;
    assign PA[3] = ((x > 19 + 518) & (x < 19 + 535) & (y > 259 - 61) & (y < 264 - 61)) ? 1 : 0 ;
    assign PA[4] = ((x > 19 + 518) & (x < 19 + 523) & (y > 250 - 61) & (y < 264 - 61)) ? 1 : 0 ;
    assign PA[5] = ((x > 19 + 518) & (x < 19 + 523) & (y > 240 - 61) & (y < 254 - 61)) ? 1 : 0 ;
    assign PA[6] = ((x > 19 + 518) & (x < 19 + 535) & (y > 250 - 61) & (y < 254 - 61)) ? 1 : 0 ;
    
    assign M[0] = ((x > 38 + 518) & (x < 38 + 535) & (y > 250 - 61) & (y < 254 - 61)) ? 1 : 0 ; 
    assign M[1] = ((x > 38 + 530) & (x < 38 + 535) & (y > 250 - 61) & (y < 264 - 61)) ? 1 : 0 ;
    assign M[2] = ((x > 562)      & (x < 567)      & (y > 250 - 61) & (y < 264 - 61)) ? 1 : 0 ;
    assign M[3] = ((x > 38 + 518) & (x < 38 + 523) & (y > 250 - 61) & (y < 264 - 61)) ? 1 : 0 ;

    // base formula
    // assign d[0] = ((x > 52 ) & (x < 69 ) & (y > 287) & (y < 290)) ? 1 : 0 ;
    // assign d[1] = ((x > 64 ) & (x < 69 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    // assign d[2] = ((x > 64 ) & (x < 69 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    // assign d[3] = ((x > 52 ) & (x < 69 ) & (y > 306) & (y < 311)) ? 1 : 0 ;
    // assign d[4] = ((x > 52 ) & (x < 57 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    // assign d[5] = ((x > 52 ) & (x < 57 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    // assign d[6] = ((x > 52 ) & (x < 69 ) & (y > 297) & (y < 301)) ? 1 : 0 ;

    assign clk5[0] = ((x > 52 ) & (x < 69 ) & (y > 287) & (y < 292)) ? 1 : 0 ;
    assign clk5[1] = ((x > 52 ) & (x < 69 ) & (y > 306) & (y < 311)) ? 1 : 0 ;
    assign clk5[2] = ((x > 52 ) & (x < 57 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign clk5[3] = ((x > 52 ) & (x < 57 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    
    assign clk4[0] = ((x > 19 + 52 ) & (x < 19 + 69 ) & (y > 306) & (y < 311)) ? 1 : 0 ;
    assign clk4[1] = ((x > 19 + 52 ) & (x < 19 + 57 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign clk4[2] = ((x > 19 + 52 ) & (x < 19 + 57 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    
    assign clk3[0] = ((x > 38 + 52 ) & (x < 38 + 69 ) & (y > 287) & (y < 292)) ? 1 : 0 ;
    assign clk3[1] = ((x > 38 + 64 ) & (x < 38 + 69 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    assign clk3[2] = ((x > 38 + 64 ) & (x < 38 + 69 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign clk3[3] = ((x > 38 + 52 ) & (x < 38 + 69 ) & (y > 306) & (y < 311)) ? 1 : 0 ;
    assign clk3[4] = ((x > 38 + 52 ) & (x < 38 + 57 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign clk3[5] = ((x > 38 + 52 ) & (x < 38 + 57 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    
    assign clk2[0] = ((x > 57 + 52 ) & (x < 57 + 69 ) & (y > 287) & (y < 292)) ? 1 : 0 ;
    assign clk2[1] = ((x > 57 + 52 ) & (x < 57 + 69 ) & (y > 306) & (y < 311)) ? 1 : 0 ;
    assign clk2[2] = ((x > 57 + 52 ) & (x < 57 + 57 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign clk2[3] = ((x > 57 + 52 ) & (x < 57 + 57 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    
    assign clk1[0] = ((x > 76 + 64 ) & (x < 76 + 69 ) & (y > 287) & (y < 298)) ? 1 : 0 ;
    assign clk1[1] = ((x > 76 + 64 ) & (x < 76 + 69 ) & (y > 300) & (y < 311)) ? 1 : 0 ;
    assign clk1[2] = ((x > 76 + 52 ) & (x < 76 + 57 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign clk1[3] = ((x > 76 + 52 ) & (x < 76 + 57 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    assign clk1[4] = ((x > 76 + 52 ) & (x < 141)      & (y > 297) & (y < 301)) ? 1 : 0 ;
    
    assign sw9[0] = ((x > 146 + 52 ) & (x < 146 + 69 ) & (y > 287) & (y < 292)) ? 1 : 0 ;
    assign sw9[1] = ((x > 146 + 64 ) & (x < 146 + 69 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign sw9[2] = ((x > 146 + 52 ) & (x < 146 + 69 ) & (y > 306) & (y < 311)) ? 1 : 0 ;
    assign sw9[3] = ((x > 146 + 52 ) & (x < 146 + 57 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    assign sw9[4] = ((x > 146 + 52 ) & (x < 146 + 69 ) & (y > 297) & (y < 301)) ? 1 : 0 ;
    
    assign sw8[0] = ((x > 165 + 52 ) & (x < 165 + 69 ) & (y > 287) & (y < 292)) ? 1 : 0 ;
    assign sw8[1] = ((x > 223)       & (x < 228)       & (y > 287) & (y < 311)) ? 1 : 0 ;
    
    assign sw7[0] = ((x > 184 + 52 ) & (x < 184 + 69 ) & (y > 287) & (y < 292)) ? 1 : 0 ;
    assign sw7[1] = ((x > 184 + 64 ) & (x < 184 + 69 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    assign sw7[2] = ((x > 184 + 64 ) & (x < 184 + 69 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign sw7[3] = ((x > 184 + 52 ) & (x < 184 + 69 ) & (y > 306) & (y < 311)) ? 1 : 0 ;
    assign sw7[4] = ((x > 184 + 52 ) & (x < 184 + 57 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign sw7[5] = ((x > 184 + 52 ) & (x < 184 + 57 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    
    assign sw6[0] = ((x > 203 + 52 ) & (x < 203 + 69 ) & (y > 287) & (y < 292)) ? 1 : 0 ;
    assign sw6[1] = ((x > 203 + 64 ) & (x < 203 + 69 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    assign sw6[2] = ((x > 203 + 52 ) & (x < 203 + 57 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign sw6[3] = ((x > 203 + 52 ) & (x < 203 + 57 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    assign sw6[4] = ((x > 203 + 52 ) & (x < 203 + 69 ) & (y > 297) & (y < 301)) ? 1 : 0 ;
    
    assign sw5[0] = ((x > 280)       & (x < 285)       & (y > 296) & (y < 311)) ? 1 : 0 ;
    assign sw5[1] = ((x > 222 + 64 ) & (x < 222 + 69 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    assign sw5[2] = ((x > 222 + 64 ) & (x < 222 + 69 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign sw5[3] = ((x > 222 + 52 ) & (x < 222 + 69 ) & (y > 306) & (y < 311)) ? 1 : 0 ;
    assign sw5[4] = ((x > 222 + 52 ) & (x < 222 + 57 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign sw5[5] = ((x > 222 + 52 ) & (x < 222 + 57 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    
    assign sw4[0] = ((x > 241 + 52 ) & (x < 241 + 69 ) & (y > 287) & (y < 292)) ? 1 : 0 ;
    assign sw4[1] = ((x > 241 + 64 ) & (x < 241 + 69 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    assign sw4[2] = ((x > 241 + 64 ) & (x < 241 + 69 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign sw4[3] = ((x > 241 + 52 ) & (x < 241 + 57 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign sw4[4] = ((x > 241 + 52 ) & (x < 241 + 57 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    assign sw4[5] = ((x > 241 + 52 ) & (x < 241 + 69 ) & (y > 297) & (y < 301)) ? 1 : 0 ;
    
    assign sw3[0] = ((x > 260 + 52 ) & (x < 260 + 69 ) & (y > 287) & (y < 292)) ? 1 : 0 ;
    assign sw3[1] = ((x > 318)       & (x < 323)       & (y > 287) & (y < 311)) ? 1 : 0 ;
    
    assign sw2[0] = ((x > 279 + 52 ) & (x < 279 + 69 ) & (y > 287) & (y < 292)) ? 1 : 0 ;
    assign sw2[1] = ((x > 279 + 52 ) & (x < 279 + 69 ) & (y > 306) & (y < 311)) ? 1 : 0 ;
    assign sw2[2] = ((x > 279 + 52 ) & (x < 279 + 57 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign sw2[3] = ((x > 279 + 52 ) & (x < 279 + 57 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    
    assign sw1[0] = ((x > 298 + 64 ) & (x < 298 + 69 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    assign sw1[1] = ((x > 298 + 64 ) & (x < 298 + 69 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign sw1[2] = ((x > 298 + 52 ) & (x < 298 + 57 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign sw1[3] = ((x > 298 + 52 ) & (x < 298 + 57 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    assign sw1[4] = ((x > 298 + 52 ) & (x < 298 + 69 ) & (y > 297) & (y < 301)) ? 1 : 0 ;
    
    assign t5[0] = ((x > 367 + 52 ) & (x < 367 + 69 ) & (y > 287) & (y < 292)) ? 1 : 0 ;
    assign t5[1] = ((x > 425)       & (x < 430)       & (y > 287) & (y < 311)) ? 1 : 0 ;
    
    assign t4[0] = ((x > 386 + 52 ) & (x < 386 + 69 ) & (y > 287) & (y < 292)) ? 1 : 0 ;
    assign t4[1] = ((x > 386 + 52 ) & (x < 386 + 69 ) & (y > 306) & (y < 311)) ? 1 : 0 ;
    assign t4[2] = ((x > 444)       & (x < 449)       & (y > 291) & (y < 307)) ? 1 : 0 ;
    
    assign t3[0] = ((x > 405 + 52 ) & (x < 405 + 69 ) & (y > 287) & (y < 292)) ? 1 : 0 ;
    assign t3[1] = ((x > 405 + 64 ) & (x < 405 + 69 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    assign t3[2] = ((x > 405 + 64 ) & (x < 405 + 69 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign t3[3] = ((x > 463)       & (x < 468)       & (y > 291) & (y < 301)) ? 1 : 0 ;
    assign t3[4] = ((x > 405 + 52 ) & (x < 405 + 57 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign t3[5] = ((x > 405 + 52 ) & (x < 405 + 57 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    
    assign t2[0] = ((x > 424 + 52 ) & (x < 424 + 69 ) & (y > 287) & (y < 292)) ? 1 : 0 ;
    assign t2[1] = ((x > 424 + 52 ) & (x < 424 + 69 ) & (y > 306) & (y < 311)) ? 1 : 0 ;
    assign t2[2] = ((x > 424 + 52 ) & (x < 424 + 57 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign t2[3] = ((x > 424 + 52 ) & (x < 424 + 57 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    assign t2[4] = ((x > 424 + 52 ) & (x < 424 + 69 ) & (y > 297) & (y < 301)) ? 1 : 0 ;
    
    assign t1[0] = ((x > 443 + 52 ) & (x < 508)       & (y > 287) & (y < 292)) ? 1 : 0 ;
    assign t1[1] = ((x > 443 + 64 ) & (x < 443 + 69 ) & (y > 291) & (y < 298)) ? 1 : 0 ;
    assign t1[2] = ((x > 443 + 64 ) & (x < 443 + 69 ) & (y > 300) & (y < 311)) ? 1 : 0 ;
    assign t1[3] = ((x > 443 + 52 ) & (x < 443 + 57 ) & (y > 297) & (y < 311)) ? 1 : 0 ;
    assign t1[4] = ((x > 443 + 52 ) & (x < 443 + 57 ) & (y > 287) & (y < 301)) ? 1 : 0 ;
    assign t1[5] = ((x > 443 + 52 ) & (x < 508)       & (y > 297) & (y < 301)) ? 1 : 0 ;
    
    assign c2[0] = ((x > 190) & (x < 207) & (y > 209) & (y < 225)) ? 1 : 0;
    assign c2[1] = ((x > 190) & (x < 207) & (y > 247) & (y < 264)) ? 1 : 0;
    
    assign c1[0] = ((x > 166 + 190) & (x < 166 + 207) & (y > 209) & (y < 225)) ? 1 : 0;
    assign c1[1] = ((x > 166 + 190) & (x < 166 + 207) & (y > 247) & (y < 264)) ? 1 : 0;
    


 // Assign the registers to the VGA 3rd output. This will display strong red on the Screen when 
 // grid = 1, and strong green on the screen when green = 1;
 assign VGA_R[3] = red;
 assign VGA_G[3] = green;
 assign VGA_B[3] = blue;
 
  
  always @ (*)
  begin 
	//At start of every input change reset the screen and grid. Check inputs and update grid accordingly
	
	//Green = 0 means that there will be no values of x/y on the VGA that will display green
    red = 0;
    green = 0;
    blue = 0;
    sumred = 0;
    sumwhite = 0;
    sumgreen = 0;
    
    case(random_num[3:0])
        4'b0000: sumred = sumred + ms1[0] + ms1[1] + ms1[2] + ms1[3] + ms1[4] + ms1[5];
        4'b0001: sumred = sumred + ms1[1] + ms1[2];
        4'b0010: sumred = sumred + ms1[0] + ms1[1] + ms1[3] + ms1[4] + ms1[6];
        4'b0011: sumred = sumred + ms1[0] + ms1[1] + ms1[2] + ms1[3] + ms1[6];
        4'b0100: sumred = sumred + ms1[1] + ms1[2] + ms1[5] + ms1[6];
        4'b0101: sumred = sumred + ms1[0] + ms1[2] + ms1[3] + ms1[5] + ms1[6];
        4'b0110: sumred = sumred + ms1[0] + ms1[2] + ms1[3] + ms1[4] + ms1[5] + ms1[6];
        4'b0111: sumred = sumred + ms1[0] + ms1[1] + ms1[2];
        4'b1000: sumred = sumred + ms1[0] + ms1[1] + ms1[2] + ms1[3] + ms1[4] + ms1[5] + ms1[6];
        4'b1001: sumred = sumred + ms1[0] + ms1[1] + ms1[2] + ms1[5] + ms1[6];
    endcase
    case(random_num[7:4])
        4'b0000: sumred = sumred + ms2[0] + ms2[1] + ms2[2] + ms2[3] + ms2[4] + ms2[5];
        4'b0001: sumred = sumred + ms2[1] + ms2[2];
        4'b0010: sumred = sumred + ms2[0] + ms2[1] + ms2[3] + ms2[4] + ms2[6];
        4'b0011: sumred = sumred + ms2[0] + ms2[1] + ms2[2] + ms2[3] + ms2[6];
        4'b0100: sumred = sumred + ms2[1] + ms2[2] + ms2[5] + ms2[6];
        4'b0101: sumred = sumred + ms2[0] + ms2[2] + ms2[3] + ms2[5] + ms2[6];
        4'b0110: sumred = sumred + ms2[0] + ms2[2] + ms2[3] + ms2[4] + ms2[5] + ms2[6];
        4'b0111: sumred = sumred + ms2[0] + ms2[1] + ms2[2];
        4'b1000: sumred = sumred + ms2[0] + ms2[1] + ms2[2] + ms2[3] + ms2[4] + ms2[5] + ms2[6];
        4'b1001: sumred = sumred + ms2[0] + ms2[1] + ms2[2] + ms2[5] + ms2[6];
    endcase
    case(random_num[11:8])
        4'b0000: sumred = sumred + ms3[0] + ms3[1] + ms3[2] + ms3[3] + ms3[4] + ms3[5];
        4'b0001: sumred = sumred + ms3[1] + ms3[2];
        4'b0010: sumred = sumred + ms3[0] + ms3[1] + ms3[3] + ms3[4] + ms3[6];
        4'b0011: sumred = sumred + ms3[0] + ms3[1] + ms3[2] + ms3[3] + ms3[6];
        4'b0100: sumred = sumred + ms3[1] + ms3[2] + ms3[5] + ms3[6];
        4'b0101: sumred = sumred + ms3[0] + ms3[2] + ms3[3] + ms3[5] + ms3[6];
        4'b0110: sumred = sumred + ms3[0] + ms3[2] + ms3[3] + ms3[4] + ms3[5] + ms3[6];
        4'b0111: sumred = sumred + ms3[0] + ms3[1] + ms3[2];
        4'b1000: sumred = sumred + ms3[0] + ms3[1] + ms3[2] + ms3[3] + ms3[4] + ms3[5] + ms3[6];
        4'b1001: sumred = sumred + ms3[0] + ms3[1] + ms3[2] + ms3[5] + ms3[6];
    endcase
    case(random_num[15:12])
        4'b0000: sumred = sumred + s1[0] + s1[1] + s1[2] + s1[3] + s1[4] + s1[5];
        4'b0001: sumred = sumred + s1[1] + s1[2];
        4'b0010: sumred = sumred + s1[0] + s1[1] + s1[3] + s1[4] + s1[6];
        4'b0011: sumred = sumred + s1[0] + s1[1] + s1[2] + s1[3] + s1[6];
        4'b0100: sumred = sumred + s1[1] + s1[2] + s1[5] + s1[6];
        4'b0101: sumred = sumred + s1[0] + s1[2] + s1[3] + s1[5] + s1[6];
        4'b0110: sumred = sumred + s1[0] + s1[2] + s1[3] + s1[4] + s1[5] + s1[6];
        4'b0111: sumred = sumred + s1[0] + s1[1] + s1[2];
        4'b1000: sumred = sumred + s1[0] + s1[1] + s1[2] + s1[3] + s1[4] + s1[5] + s1[6];
        4'b1001: sumred = sumred + s1[0] + s1[1] + s1[2] + s1[5] + s1[6];
    endcase
    case(random_num[19:16])
        4'b0000: sumred = sumred + s2[0] + s2[1] + s2[2] + s2[3] + s2[4] + s2[5];
        4'b0001: sumred = sumred + s2[1] + s2[2];
        4'b0010: sumred = sumred + s2[0] + s2[1] + s2[3] + s2[4] + s2[6];
        4'b0011: sumred = sumred + s2[0] + s2[1] + s2[2] + s2[3] + s2[6];
        4'b0100: sumred = sumred + s2[1] + s2[2] + s2[5] + s2[6];
        4'b0101: sumred = sumred + s2[0] + s2[2] + s2[3] + s2[5] + s2[6];
        4'b0110: sumred = sumred + s2[0] + s2[2] + s2[3] + s2[4] + s2[5] + s2[6];
    endcase
    case(random_num[23:20])
        4'b0000: sumred = sumred + m1[0] + m1[1] + m1[2] + m1[3] + m1[4] + m1[5];
        4'b0001: sumred = sumred + m1[1] + m1[2];
        4'b0010: sumred = sumred + m1[0] + m1[1] + m1[3] + m1[4] + m1[6];
        4'b0011: sumred = sumred + m1[0] + m1[1] + m1[2] + m1[3] + m1[6];
        4'b0100: sumred = sumred + m1[1] + m1[2] + m1[5] + m1[6];
        4'b0101: sumred = sumred + m1[0] + m1[2] + m1[3] + m1[5] + m1[6];
        4'b0110: sumred = sumred + m1[0] + m1[2] + m1[3] + m1[4] + m1[5] + m1[6];
        4'b0111: sumred = sumred + m1[0] + m1[1] + m1[2];
        4'b1000: sumred = sumred + m1[0] + m1[1] + m1[2] + m1[3] + m1[4] + m1[5] + m1[6];
        4'b1001: sumred = sumred + m1[0] + m1[1] + m1[2] + m1[5] + m1[6];
    endcase
    case(random_num[27:24])
        4'b0000: sumred = sumred + m2[0] + m2[1] + m2[2] + m2[3] + m2[4] + m2[5];
        4'b0001: sumred = sumred + m2[1] + m2[2];
        4'b0010: sumred = sumred + m2[0] + m2[1] + m2[3] + m2[4] + m2[6];
        4'b0011: sumred = sumred + m2[0] + m2[1] + m2[2] + m2[3] + m2[6];
        4'b0100: sumred = sumred + m2[1] + m2[2] + m2[5] + m2[6];
        4'b0101: sumred = sumred + m2[0] + m2[2] + m2[3] + m2[5] + m2[6];
        4'b0110: sumred = sumred + m2[0] + m2[2] + m2[3] + m2[4] + m2[5] + m2[6];
    endcase
    case(random_num[31:28])
        4'b0000: sumred = sumred + h1[0] + h1[1] + h1[2] + h1[3] + h1[4] + h1[5];
        4'b0001: sumred = sumred + h1[1] + h1[2];
        4'b0010: sumred = sumred + h1[0] + h1[1] + h1[3] + h1[4] + h1[6];
        4'b0011: sumred = sumred + h1[0] + h1[1] + h1[2] + h1[3] + h1[6];
        4'b0100: sumred = sumred + h1[1] + h1[2] + h1[5] + h1[6];
        4'b0101: sumred = sumred + h1[0] + h1[2] + h1[3] + h1[5] + h1[6];
        4'b0110: sumred = sumred + h1[0] + h1[2] + h1[3] + h1[4] + h1[5] + h1[6];
        4'b0111: sumred = sumred + h1[0] + h1[1] + h1[2];
        4'b1000: sumred = sumred + h1[0] + h1[1] + h1[2] + h1[3] + h1[4] + h1[5] + h1[6];
        4'b1001: sumred = sumred + h1[0] + h1[1] + h1[2] + h1[5] + h1[6];
    endcase
    case(random_num[35:32])
        4'b0000: sumred = sumred + h2[0] + h2[1] + h2[2] + h2[3] + h2[4] + h2[5];
        4'b0001: sumred = sumred + h2[1] + h2[2];
        4'b0010: sumred = sumred + h2[0] + h2[1] + h2[3] + h2[4] + h2[6];
        4'b0011: sumred = sumred + h2[0] + h2[1] + h2[2] + h2[3] + h2[6];
        4'b0100: sumred = sumred + h2[1] + h2[2] + h2[5] + h2[6];
        4'b0101: sumred = sumred + h2[0] + h2[2] + h2[3] + h2[5] + h2[6];
        4'b0110: sumred = sumred + h2[0] + h2[2] + h2[3] + h2[4] + h2[5] + h2[6];
        4'b0111: sumred = sumred + h2[0] + h2[1] + h2[2];
        4'b1000: sumred = sumred + h2[0] + h2[1] + h2[2] + h2[3] + h2[4] + h2[5] + h2[6];
        4'b1001: sumred = sumred + h2[0] + h2[1] + h2[2] + h2[5] + h2[6];
    endcase

    case(mode)
        2'b00: begin
            // if in 12hr mode
            if (clockfmt == 1) begin
                sumred = sumred + M[0] + M[1] + M[2] + M[3];

                if (am_pm == 0)
                    sumred = sumred + PA[0] + PA[1] + PA[2] + PA[4] + PA[5] + PA[6];
                else if (am_pm == 1)
                    sumred = sumred + PA[0] + PA[1] + PA[4] + PA[5] + PA[6];
            end 
        
            // display CLOCK
            sumred = sumred + clk5[0] + clk5[1] + clk5[2] + clk5[3];
            sumred = sumred + clk4[0] + clk4[1] + clk4[2];
            sumred = sumred + clk3[0] + clk3[1] + clk3[2] + clk3[3] + clk3[4] + clk3[5];
            sumred = sumred + clk2[0] + clk2[1] + clk2[2] + clk2[3];
            sumred = sumred + clk1[0] + clk1[1] + clk1[2] + clk1[3] + clk1[4];
        end
        2'b01: begin
            //display STOPWATCH
            sumred = sumred + sw9[0] + sw9[1] + sw9[2] + sw9[3] + sw9[4];
            sumred = sumred + sw8[0] + sw8[1];
            sumred = sumred + sw7[0] + sw7[1] + sw7[2] + sw7[3] + sw7[4] + sw7[5];
            sumred = sumred + sw6[0] + sw6[1] + sw6[2] + sw6[3] + sw6[4];
            sumred = sumred + sw5[0] + sw5[1] + sw5[2] + sw5[3] + sw5[4] + sw5[5];
            sumred = sumred + sw4[0] + sw4[1] + sw4[2] + sw4[3] + sw4[4] + sw4[5];
            sumred = sumred + sw3[0] + sw3[1];
            sumred = sumred + sw2[0] + sw2[1] + sw2[2] + sw2[3];
            sumred = sumred + sw1[0] + sw1[1] + sw1[2] + sw1[3] + sw1[4];
        end
        2'b10: begin
            //display TIMER
            sumred = sumred + t5[0] + t5[1];
            sumred = sumred + t4[0] + t4[1] + t4[2];
            sumred = sumred + t3[0] + t3[1] + t3[2] + t3[3] + t3[4] + t3[5];
            sumred = sumred + t2[0] + t2[1] + t2[2] + t2[3] + t2[4];
            sumred = sumred + t1[0] + t1[1] + t1[2] + t1[3] + t1[4] + t1[5];
        end
    endcase
    
    // Check if the timer is done
    if (timer_done) begin
        sumgreen = sumgreen + t5[0] + t5[1];
        sumgreen = sumgreen + t4[0] + t4[1] + t4[2];
        sumgreen = sumgreen + t3[0] + t3[1] + t3[2] + t3[3] + t3[4] + t3[5];
        sumgreen = sumgreen + t2[0] + t2[1] + t2[2] + t2[3] + t2[4];
        sumgreen = sumgreen + t1[0] + t1[1] + t1[2] + t1[3] + t1[4] + t1[5];
    end
    
    // if the mode is clock / timer and we are editing, indicate the editing digit
    if (editmode) begin
        if (mode == 2'b00) begin
            case (editDigit[1:0])
                2'b00: sumwhite = ((x > 52 ) & (x < 180) & (y > 268) & (y < 271)) ? 1 : 0; 
                2'b01: sumwhite = ((x > 218) & (x < 277) & (y > 268) & (y < 271)) ? 1 : 0; 
                2'b10: sumwhite = ((x > 287) & (x < 346) & (y > 268) & (y < 271)) ? 1 : 0; 
                default: sumwhite = 0;
            endcase
        end else if (mode == 2'b10) begin
            case (editDigit[2:0])
                3'b000: sumwhite = ((x > 52 ) & (x < 111) & (y > 268) & (y < 271)) ? 1 : 0; 
                3'b001: sumwhite = ((x > 121) & (x < 180) & (y > 268) & (y < 271)) ? 1 : 0; 
                3'b010: sumwhite = ((x > 218) & (x < 277) & (y > 268) & (y < 271)) ? 1 : 0;
                3'b011: sumwhite = ((x > 287) & (x < 346) & (y > 268) & (y < 271)) ? 1 : 0;
                3'b100: sumwhite = ((x > 384) & (x < 443) & (y > 268) & (y < 271)) ? 1 : 0;
                3'b101: sumwhite = ((x > 453) & (x < 512) & (y > 268) & (y < 271)) ? 1 : 0;
            endcase
        end
    end
    
    // always display the colons
    sumred = sumred + c2[1] + c2[0] + c1[1] + c1[0];
    
    if (sumred > 0) red = 1;
    if (sumgreen > 0) green = 1;
    if (sumwhite > 0) begin 
        green = 1;
        red = 1;
        blue = 1;
    end
  end
    
    
endmodule