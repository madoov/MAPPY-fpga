//=======================================================
// FPGA mappy address decoder module
/*
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
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/
//=======================================================//

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


module td_adec(
//input port
	input  wire PCLK,
	input  wire [15:0]A,
	input  wire [15:0]SA,
	input  wire ZWR,SWR,
//output port

	output  wire ROM,	   // 8000-ffff.r 

	output  wire RAM_2H,	// 0000-07ff.rw
	output  wire RAM_2J,	// 0800-0fff.rw
	output  wire RAM_2N,	// 1000-17ff.rw
	output  wire RAM_2L,	//	1800-1fff.rw
	output  wire RAM_2M,	//	2000-27ff.rw


	output  wire [7:0]TILE_SCRL,	// 3800-3fff.w [8bit]
	output  wire SHARED,  // 4000-43ff.rw sub:0000-03ff
	output  wire IO1,		// 4800-480f.rw
	output  wire IO2,		// 4810-481f.rw
	
	output  wire L_SIRQen, //5000 5001 (A0 is data)
	output  wire L_MIRQen, //5002 5003
	output  wire L_FLIP,   //5004 5005
	output  wire L_SNDon,  //5006 5007
	output  wire L_nRSTIO,  //5008 5009 <invert>
	output  wire L_nSUBRST, //500a 500b <invert>
	
	//sub
	output  wire S_SHARED,// 0000-03ff.rw sub
	output  wire S_ROM,	// e000-ffff.r
	output  wire WDT,	// 8000.w Watchdog timer reset
	input wire [3:0]game_kind

);

    assign ROM 		= ZWR & (A[15] == 1'b1) ;
    assign RAM_2H = game_kind[3] ? (A[15:10] == 6'b0000_00 ) : (A[15:11] == 5'b0000_0 );
    assign RAM_2J = game_kind[3] ? (A[15:10] == 6'b0000_01 ) : (A[15:11] == 5'b0000_1 );
    assign RAM_2N = game_kind[3] ? (A[15:11] == 5'b0000_1 )  : (A[15:11] == 5'b0001_0 );
    assign RAM_2L = game_kind[3] ? (A[15:11] == 5'b0001_0 )  : (A[15:11] == 5'b0001_1 );
    assign RAM_2M = game_kind[3] ? (A[15:11] == 5'b0001_1 )  : (A[15:11] == 5'b0010_0 );

reg [7:0] w_TILE_SCRL;

reg wL_SIRQen,wL_MIRQen,wL_FLIP,wL_nRSTIO,wL_nSUBRST;
reg wL_SNDon;

always @(posedge PCLK)
begin

 w_TILE_SCRL <= ( (A[15:11] == 5'b00111 ) )  ? A[10:3] : w_TILE_SCRL ;

 if (A[15:4] == 12'h500 ) 
	begin
	
	case (A[3:1])
	3'b000 : wL_SIRQen <= A[0];     
	3'b001 : wL_MIRQen <= A[0];  
	3'b010 : wL_FLIP   <= A[0];     
	3'b011 : wL_SNDon  <= A[0];     
	3'b100 : wL_nRSTIO <= A[0];
	3'b101 : wL_nSUBRST<= A[0]; 
	endcase
	
	end
	
	
 if (SA[15:13] == 3'b001)
	begin
	case (SA[3:1])
	3'b000 : wL_SIRQen <= SA[0];
	3'b101 : wL_nSUBRST<= SA[0]; 

	endcase
	end
	

end


assign TILE_SCRL = w_TILE_SCRL;
assign L_SIRQen  = wL_SIRQen;
assign L_MIRQen  = wL_MIRQen;
assign L_FLIP    = wL_FLIP;
assign L_SNDon   = wL_SNDon;
assign L_nRSTIO  = wL_nRSTIO;
assign L_nSUBRST = wL_nSUBRST;

assign SHARED = (A[15:10] == 6'b0100_00);

assign S_SHARED = (SA[15:10] == 6'b0000_00 );
assign S_ROM = (SA[15:13] == 3'b111) & SWR;

assign IO1 = (A[15:4]==12'h480) ;
assign IO2 = (A[15:4]==12'h481) ;

endmodule

