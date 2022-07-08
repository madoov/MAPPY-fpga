//=======================================================
/* FPGA mappy top level module
Copyright (c) 2022, madov
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.// Copyright (C) 2022 by madov(@maddoka)
*/

//=======================================================
`ifdef QUARTUS

`default_nettype none
`endif
                                                                                                                                                                                                                  
module NANO_DRUAGA(

	//////////// CLOCK //////////
	input 		wire      		FPGA_CLK1_50,

`ifdef QUARTUS
	input 		wire       		FPGA_CLK2_50,
`endif


`ifdef TRION
    input wire clk_18432,
    input wire clk_6144,
    input wire clk_36864,
    


`endif

    input wire [3:0]dip,
	output wire [2:0]red,green,
	output wire [1:0]blue,
	output wire csync,
	input  wire  coin,start,up,down,left,right,t1,t2,
	output wire DD1,DD2,DD3,DD4,
	input wire [1:0]KEY,

`ifdef QUARTUS	
	output wire sx,sclk,rclk,sx4,
`endif
	input wire [7:0]rom_d,

`ifdef QUARTUS
	output wire [15:0]rom_a,
    output wire nrom_oe,
    output wire nrom_oe2,
`endif

`ifdef TRION
	output wire [18:0]rom_a,
    input wire gamesw,
    output wire o_nrom_oe,
    output wire sclk,
    output wire shld,
    output wire nrom_oe2,
    output wire debug1,debug2,debug3,debug4,
`endif
	output wire [7:0]c99_out
	
);

`ifdef TRION
wire [15:0]dipsw_port;
assign nrom_oe2 = 1'b0;
assign sclk = clk_6144;
reg [4:0]dsw_counter;
reg [15:0]dipsw;
reg shld_reg;
assign  shld = shld_reg;

always @(posedge clk_6144)
begin
    dsw_counter = dsw_counter + 1;
    shld_reg = dsw_counter[4];
end
always @(negedge clk_6144)
begin
    if (dsw_counter[4]==1) begin
        dipsw[ dsw_counter[3:0] ] = ~gamesw;
        end
end

assign debug1 = svsw;//dipsw_port[0];
assign debug2 = 0;
assign debug3 = 0;
assign debug4 = 0;
 
assign dipsw_port = { dipsw[8],dipsw[9],dipsw[10],dipsw[11],dipsw[12],dipsw[13],dipsw[14],dipsw[15],
                      dipsw[0],dipsw[1],dipsw[2],dipsw[3],dipsw[4],dipsw[5],dipsw[6],dipsw[7] };
    
`endif

//DIPSW　仕様
//swa  12345678
//dipsw[7:0]
//swb 12345678
//dipsw[15:8]

// 58xx + 58xx 4bitsp  mappy    == 0000
// 58xx + 56xx 4bitsp  td,dig2  == 0001
// 56xx + 56xx 4bitsp  mo       == 0011

// 58xx + 56xx 2bitsp  grobda   == 1001
// 56xx + 59xx 2bitsp  pacnpal  == 1110
// 56xx + 56xx 2bitsp  spacman  == 1011

// [3] ... 4bit or 2bit
// [1:0] .. 58?56?
// [2] .. 59

//=======================================================
//  REG/WIRE declarations
//=======================================================

`ifdef QUARTUS

assign sclk = clk_6144;
assign sx4 = 0;
reg [3:0]shc;
always @(posedge clk_6144)
	shc <= shc + 1;
	
reg [15:0]sx_out;
initial sx_out[9:0] = { 9'b0,1'b1 };

