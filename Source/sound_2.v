//=======================================================
/* FPGA mappy WSG module
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


module WSG_c1599
(
    input wire  RESET,      
	input wire  pxclk,
    input wire [15:0] SA,
    input wire [7:0] SDATA,
	output wire [7:0]c99raw_out,
	output wire [7:0]WROMADR,
	input wire [7:0]WROMDAT
);

reg [19:0] F [0:7];
reg [2:0]  W [0:7];
reg [3:0]  V [0:7];

//for grobda voice
reg [3:0]  Vo;

wire WR = (SA[15:6] == 10'h000);

//wave counter
reg [20:0] c [0:7];

//wave prom addr.
reg  [7:0] waveadr;
assign WROMADR = waveadr;

reg  [3:0]wavevol;
wire [7:0]c99out = { wavevol,WROMDAT[3:0] };

reg  [7:0]c99out_ch;
reg  [6:0]phase_pxclk;

//cus99 out 
assign c99raw_out = voin ? {4'b1111, Vo } : c99out_ch; 


//accurate data
// pxclk 6.144MHz
// smpl_clk -> 384KHz
// phase 8 phase

reg voin;

wire [2:0] channel = SA[5:3];

always @ ( posedge pxclk or posedge RESET ) begin

   if ( RESET ) begin

      {W[0],W[1],W[2],W[3],W[4],W[5],W[6],W[7]} <= 24'b0;
      {F[0],F[1],F[2],F[3],F[4],F[5],F[6],F[7]} <= 160'b0;
      {V[0],V[1],V[2],V[3],V[4],V[5],V[6],V[7]} <= 32'b0;

   end
   else begin
    
      if ( WR ) 
      
      begin
      
     case (SA[2:0])
    //channel = SA[5:3];
        3'b011: V[channel] <= SDATA[3:0];
        3'b100: F[channel][7:0] <= SDATA; 
        3'b101: F[channel][15:8] <= SDATA;
        3'b110:
            begin
                voin <= 1'b0;
                W[channel]        <= SDATA[6:4];
                F[channel][19:16] <= SDATA[3:0];
            end
        //grobda
        3'b010:
            begin 
                voin = 1'b1;
                Vo <= SDATA[3:0];
             end
 
        default : ;
        
        endcase
    end
   end
end


//pxclk = 6.144MHz
//new phase
//96KHz
//= 6.144MHz / 64
//6.144MHz / 16 = 384 khz
//384 / 8 = 48 khz

//phase 7bit

//freq= 20bit
//20bit+ 20bit => 21bit


wire [2:0] phase_channel = phase_pxclk[6:4];

always @(posedge pxclk or posedge RESET )
begin


   if ( RESET ) begin
      phase_pxclk  <= 0;
      {c[0],c[1],c[2],c[3],c[4],c[5],c[6],c[7]}  <= 168'b0;
   end
   else begin
		phase_pxclk <= phase_pxclk + 1;
     //Freq : 20bits

        //clock phase 7f
     if (phase_pxclk[6:0]==7'h7f)
		begin
			c[0] <=    c[0] + F[0];
			c[1] <=    c[1] + F[1];
			c[2] <=    c[2] + F[2];
			c[3] <=    c[3] + F[3];
			c[4] <=    c[4] + F[4];
			c[5] <=    c[5] + F[5];
			c[6] <=    c[6] + F[6];
			c[7] <=    c[7] + F[7];
		end
	
     // clock phase 00,10,20....70   
     // waveadr,wavevol set
      if ( phase_pxclk[3:0] == 4'b0 )
        begin
            waveadr <= { W[phase_channel],c[phase_channel][20:16] };
            wavevol <= V[phase_channel];
        end
        
     // clock phase 08,18,28....78
     // dac output 
      if ( phase_pxclk[3:0] == 4'b1000 )
        begin
            c99out_ch <= c99out;
        end
   end

end

endmodule
