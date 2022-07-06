//=======================================================
// FPGA mappy sprite sub module
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

module spr_adder
(
		input  wire match,
		output  wire n_spr_in_progress ,
		input  wire xsize,
		input  wire xflip,
		input  wire pclk,
		output  wire [4:0]adder

);

reg [5:0]counter;
reg [5:0]xcount;
reg progress;
reg zeroflag;

always @(posedge pclk)

begin

	// match = 1 -> progress = 1
	// 処理終了までprogressいじらず
	if ( counter == xcount )
						begin progress = 0;
                              counter = 0;
                        end
				
	if (progress == 1)
	begin
		if (~zeroflag) counter = counter + 1;
			else zeroflag = 0;
			
		
		
				
	end
	
	if (progress == 0)
	begin
		if (match) begin
						progress = 1;
						counter = 0;
						zeroflag = 1;
						if (xsize) xcount = 31; else xcount = 15;
		end
		
	end
		
			
end
	assign adder = counter;
	assign n_spr_in_progress = ~progress;




		
endmodule


