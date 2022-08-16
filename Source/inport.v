//=======================================================
// FPGA mappy I/O module
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
                                            4808 4818  sv
Super Pac Man           56XX  56XX  ----  ---- 4 9      1 9  UDLR:4801 T:4803[0] S1:4803[2] C:4800[0]
Pac & Pal               56XX  59XX  ----  ---- 1 3      1 3  (same)
Motos                   56XX  56XX  ----  ---- 1 9      1 9  (same)
Mappy                   58XX  58XX  ----  ----       1 4  UDLR:4805 T:4807[0] T2:4815(tglsub) S1:4807[2]
Phozon                  58XX  56XX  ----  ----

*/

module namco5856_inp_new(
// inputs
	input wire [15:0]AB,
	input wire vsync,
	input wire [8:0]vcnt,
	input wire [8:0]hcnt,
	input wire hsync,
	input wire pxclk,
	
	
	input wire IO1,IO2,
	input wire LEFT,
	input wire RIGHT,
	input wire UP,
	input wire DOWN,
	input wire TRIG,
    input wire TRIG2,
	input wire START,
	input wire COIN,

//output
	//AB_5856,
	
	output wire [7:0]outport,
	
	input wire [7:0]inport,
    input wire ZRW,
	
    input wire [3:0]game_kind,
    
    
    input wire [15:0]dipsw,
    input wire svsw
    
	
);

reg [7:0] w_out;

reg [7:0] port_4800,port_4801,port_4802,port_4804;
reg [7:0] port_4805,port_4803,port_4807;
reg [7:0] port_4815,port_4816,port_4817;

reg [7:0]port_mem;

reg [7:0]coin_counter;
reg [1:0]coin_toggle;

reg deduction;


reg [3:0] reg48xx [31:0];

