//=======================================================
// FPGA mappy memory module
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

//=======================================================

/*
00000xxxxxxxxxxx R/W xxxxxxxx RAM 2H    tilemap RAM (tile number)
00001xxxxxxxxxxx R/W xxxxxxxx RAM 2J    tilemap RAM (tile color)
00010xxxxxxxxxxx R/W xxxxxxxx RAM 2N    work RAM
000101111xxxxxxx R/W xxxxxxxx           portion holding sprite registers (sprite number & color)
00011xxxxxxxxxxx R/W xxxxxxxx RAM 2L    work RAM
000111111xxxxxxx R/W xxxxxxxx           portion holding sprite registers (x, y)
00100xxxxxxxxxxx R/W xxxxxxxx RAM 2M    work RAM
001001111xxxxxxx R/W xxxxxxxx           portion holding sprite registers (x msb, flip, size)
00111xxxxxxxx---   W -------- POSIV     tilemap scroll (data is in A3-A10)
01000-xxxxxxxxxx R/W xxxxxxxx SOUND     RAM (shared with sound CPU)
01000-0000xxxxxx R/W xxxxxxxx           portion holding the sound registers
*/



module Mappy_ram(
//
    input wire memCLK,clk18432,
    input wire clk36864,
// Shared Address & Data(Out) Bus

    input wire [15:0]AB,
    input wire [7:0]DB_I,
  
// sub_cpu buses
    input wire [15:0]SAB,
    input wire [7:0]SDB_I,
    output wire [7:0]SDB_O,
    input wire SRW,
      
  
    input wire TILE_CS,TILE_WE, COL_CS,COL_WE, 

//  WORK_CS,WORK_WE, cpu side
	input wire CS_2L,	WE_2L,
	input wire CS_2M,	WE_2M,
	input wire CS_2N,	WE_2N,

// Sound shared RAM
    input wire CS_SHARED,
	input wire CS_SUB_SHARED,
	
	
  
    input wire [15:0]ZA,
    output wire [7:0]ZO,SZO,
  
	//for debug,  only ZA-ZO imprementation
    input wire [10:0]AB_TILE,	
    output wire [7:0]tile_ram_out,tile_pal_out,
  
    input wire ZRW,
  
    input wire [10:0]AB_obj1 ,	AB_obj2 ,  	AB_obj3 , 
	output wire [7:0]obj1out ,	obj2out ,	obj3out ,
    input wire [3:0] game_kind

   
  
  );


/////////////////////////////////////////////////////////////////////////////
// Video RAM
/////////////////////////////////////////////////////////////////////////////

wire [7:0] wram_do2;
wire [7:0] ram_2l_zo2, ram_2m_zo2, ram_2n_zo2;

wire [7:0] tile_zo2;
wire [7:0] col_zo2;
wire [7:0] wram_zo2;

wire [7:0] tile_zo = (TILE_CS)? tile_zo2:8'h00;
wire [7:0] col_zo  = (COL_CS)?  col_zo2 :8'h00;
wire [7:0] ram_2l_zo = (CS_2L)? ram_2l_zo2 : 8'h00;
wire [7:0] ram_2m_zo = (CS_2M)? ram_2m_zo2 : 8'h00;
wire [7:0] ram_2n_zo = (CS_2N)? ram_2n_zo2 : 8'h00;

wire [7:0] ram_sh_zo2;
wire [7:0] ram_sh_zo = (CS_SHARED) ? ram_sh_zo2 : 8'h00;


//cpu side
assign ZO    = tile_zo | col_zo | ram_2l_zo | ram_2m_zo | ram_2n_zo | ram_sh_zo;
assign SZO = (CS_SUB_SHARED) ? SDB_O[7:0] : 8'h00;

true_dual_port_ram #( .DATA_WIDTH(8), .ADDR_WIDTH(11) )
 tile_obj_dprm (
    .addr1 (game_kind[3] ? {1'b0,ZA[9:0]} : ZA[10:0] ),//gr
	 .din1(DB_I[7:0]),
	 .dout1(tile_zo2[7:0]),
	 .we1 (TILE_CS & ZRW),
	 .clka (memCLK),

    .addr2 (AB_TILE[10:0]),
	 .din2(0),
	 .dout2(tile_ram_out[7:0]),
	 .we2 (0),
	 .clkb (clk18432)

	 
    );

true_dual_port_ram #( .DATA_WIDTH(8), .ADDR_WIDTH(11) )
 tile_color_dprm (
    .addr1 (game_kind[3] ? {1'b0,ZA[9:0]} : ZA[10:0] ),//gr
	 .din1(DB_I[7:0]),
	 .dout1(col_zo2[7:0]),
	 .we1 (COL_CS & ZRW),
	 .clka (memCLK),

    .addr2 (AB_TILE[10:0]),
	 .din2(0),
	 .dout2(tile_pal_out[7:0]),
	 .we2 (0),
	 .clkb (clk18432)

	 
    );
	
true_dual_port_ram #( 8,11 )
	work_ram_2n ( 
	 .addr1 (ZA[10:0]),
	 .din1(DB_I[7:0]),
	 .dout1(ram_2n_zo2[7:0]),
	 .we1 (WE_2N & CS_2N),
	 .clka (memCLK),

    .addr2 (AB_obj1[10:0]),
	 .din2(0),
	 .dout2(obj1out[7:0]),
	 .we2 (0),
	 .clkb (clk36864) //clk18432)
);

true_dual_port_ram #( 8,11 )
	work_ram_2l ( 
	 .addr1 (ZA[10:0]),
	 .din1(DB_I[7:0]),
	 .dout1(ram_2l_zo2[7:0]),
	 .we1 (WE_2L & CS_2L),
	 .clka (memCLK),

    .addr2 (AB_obj2[10:0]),
	 .din2(0),
	 .dout2(obj2out[7:0]),
	 .we2 (0),
	 .clkb (clk36864)//clk18432)
);
true_dual_port_ram #( 8,11 )
	work_ram_2m ( 
	 .addr1 (ZA[10:0]),
	 .din1(DB_I[7:0]),
	 .dout1(ram_2m_zo2[7:0]),
	 .we1 (WE_2M & CS_2M),
	 .clka (memCLK),

    .addr2 (AB_obj3[10:0]),
	 .din2(0),
	 .dout2(obj3out[7:0]),
	 .we2 (0),
	 .clkb (clk36864)//18432)
);


// SHARED RAM
									
									
true_dual_port_ram #( 8,10 )
	share_ram ( 
	 .addr1 (ZA[9:0]),
	 .din1(DB_I[7:0]),
	 .dout1(ram_sh_zo2[7:0]),
	 .we1 (CS_SHARED & ZRW),
	 .clka (memCLK),

    .addr2 (SAB[9:0]),
	 .din2(SDB_I[7:0]),
	 .dout2(SDB_O[7:0]),
	 .we2 (CS_SUB_SHARED & SRW),
	 .clkb (memCLK)
);
									
									



endmodule
