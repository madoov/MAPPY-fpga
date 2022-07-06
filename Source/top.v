/////////////////////////////////////////////////////////////////////////////
// FPGA mappy game module
/* Copyright (c) 2022, madov
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
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

//
/////////////////////////////////////////////////////////////////////////////
module mappy_top(

	output wire n_HSYNC,n_VSYNC,

//CPU interface
//ROM interface
	output wire [18:0]RA,SRA,
	input  wire [7:0]RD,SRD,
	
//Contyroll switches
	input  wire [3:0]PSW,

	input  wire CLK18M432,
	input  wire CLK36M864,
	input  wire CLK_50M,
	
	
	output  wire CLK_E,
	
	//output  wire DAC,
	
	output  wire [2:0]RED,GREEN,
	output  wire [1:0]BLUE,
	input  wire [7:0]JOYPORT,
	
	output  wire hblank,vblank,
	
	input  wire clk_6144,
	
	output  wire [7:0]c99out,

	output  wire [11:0]bg_addr,
	input  wire [7:0]bg_data,
	
	input  wire n_main_reset,
	input  wire n_sub_reset,
	
	
	output  wire [7:0] wromadr,
	input  wire [7:0] wromdat,
	
	output  wire [7:0]tileclut_addr,
	output  wire [10:0]spclut_addr, 
	input  wire [7:0]tileclut_out,	
	input  wire [7:0]spclut_out,
	
	
	output  wire [4:9]clut_addr,
	input  wire [7:0]clut_out,
	

	output wire [13:0]AB_gfx2,
	input  wire [7:0]gfx2aout,
	input  wire [7:0]gfx2bout,
    
    input wire [3:0]game_kind,
    
    input wire [15:0]dipsw,
    input wire svsw

	
	
);

wire [11:0]bg_addr_v2;
assign bg_addr = bg_addr_v2;

assign RED = red;
assign GREEN = green;
assign BLUE = blue;

wire CLK18_432M = CLK18M432;
wire CLK12_288M;
wire CLK6_144M;

// base & video pixel clock
wire pixel_clk = clk_6144;
wire ZINT,ZINT2; // vblank IRQ

wire [7:0]SDI,SDO,S2DI,S2DO;
wire [15:0]SA,S2A;
wire SRnW,S2RnW,S2BS,S2BA,SM6BS,SM6BA,SAVMA,SBUSY,SLIC;
wire MnRESET,S2RESET;
wire nsubrst;
wire M6BS,M6BA,MAVMA,MBUSY,MLIC;


wire [7:0] ZDO,ZDI;
//output
wire [15:0] ZA;
wire ZRnW;

mc6809 mc68e_sub(
    .D		(SDI),
	 .DOut	(SDO),
	 .ADDR	(SA),
	 .RnW		(SRnW),
	 .BS		(SM6BS),
	 .BA		(SM6BA),
	 .nIRQ	(ZINT2),
	 .nFIRQ	(1'b1),
    .nNMI	(1'b1),
	 .nHALT	(1'b1),
	 .MRDY   (1'b1),
	 .nRESET	(nsubrst),
	 .nDMABREQ (1'b1),
	 .EXTAL	(pixel_clk)  
);


mc6809 mc68e_main(

    .D		(ZDI),
	 .DOut	(ZDO),
	 .ADDR	(ZA),
	 .RnW		(ZRnW),
	 .BS		(M6BS),
	 .BA		(M6BA),
	 .nIRQ	(ZINT),
	 .nFIRQ	(1'b1),
    .nNMI	(1'b1),
	 .nHALT	(1'b1),
	 .nRESET	(MnRESET),
	 .MRDY	(1'b1),
	 .nDMABREQ (1'b1),
	 .EXTAL	(pixel_clk)
	 
	 
);


wire ZRW,SRW;
//assign  ZRnW = ~ZRW;

assign  ZRW = ~ZRnW;
assign  SRW = ~SRnW;


wire M_VMA;

wire io_nsubrst;

assign MnRESET = n_main_reset;
assign nsubrst = io_nsubrst & n_sub_reset;

wire ZMREQ,ZIORQ;//mad ZRD-> off
wire ZRFSH;
wire ZWO;
//input
wire Z80CLK;
//wire ZINT,
wire ZNMI,ZRESET,ZWAIT;

wire cs2h,cs2j,cs2n,cs2l,cs2m;
wire [7:0]tile_scrl;
wire r_shared;
wire io1,io2;
wire cs_spr_num_col,cs_spr_xy,cs_spr_mfs;
wire irqen2;
wire d_flip,sndon,nrstio,s_shared;
wire cssrom;
wire csrom;

wire irqen;

td_adec dru_adec(
	.PCLK			(pixel_clk),
	.A				(ZA),
	.SA			(SA),
	.ZWR			(ZRnW),
	.SWR			(SRnW),

	//output port
	.ROM		(csrom),	   // 8000-ffff.r 
	.RAM_2H		(cs2h),
	.RAM_2J		(cs2j),
	.RAM_2N		(cs2n),
	.RAM_2L		(cs2l),
	.RAM_2M		(cs2m),

	.TILE_SCRL	(tile_scrl),	
	.IO1		(io1),		
	.IO2		(io2),		
		
	.L_SIRQen	(irqen2),   
	.L_MIRQen	(irqen),    

	.L_FLIP		(d_flip),   
	.L_SNDon	(sndon),
	.L_nRSTIO	(nrstio),   

	.L_nSUBRST	(io_nsubrst),
	
	//sub
	.S_SHARED	(s_shared), 
	.SHARED		(r_shared), 
	
	.S_ROM		(cssrom),	
	
	.WDT		(),	// 8000.w Watchdog timer reset
    .game_kind  (game_kind)


);
		
wire [18:0] cpu_a,scpu_a;
reg [7:0] cpu_rd;
wire [7:0] rom_do = csrom ? RD : 8'h00;
wire [7:0] srom_do = cssrom ? SRD :8'h00;

assign cpu_a[15:0] = ZA;
assign cpu_a[18:16] = 3'b000;
assign scpu_a[15:0] = SA;

/////////////////////////////////////////////////////////////////////////////
// controller IN / DIP switch 
/////////////////////////////////////////////////////////////////////////////
wire [7:0] inp_do;

wire U1,D1,L1,R1,T1,S1,C1,T2;
assign {T2,U1,D1,L1,R1,T1,S1,C1} = JOYPORT;
wire [8:0] hcnt;
wire [8:0] vcnt;
wire hsync,vsync;
wire [7:0] vdo;
wire [2:0] red;
wire [2:0] green;
wire [1:0] blue;
reg [7:0] pd;   //pattern ROM data
wire [12:0] pa; //patterm ROM address

namco5856_inp_new inport (
	.AB		    (ZA[15:0]),
	.vsync	    (vsync),
	.hsync	    (hsync),
	.hcnt		(hcnt),
	.vcnt		(vcnt),
	.IO1		(io1),
	.IO2		(io2),
	.pxclk	    (pixel_clk),
	.LEFT		(L1),
	.RIGHT	    (R1),
	.UP		    (U1),	
	.DOWN		(D1),
	.TRIG		(T1),
    .TRIG2      (T2),
	.START	    (S1),
	.COIN		(C1),

	.outport	(inp_do),
	
	.inport     (ZDO),
	.ZRW		(ZRW),
    
    .game_kind ( game_kind ),
	.dipsw     ( dipsw ),
    .svsw      ( svsw )

	);


/////////////////////////////////////////////////////////////////////////////
// VIDEO hardware interface
/////////////////////////////////////////////////////////////////////////////


// video & work RAM I/F

wire [15:0] AB;
wire [7:0] DB_I,SDBI;
wire tile_we , col_we , wram_we;
wire lram_cs;

wire [9:0] clut_a;
wire [3:0] clut_d;
wire [3:0] pal_a;

wire flip;
wire vcs2h,vcs2j,vcs2n,vcs2l,vcs2m;

wire [10:0] ABTILE;
wire [7:0] TILE_RAM_out,TILE_PAL_out;

wire [8:0] hcnt_raw;


wire [15:0]ab_obj1,ab_obj2,ab_obj3;
wire [7:0]obj1_in,obj2_in,obj3_in;


mappy_video video_module(


	.AB_tile (ABTILE),
	.tile_ram_out (TILE_RAM_out),
	.tile_pal_out (TILE_PAL_out),
	
	.tile_scroll (tile_scrl),


	.pclk(pixel_clk),
	.flip(flip),
	.vb(vblank),
	.hb(hblank),
	.hc(hcnt),
	.vc(vcnt),
	.hs(hsync),
	.vs(vsync),
	
	.r		(red) ,
	.g		(green) ,
	.b		(blue) ,
	
	//.clk_12m (CLK12_288M),
	.clk_18432 (CLK18M432), 
    .clk_36864 (CLK36M864),

	
	
	.hcount_raw (hcnt_raw),
	
	
	.AB_obj1	(ab_obj1),
	.AB_obj2 (ab_obj2),
	.AB_obj3 (ab_obj3),
	.obj1in	(obj1_in),
	.obj2in	(obj2_in),
	.obj3in	(obj3_in),
	
	
	.bg_addr	(bg_addr_v2),
	.bg_data	(bg_data),
	
	.tileclut_out ( tileclut_out ),
	.spclut_out ( spclut_out ),
	.tileclut_addr ( tileclut_addr ),
	.spclut_addr ( spclut_addr ),
	
	.n_main_reset (n_main_reset),
	.n_sub_reset (n_sub_reset),
	
	.clut_addr (clut_addr),
	.clut_out (clut_out),
	
	
	
	.AB_gfx2 (AB_gfx2),
	.gfx2aout (gfx2aout),
	.gfx2bout (gfx2bout),
    
    .game_kind (game_kind)

	

);



wire pb,cluts,chbank,wr0,wr1;

/////////////////////////////////////////////////////////////////////////////
// IRQ & IRQ vector
/////////////////////////////////////////////////////////////////////////////
dru_irq dru_irqvector(
	.IRQEN	(irqen)	,
	.IRQEN2	(irqen2)	,
	.IRQTRG	(vblank)	,
	.n_IRQ	(ZINT)	,
	.n_IRQ2	(ZINT2)	
		
);


/////////////////////////////////////////////////////////////////////////////
// sound
/////////////////////////////////////////////////////////////////////////////
WSG_c1599 sound (
		.RESET	(),
		.pxclk	(pixel_clk),
		.SA		(SA),
		.SDATA	(SDO),
		.c99raw_out (c99out),
		
		.WROMADR ( wromadr ),
		.WROMDAT	( wromdat )
);
/////////////////////////////////////////////////////////////////////////////
// memory 
/////////////////////////////////////////////////////////////////////////////
wire [7:0] pal_d;
wire [7:0] zo,szo;

Mappy_ram mappyram(
	.memCLK		(CLK18_432M),
    .clk18432  (CLK18_432M),
    .clk36864  (CLK36M864),
	 .AB(AB),.ZA(ZA),.DB_I(ZDO),
    .ZO(zo),
    .SZO(szo),
  
    .SAB(SA),.SDB_I(SDO),.SDB_O(SDBI),.SRW(SRW),
    .TILE_CS(cs2h), .TILE_WE(tile_we),
    .COL_CS(cs2j),  .COL_WE(col_we),
    .CS_SHARED (r_shared),
    .CS_SUB_SHARED (s_shared),
	.CS_2L	(cs2l),
	.CS_2M	(cs2m),
	.CS_2N	(cs2n),
	.WE_2L	(~ZRnW),
	.WE_2M	(~ZRnW),
	.WE_2N	(~ZRnW),
	
	.AB_TILE (ABTILE),
	.tile_ram_out (TILE_RAM_out),
	.tile_pal_out (TILE_PAL_out),
  
  .ZRW (ZRW) ,


   .AB_obj1	(ab_obj1),
	.AB_obj2 (ab_obj2),
	.AB_obj3 (ab_obj3),
	.obj1out (obj1_in),
	.obj2out	(obj2_in),
	.obj3out	(obj3_in),
    
    .game_kind (game_kind)
  
  
);

reg [18:0] rom_a;

assign RA = cpu_a;

assign SRA = scpu_a;

assign ZDI = rom_do | zo | inp_do;

assign SDI = srom_do | szo ;

wire hs_out , vs_out;
wire hs_tri , vs_tri;
wire [4:0] r_tri,g_tri,b_tri;

assign n_HSYNC = ~hsync;
assign n_VSYNC = ~vsync;


endmodule

