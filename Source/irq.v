//=======================================================
// FPGA mappy vector handler
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


module dru_irq( 
    input wire IRQEN, IRQEN2, 
    input wire IRQTRG, 
    output wire n_IRQ, n_IRQ2,
    
    input wire pxclk,
    input wire hb,
    input wire [8:0]hc,
    input wire [8:0]vc
   
   );

	reg irq_latch,irq_latch2;

    always @(posedge IRQTRG or negedge IRQEN)
    //always @(posedge pxclk or negedge IRQEN)
 
	begin
		if(IRQEN==0)
			irq_latch = 1'b1;
		else
         //   if (hb && (hc[6:0]==7'h28) && (vc == 240) )
                irq_latch = 1'b0;
            
        end
	
	
    always @(posedge IRQTRG or negedge IRQEN2)
    //always @(posedge pxclk or negedge IRQEN2)
       
	begin
		if (IRQEN2==0)
			irq_latch2 = 1'b1;
		else
      //      if (hb && (hc[6:0]==7'h28) && (vc == 240) )
                irq_latch2 = 1'b0;
	end  

assign n_IRQ = irq_latch;
assign n_IRQ2 = irq_latch2;
	

endmodule
	