wire [4:0] ab_5b = AB[4:0];
wire io_en = (AB[15:5]==11'b0100_1000_000);


//hsync edge
//vcnt [4:0] -> 

	//UP 1  R 2 D 4 L 8
	//

always @(posedge pxclk)

begin

	if (io_en & ZRW)
	begin
	reg48xx[ab_5b] <= inport[3:0];
	end
    
    //hit 4800
    if (io_en & ZRW && (ab_5b == 5'b0) )
    begin
        if ( (game_kind[1] == 1'b0)  && reg48xx[8]==3 )
                    reg48xx[3]  <= port_4803[3:0];
    end

    if (deduction) begin
        reg48xx[3] <= port_4803[3:0];
       
    end
    
    
      
    //function 8,16 write -> next frame

//    if ((hcnt==399) && (vcnt==9'h013))

   

//    if ((hcnt==399) && (vcnt==9'h020))
    if ((hcnt==399) && (vcnt==9'h011))

    //    if ((hcnt==399) && ( vcnt[0] == 1'b1 ) )
	begin


/* ********************************************************************
   startup check
   ******************************************************************** */
// 58xx + 58xx 4bitsp  mappy    == 0000
// 58xx + 56xx 4bitsp  td,dig2  == 0001
// 56xx + 56xx 4bitsp  mo       == 0011
// 58xx + 56xx 2bitsp  grobda   == 1001
// 56xx + 59xx 2bitsp  pacnpal  == 1110
// 56xx + 56xx 2bitsp  spacman  == 1011
   
   
     if (game_kind == 4'b0000) /* mappy, druaga */
         if ( reg48xx[8] == 5 && reg48xx[24] == 5 )
            begin
		reg48xx[0] <= 0;
		reg48xx[1] <= 8;
		reg48xx[2] <= 4;
		reg48xx[3] <= 6;
		reg48xx[4] <= 4'he;
		reg48xx[5] <= 4'hd;
		reg48xx[6] <= 4'h9;
		reg48xx[7] <= 4'hd;
		reg48xx[16] <= 0;
		reg48xx[17] <= 8;
		reg48xx[18] <= 4;
		reg48xx[19] <= 6;
		reg48xx[20] <= 4'he;
		reg48xx[21] <= 4'hd;
		reg48xx[22] <= 4'h9;
		reg48xx[23] <= 4'hd;
            end

    //grobda
    if (game_kind == 4'b1001) 
      if ( reg48xx[8] == 5 ) //&& reg48xx[24] == 5 )
		begin
		reg48xx[2] <= 4'hf;
		reg48xx[6] <= 4'hc;
        reg48xx[16] <= 4'h6;
        reg48xx[17] <= 4'h9;
        
		end

    //motos,superpac
    if ( (game_kind == 4'b0011) || (game_kind == 4'b1011)  )
    begin
        if ( reg48xx[8] == 8 && reg48xx[24] == 8 ) 
        begin
		reg48xx[0] <= 6;
		reg48xx[1] <= 9;
		reg48xx[2] <= 0;
		reg48xx[3] <= 0;
		reg48xx[4] <= 0;
		reg48xx[5] <= 0;
		reg48xx[6] <= 0;
		reg48xx[7] <= 0;
        reg48xx[16] <= 6;
		reg48xx[17] <= 9;
		reg48xx[18] <= 0;
		reg48xx[19] <= 0;
		reg48xx[20] <= 0;
		reg48xx[21] <= 0;
		reg48xx[22] <= 0;
		reg48xx[23] <= 0;
        end
            
    end
// 58xx + 58xx 4bitsp  mappy    == 0000
// 58xx + 56xx 4bitsp  td,dig2  == 0001
// 56xx + 56xx 4bitsp  mo       == 0011

// 58xx + 56xx 2bitsp  grobda   == 1001
// 56xx + 59xx 2bitsp  pacnpal  == 1110
// 56xx + 56xx 2bitsp  spacman  == 1011
/*                                         4808 4818  sv
Super Pac Man           56XX  56XX  ----  ---- 4 9      1 9  UDLR:4801 T:4803[0] S1:4803[2] C:4800[0]

Pac & Pal               56XX  59XX  ----  ---- 1 3      1 3  (same)
Motos                   56XX  56XX  ----  ---- 1 9      1 9  (same)

Mappy                   58XX  58XX  ----  ---- 3 4      1 4  UDLR:4805 T:4807[0] S1:4807[2] C:4800[0]
The Tower of Druaga     58XX  56XX  ----  ---- 3 4      1 4  (same)
Grobda                  58XX  56XX  ----  ---- 3 9      1 9  (same)
Dig Dug II              58XX  56XX  ----  ---- 3 4      1 4  UDLR:4805 T:4807[0] T2:4815(tglsub) S1:4807[2]
*/
/* ********************************************************************
   input mode
   ******************************************************************** */
   //mp,td,gr,d2 : 58xx
   //mode: 3,4 
   //mp,td,d2

    // custom first == 58xx, and 4808 == 3
    if ( (game_kind[1] == 1'b0)  && reg48xx[8]==3 )
        begin
            reg48xx[0] <= port_4800[3:0];
            reg48xx[1] <= port_4801[3:0];
//          reg48xx[3] <= port_4803[3:0];
            reg48xx[4] <= port_4804[3:0];
            reg48xx[5] <= port_4805[3:0];
            reg48xx[7] <= port_4807[3:0];
       end
       
    if ( (game_kind[1] == 1'b0) && reg48xx[8] == 1)
       begin
            reg48xx[5] <= port_4805[3:0];
            reg48xx[7] <= port_4807[3:0];
       end
       
       
       
    // custom first == 56xx, and 4808 == 1 or 4
    if ( (game_kind[1] == 1'b1) && ( reg48xx[8] == 1 || reg48xx[8] == 4 ) && ( reg48xx[24]== 9 || reg48xx[24]== 3 ) )
      begin
            reg48xx[0] <= port_4800[3:0];
            reg48xx[1] <= port_4801[3:0];
            reg48xx[2] <= port_4802[3:0];
            reg48xx[3] <= port_4803[3:0];
            reg48xx[4] <= port_4804[3:0];
            reg48xx[5] <= port_4805[3:0];
            reg48xx[7] <= port_4807[3:0];
      end
      

    //mappy only
    if ( (game_kind[2:0] == 3'b000)  &&  ( reg48xx[24] == 4) )
    begin
           reg48xx[18] <= dipsw[3:0];
           reg48xx[19] <= dipsw[3:0];
           reg48xx[20] <= dipsw[7:4];
           reg48xx[21] <= dipsw[7:4];
           reg48xx[16] <= dipsw[11:8];
           reg48xx[17] <= dipsw[15:12];
           reg48xx[22] <= { svsw , 3'b0};
           reg48xx[23] <= { svsw , 3'b0};
           
           
    end
    
    //td,dig2
    //xxxx + 56xx / 4
    if ( (game_kind[0] == 1'b1)  && ( reg48xx[24] == 4) )
    begin
           reg48xx[20] <= dipsw[3:0];
           reg48xx[22] <= dipsw[7:4];
           reg48xx[21] <= port_4815[3:0];
    end
    
    //motos,gr,sp
    //xxxx + 56xx / 9
    if ( (game_kind[0] == 1'b1)  && ( reg48xx[24] == 9) )
    begin
            reg48xx[22] <= {svsw,port_4816[2:0]};
            reg48xx[23] <= {svsw,port_4817[2:0]};
            
            reg48xx[18] <= dipsw[3:0];
            reg48xx[19] <= dipsw[3:0];
            reg48xx[20] <= dipsw[7:4];
            reg48xx[21] <= dipsw[7:4];
            reg48xx[16] <= dipsw[11:8];
            reg48xx[17] <= dipsw[15:12];
    end
    
    //pp
    //xxxx + 59xx / 3
    
    if ( (game_kind == 4'b1110) && ( reg48xx[24] == 3) )
    begin
            reg48xx[22] <= dipsw[3:0];
            reg48xx[21] <= dipsw[7:4];
            reg48xx[20] <= dipsw[11:8];
            reg48xx[23] <= { svsw , 3'b0};
                
    
    end
    

    
    end
    
end

    
    
/*
                                            4808 4818  sv
Super Pac Man           56XX  56XX  ----  ---- 4 9      1 9  UDLR:4801 T:4803[0] S1:4803[2] C:4800[0]
Pac & Pal               56XX  59XX  ----  ---- 1 3      1 3  (same)
Motos                   56XX  56XX  ----  ---- 1 9      1 9  (same)

Mappy                   58XX  58XX  ----  ---- 3 4      1 4  UDLR:4805 T:4807[0] S1:4807[2] C:4804[0]
The Tower of Druaga     58XX  56XX  ----  ---- 3 4      1 4  (same)
Grobda                  58XX  56XX  ----  ---- 3 9      1 9  (same)
Dig Dug II              58XX  56XX  ----  ---- 3 4      1 4  UDLR:4805 T:4807[0] T2:4815(tglsub) S1:4807[2]

Phozon                  58XX  56XX  ----  ----


*/
// 58xx + 58xx 4bitsp  mappy    == 0000
// 58xx + 56xx 4bitsp  td,dig2  == 0001
// 56xx + 56xx 4bitsp  mo       == 0011

// 58xx + 56xx 2bitsp  grobda   == 1001
// 56xx + 59xx 2bitsp  pacnpal  == 1110
// 56xx + 56xx 2bitsp  spacman  == 1011

// [3] ... 4bit or 2bit
// [1:0] .. 58?56?
// [2] .. 59

always @(posedge pxclk)
	
	if ((hcnt==399) && (vcnt==9'h010)) //240))
//  if ( io_en )

//    if ((hcnt==399) && ( vcnt[0] == 1'b0))
  
	begin
    
	//service mode  motos,pp,sp(56XX)
    if (reg48xx[8] == 1)
        begin
        //sp service mode
        //pp mo (56xx + xxxx) normal mode
            if ( game_kind[1] == 1'b1 )
                    begin
                        port_4801 = { 4'hf, LEFT, DOWN, RIGHT, UP};
                        port_4803 = { 4'hf, 1'b0, START ,1'b0 ,TRIG};
                        port_4800[0] = COIN;
                        
                    end else 
                    begin
                        port_4805 = { 4'hf, LEFT, DOWN, RIGHT, UP};
                        port_4807 = { 4'hf, 1'b0, START, 1'b0 ,TRIG};
                    end    
        end
        
    //mp,td,d2,gr,sp
    else 
       begin
        port_4804 = {4'hf, LEFT,DOWN,RIGHT,UP} ;
    	port_4805[0] = ( port_4805[1] ) ? 0 : TRIG ;
    	port_4805[1] = TRIG;
    	port_4805[2] = ( port_4805[3] ? 0 : START );
    	port_4805[3] = START;

        //mp,td,d2,gr,sp
        
        //58xx + xxxx
        if (game_kind[1] == 1'b0) begin
    	port_4815[0] = ( port_4815[1] ) ? 0 : TRIG2 ;
    	port_4815[1] = TRIG2;
        end
    
        //mp,gr,td,d2
        if (game_kind[1] == 1'b0)
        begin
        //check 4801 and coin deduction

        port_4801[0] = reg48xx[9];
        deduction = 0;
        
        if ( port_4805[2] && ~reg48xx[9] ) begin
            if ( coin_counter != 0) begin
                deduction = 1;
                coin_counter = coin_counter - 1;
                port_4801[0] = 1;
            end
        end

        // 	port_4801[0] =   ( coin_counter == 0 ) ? 0 :  (reg48xx[9] ? 0 : port_4805[2]);
        coin_toggle[0] = ( coin_toggle[1] ? 0 : COIN );
        coin_toggle[1] = COIN;
        port_4800[0] =  coin_toggle[0];
        
        port_4816[0] =  TRIG2;
        port_4817[0] =  TRIG2;
        
   
        
        end
    //end

        if (reg48xx[8] == 4) begin
        //sp
        if (game_kind == 4'b1011) begin
        coin_toggle[0] = ( coin_toggle[1] ? 0 : COIN );
        coin_toggle[1] = COIN;
        port_4802[0] =  coin_toggle[0];
        end
    end

end

	if (coin_toggle[0]) begin
            coin_counter = (coin_counter == 9) ? coin_counter : coin_counter + coin_toggle[0];
    end

//  if (port_4805[2] & ~port_4801[0] )// ~reg48xx[9])
//		begin
//           coin_counter = (coin_counter==0) ? 0 : coin_counter - 1 ;
//      end


    //spだけ別処理
        if ( game_kind==4'b1011 ) 
             port_4801 = { 5'b11110 ,  coin_counter };
        else 
             if ( ~ (game_kind == 4'b0011 || game_kind == 4'b1110) ) 
                   // ??port_4803 = { 5'b11110 ,  coin_counter };
                    port_4803 = { 4'b1111 ,  coin_counter[3:0] };


   
   // gr は特別処理
    if ( game_kind == 4'b1001 ) port_4803 = { 5'b11110, coin_counter };
		
	end


assign outport = (io_en) ? { 4'b1111, reg48xx[ab_5b] } : 8'h00 ;

endmodule

/* dip sw */
// mappy,grobda,superpac SWA,SWB
// pacnpal SWA,SWB[3:0]
// dig2,motos,druaga SWA only


/*

58xx mode 4
SW1
		1 2 3 4 5 6 7 8
4812,3	0 1 2 3 
4814,5          0 1 2 3


SW2
		1 2 3 4 5 6 7 8
4810	0 1 2 3 
4811			0 1 2 3



56xx mode 4
SW1
        1 2 3 4 5 6 7 8
4814	0 1 2 3 
4816            0 1 2 3

SW2 unused


56xx mode 9
SW1
		1 2 3 4 5 6 7 8
4812,3	0 1 2 3
4814,5			0 1 2 3

SW2
		1 2 3 4 5 6 7 8
4810	0 1 2 3
4811			0 1 2 3


59xx mode3
SW1
		1 2 3 4 5 6 7 8
4817	0 1 2 3
4815			0 1 2 3

SW2
		1 2 3 4 5 6 7 8
4814	0 1 2 3

*/    
    