assign sx =  sx_out[~shc[3:0]];
assign rclk = (shc[3:0]==4'b0000);
wire clk_18432;
wire clk_36864;

`endif

wire U1 = ~up;
wire R1 = ~right;
wire D1 = ~down;
wire L1 = ~left;
wire T1 = ~t1;
wire S1 = ~start;
wire C1 = ~coin;
wire T2 = ~t2;

wire [7:0] JOY = {T2,U1,D1,L1,R1,T1,S1,C1};
wire p3x;
wire [15:0]rom_ra,srom_ra;
wire [7:0]rom_rd,srom_rd;
wire rom_rcs,rom_roe,rom_rwe;
wire clk_z80;
wire [11:0]bg_addr;
wire [7:0]bg_data;
wire [4:0] vr,vg,vb;
wire [9:0] pcm_out;
wire pxc;
//wire dac_out;
//assign DD1 = dac_out;
assign DD2 = 0;
assign DD3 = 0;
assign DD4 = 0;

reg romtrans_done;
initial romtrans_done = 0;
wire [7:0]WROMADR,WROMDAT;
wire [13:0]AB_gfx2;
wire [7:0]gfx2aout;
wire [7:0]gfx2bout;
wire HS,VS;
assign csync = HS & VS;

wire [7:0]tileclut_addr;
wire [10:0]spclut_addr;
wire [7:0]tileclut_out,spclut_out;
wire [4:0]clut_addr;
wire [7:0]clut_out;

    
wire n_main_reset;
wire n_sub_reset;

assign n_main_reset = romtrans_done ;//& ~KEY[0] ; 
assign n_sub_reset = romtrans_done ;//& ~KEY[0] ;

//assign dsdac = dac_out;
reg [9:0] a;	

//=======================================================
//  Structural coding
//=======================================================

`ifdef TRION
wire [3:0]game_kind = ~dip;
`endif
`ifdef QUARTUS
wire[3:0]game_kind =  4'b0100;
`endif


//service switch for mappy 
reg [16:0] count6m;
reg key_a,key_b;

always @(posedge clk_6144)
begin
    count6m <= count6m + 1;
    if (count6m == 17'b0) begin
        if ( ( key_a != KEY[0] ) && ( KEY[0]==0) )begin
                            key_b = ~key_b ;
                               end
    end
    if (count6m == 17'b1) begin
                key_a = KEY[0];
    end
end
wire svsw;
assign svsw = key_b;


mappy_top mappy (
	.n_HSYNC	(HS)	,
	.n_VSYNC	(VS)	,
	
	.RA		(rom_ra)	,
	.RD		(rom_rd)	,
	.SRA		(srom_ra),
	.SRD		(srom_rd),
	
	.PSW		(~KEY) ,
	
	.CLK18M432	(clk_18432),
	.CLK_50M	(FPGA_CLK1_50),
	.CLK36M864	(clk_36864),
	.RED		(red),
	.GREEN	    (green),
	.BLUE		(blue),
	//.DAC		(dac_out),
	.JOYPORT    (JOY),
	.clk_6144   (~clk_6144),
	.c99out	    (c99_out),
	
	.bg_addr	(bg_addr),
	.bg_data	(bg_data),


	.n_main_reset (n_main_reset),
	.n_sub_reset (n_sub_reset),
	
	.wromadr ( WROMADR ),
	.wromdat ( WROMDAT ),

	.tileclut_addr	( tileclut_addr ),
	.spclut_addr	( spclut_addr ),
	.tileclut_out	( tileclut_out ),
	.spclut_out		( spclut_out ),
	
	.clut_addr	(clut_addr),
	.clut_out	(clut_out),
	
	.AB_gfx2	(AB_gfx2),
	.gfx2aout (gfx2aout),
	.gfx2bout (gfx2bout),
    
    .game_kind ( game_kind ),
    .dipsw     (dipsw_port),
    .svsw      ( svsw )

	);
`ifdef QUARTUS
assign rom_a = romtrans_done ? rom_ra[14:0] : dl_addr ;
assign rom_rd = rom_d;
assign nrom_oe = 0;

//wire [15:0]dl_addr;
wire dl_we = ~romtrans_done;
wire [7:0]dl_data = rom_d;
//a000-afff bg
//8000-9fff cpu2
//0000-7fff cpu1

reg [15:0]dl_addr;
wire cs_bg = 		(dl_addr[15:12]==4'ha);
wire cs_cpu2 = 	(dl_addr[15:13]==3'b100);
wire cs_palrom1 = (dl_addr[15: 8]==8'hb4 );
wire cs_palrom3 = (dl_addr[15:10]==6'b1011_00 );

wire cs_clut	=	(dl_addr[15: 5]==11'b1011_0110_000);
wire cs_wavrom	 =  (dl_addr[15: 8]== 8'b1011_0101);

initial dl_addr = 16'h0000;
always @(posedge clk_6144)
begin

 if (romtrans_done == 0)	
	begin
		dl_addr = dl_addr + 1;
	
		if ( dl_addr == 16'hffff )
			romtrans_done = 1;
	
	end
	
	

end
`endif

/*
rom1
00000-07FFF   cpu0      td2_3.1d,td2_1.1b  gr2-3.1d,gr2-2.1c,gr2-1.1b 
08000-09FFF   cpu1      td1_4.1k gr1-4.1k
0A000-0AFFF   bg        td1_5.3b gr1-7.3c
0B000-0B3FF   spclut	td1-7.5k gr1-4.3l
0B400-0B4FF   bgclut	td1-6.4c gr1-5.4e
0B500-0B5FF   wave		td1-3.3m gr1-3.3m
0B600-0B61F   palet		td1-5.5b gr1-6.4c

rom2
00000-07FFF   spchip0/1 td1_6.3m,td1_7.3n  gr1-5.3f,gr1-6.3e

//rom1 cpu0については、8000-ffffの場合は0000-7fff,c000-ffffの場合は4000-7fff
//rom1 cpu1については、e000-ffffの場合は8000-9fff,f000-ffffの場合は9000-9fff 

//rom2 各ロムは　0-3fff,4000-7fffとする
//rom容量の小さいものも同様。

*/

`ifdef TRION

reg [18:0]dl_addr;
wire cs_bg =        (dl_addr[16:12]==5'h0_a);        //0a000-0afff
wire cs_cpu2 = 	    (dl_addr[16:13]== 4'b0_100);     //08000-09fff
wire cs_palrom1 =   (dl_addr[16: 8]== 9'h0_b4 );     //0b400-0b4ff
wire cs_palrom3 =   (dl_addr[16:10]== 7'b0_1011_00 );//0b000-0b3ff
wire cs_sprrom1 =   (dl_addr[16:14]== 3'b1_00);      //10000-13fff
wire cs_sprrom2 =   (dl_addr[16:14]== 3'b1_01);      //14000-17fff
wire cs_clut	 =	(dl_addr[16: 5]==12'b0_1011_0110_000); //0b600-0b61f
wire cs_wavrom	 =  (dl_addr[16: 8]== 9'b0_1011_0101);  //0b500-0b5ff

assign rom_a = romtrans_done ? {4'b0,rom_ra[14:0]} : dl_addr[18:0] ;
assign rom_rd = rom_d;
assign o_nrom_oe = 1'b0;

wire dl_we = ~romtrans_done;
wire [7:0]dl_data = rom_d;

initial dl_addr = 17'h00000;
always @(posedge clk_6144)
begin

 if (romtrans_done == 0)	
	begin
		dl_addr = dl_addr + 1;
	
		if ( dl_addr == 17'h1ffff )
			begin
                romtrans_done = 1;
                dl_addr = 17'h00000;
            end
            
	end
	
	

end
`endif

true_dual_port_ram #( 8, 12 )
gfxrom1
(
		.addr1 ( bg_addr ),
		.we1 ( 0 ),
		.din1 ( 0 ),
		.dout1 ( bg_data ),
		.clka ( clk_18432 ),
		
		.addr2 ( dl_addr[11:0] ),
		.we2 ( cs_bg & dl_we ),
		.din2 ( dl_data ),
		.dout2 (),
		.clkb ( clk_6144 )
		
		
		
);	
	
true_dual_port_ram #( 8, 13 )
subcpurom
(
		.addr1 ( srom_ra ),
		.we1 ( 0 ),
		.din1 ( 0 ),
		.dout1 ( srom_rd ),
		.clka ( clk_18432 ),
		
		.addr2 ( dl_addr[12:0] ),
		.we2 ( cs_cpu2 & dl_we ),
		.din2 ( dl_data ),
		.dout2 (),
		.clkb ( clk_6144 )
		
);	

true_dual_port_ram #( 8, 8 )
palrom1
(
		.addr1 ( tileclut_addr ),
		.we1 ( 0 ),
		.din1 ( 0 ),
		.dout1 ( tileclut_out ),
		.clka ( clk_18432 ),
		
		.addr2 ( dl_addr[7:0] ),
		.we2 ( cs_palrom1 & dl_we ),
		.din2 ( dl_data ),
		.dout2 (),
		.clkb ( clk_6144 )
);	

true_dual_port_ram #( 8, 10 )
palrom3
(
		.addr1 ( spclut_addr ),
		.we1 ( 0 ),
		.din1 ( 0 ),
		.dout1 ( spclut_out ),
		.clka ( clk_18432 ),
		
		.addr2 ( dl_addr[9:0] ),
		.we2 (  cs_palrom3 & dl_we ),
		.din2 ( dl_data ),
		.dout2 (),
		.clkb ( clk_6144 )
		
);

true_dual_port_ram #( 8, 5 )
clutrom
(
		.addr1 ( clut_addr ),
		.we1 ( 0 ),
		.din1 ( 0 ),
		.dout1 ( clut_out ),
		.clka ( clk_18432 ),
		
		.addr2 ( dl_addr[4:0] ),
		.we2 (  cs_clut & dl_we ),
		.din2 ( dl_data ),
		.dout2 (),
		.clkb ( clk_6144 )
		
);

`ifdef QUARTUS

gfxrom2a gfx2a
	( .clock (clk_18432), .address_a ( gamekind[2] ? {1'b0, AB_gfx2[12:0] : AB_gfx2[13:0] }  ), .data_a(), .wren_a(1'b0), .q_a(gfx2aout) );//,
								
gfxrom2b gfx2b
	( .clock (clk_18432), .address_a ( gamekind[2] ? {1'b0, AB_gfx2[12:0] : AB_gfx2[13:0] }  ), .data_a(), .wren_a(1'b0), .q_a(gfx2bout) );//,
	
`endif
	
 
    
`ifdef TRION


true_dual_port_ram #( 8, 14 )
gfxrom2a
(
    //mp,gr 
//	  	.addr1 ( gamekind[2] ? {1'b0, AB_gfx2[12:0] } : AB_gfx2[13:0] ),
	  	.addr1 ( game_kind[3] ? {1'b0, AB_gfx2[12:0] } : AB_gfx2[13:0] ),

   		.we1 ( 0 ),
		.din1 ( 0 ),
		.dout1 ( gfx2aout ),
		//.clka ( clk_18432 ),
		.clka   ( clk_36864 ),
        
		.addr2 ( dl_addr[13:0] ),
		.we2 (  cs_sprrom1 & dl_we ),
		.din2 ( dl_data ),
		.dout2 (),
		.clkb ( clk_6144 )
		
);

true_dual_port_ram #( 8, 14 )
gfxrom2b
(
    //mp,gr
//	  	.addr1 ( gamekind[2] ? {1'b0,AB_gfx2[12:0] } : AB_gfx2[13:0] ),
	  	.addr1 ( game_kind[3] ? {1'b0,AB_gfx2[12:0] } : AB_gfx2[13:0] ),

		.we1 ( 0 ),
		.din1 ( 0 ),
		.dout1 ( gfx2bout ),
        //.clka ( clk_18432 ),
		.clka ( clk_36864 ),
		
		.addr2 ( dl_addr[13:0] ),
		.we2 (  cs_sprrom2 & dl_we ),
		.din2 ( dl_data ),
		.dout2 (),
		.clkb ( clk_6144 )
		
);

`endif



true_dual_port_ram #( 4, 8 )
sndrom
(
		.addr1 ( WROMADR ),
		.we1 ( 0 ),
		.din1 ( 0 ),
		.dout1 ( WROMDAT ),
		.clka ( ~clk_6144 ),
		
		.addr2 ( dl_addr[7:0] ),
		.we2 ( cs_wavrom & dl_we ),
		.din2 ( dl_data ),
		.dout2 (),
		.clkb ( clk_6144 )
		
);


//snd_rom sndrom (
//	.address		(WROMADR),
//	.clock		(~clk_6144),
//	.q				(WROMDAT)
//	);
	

`ifdef QUARTUS
		
pll0 pll_pacman (
		.inclk0	(FPGA_CLK1_50)	,
		.c0		(clk_18432),	
		.c1		(clk_6144),
		.c2		(clk_36864)
		);

`endif

		

	
endmodule





module DPRAM (
    input wire [7:0]data,
    output wire [7:0]q,
    input wire [10:0]address,
    input wire wren,
    input wire rden,
    input wire clock 
    );
    
    
simple_dual_port_ram #( .DATA_WIDTH(8), .ADDR_WIDTH(10) , .OUTPUT_REG ("FALSE") )
 dprm (
    .wdata  (data),
    .waddr  (address),
    .raddr  (address),
    .we (wren),
    .re (rden),
    .wclk (clock),
    .rclk (clock),
    .rdata (q)
    );
    

endmodule

