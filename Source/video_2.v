//=======================================================
/* FPGA mappy video module
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
//=======================================================
`ifdef QUARTUS
`default_nettype none
`endif

module mappy_video(

    output wire [11:0]AB_tile,
	input wire [7:0]tile_ram_out,
	input wire [7:0]tile_pal_out,
	
	
// VIDEO input
	input wire pclk,		// 6.144MHz video clock
	input wire flip,		// screen flip register

    // VIDEO output
	output wire [8:0] vc,   // V-counter
	output wire [8:0] hc,	// H-counter
	output wire vb,		// V-BLANK
	output wire hb,
	output wire hs,		// H-SYNC
	output wire vs,		// V-SYNC
	output wire [2:0]r,
	output wire [2:0]g,
	output wire [1:0]b,
	

	input wire clk_18432,
    input wire clk_36864,
	output reg [8:0] hcount_raw,
	input wire [7:0] tile_scroll,
	
	output wire  [10:0]AB_obj1,AB_obj2,AB_obj3,
	
	input wire [7:0]obj1in,obj2in,obj3in,

	output wire [11:0]bg_addr,
	input wire [7:0]bg_data,
	input wire [7:0]tileclut_out,spclut_out,
	output reg [7:0]tileclut_addr,
	output reg [10:0]spclut_addr,
	input wire n_main_reset,
	input wire n_sub_reset,
	
	output reg [4:0]clut_addr,
	input wire [7:0]clut_out,
	
	output reg [13:0]AB_gfx2,
	input wire [7:0]gfx2aout,
	input wire [7:0]gfx2bout,
    
    input wire [3:0]game_kind
);

wire pclk6x = clk_36864;
assign bg_addr = ref_addr;

// H timming generator
//
// counter = 0-255,384-511
// hblank  = 400(0x190)-495(0x1ef)
// hsync   = 416(0x1a0)-447(0x1bf)

//  384-399  
//  496-512
//
//  original druaga	
//  hcount 128-511
//  hblank 144-240
//
//
//2019.7.13
//original hblank-sync =>  32 - 32 - 32 
//hblank 400 - 495
//hsync  424 - 455 ( 0x1a8 - 0x1c8 )
//
//+2dot
//

reg [8:0] hcount;
reg [8:0] delay_hcount;
//reg [8:0] hc_raw;
reg [8:0] hcount_read;

reg hblank;
reg hsync;

initial delay_hcount = 8'h3;

always @(posedge pclk)
begin
    hcount_raw <= hcount_raw + 1;
    hcount_read <= hcount_read + 1;
    
    if(hcount == 495)
        begin
            hcount_raw <= 0;
            hcount_read <= 8'h28  ;  //495,28 is correct
            
            
        end
        
	//hblank
	if( hcount == 399)
	hblank <= 1;

    if(hcount[6:0] == 7'h6f)
    begin
        hblank <= 0;
    end
    
	//shet?? if( hblank && hcount[6:0] == 7'h25) hsync <= 1;
	if( hblank && hcount[6:0] == 7'h28) hsync <= 1;

	//shet?? if(hcount[6:0] == 7'h45) hsync <= 0;
   if(hcount[6:0] == 7'h48) hsync <= 0;

	//	if(hcount == 441)

	//H counter
	hcount <= (hcount==255) ? 384 : hcount + 1;

    
end

always @(posedge pclk)
begin

//delayed H counter
//実際の表示がこうなっている
//   398,399,498...512,0...255,384..397
//	         498...512,0...255,384..399(blank)　としたい

//       0...256,384..399,498..511
//  +3   3...259,387..402,501..514(=>0,1,2)
  
//  ideal
//      3...256,384,385,386, 387....402, 401...514
//      3...256,384,385,386, 387...402,501...511,0,1,2
      
	delay_hcount = hcount + 4;
	if (delay_hcount == 256) delay_hcount = 384;
	if (delay_hcount == 257) delay_hcount = 385;
	if (delay_hcount == 258) delay_hcount = 386;
	if (delay_hcount == 259) delay_hcount = 387;
	
   //actual 252,253,254,255,256,257,258,387,388,389,390...
   //ideal  252,253,254,255,384,385,386,387......	
	
end


//
// V timing generator
//
// counter = 0-255,504-511
// vblank  = 240(0x0f0)-255(0x0ff)-504(0x1f8)-511(0x1fe)-015(0x0f)
// vsync   = 504-511
//
//
// REAL BOARD
// by mad 2019.07.07
//
// vblank
// vsync = 504 - 511 
// vblank = 248 - 255 - 504 - 511 - 023 
//

reg [8:0] vcount;
reg [8:0] delay_vcount ;
reg vblank;
wire vsync;

initial delay_vcount = 9'h1f0;

always @(posedge pclk)
begin

if (hblank && hcount[6:0] == 7'h28) begin

	if ( vcount == 240)
		vblank <= 1;
	if ( vcount[5:0] == 6'h10)
		vblank <= 0;

		vcount <= (vcount==247) ? 496 : vcount+1;
        

end

	
end

assign vsync = ( vcount[8:3] == 6'b1_1111_0 );
reg [8:0] scrl_vcount;


always @(posedge pclk)
begin
	// V blank
	if (hblank && hcount[6:0] == 7'h28) begin

	delay_vcount = vcount + 9'h1f0 ;
	scrl_vcount = delay_vcount + tile_scroll+1;
	delay_vcount <= (delay_vcount==255) ? 504 : delay_vcount+1;
	end
	
	
end


assign hc = hcount;
assign vb = vblank;
assign hb = hblank;

assign hs = hsync;
assign vs = vsync;
assign vc = vcount;

// address bus

//
//sprite addresses
//tower of druaga
//
//
//0x1780 - 17ff
//tile_num = {1780[7:0],2780[7:6]
//tile_col = 1781[5:0]
//
//0x1f80 - 1fff
//y:vcount x: hcount side
//ypos = 1f80[7:0]
//xpos = 2781[0],1f80[7:0]
//
//yflip = 2780[1]
//xflip = 2780[0]
//disable = 2781[1]
//

//sprite num&col
//hc 400-495 ( 0x190 - 0x0x1f0 )
//1780-17ff ( hc 400-463 )
//(hblank)


reg[10:0]abobj1,abobj2,abobj3;


reg[8:0]nlr_waddr;
reg[8:0]nlr_raddr;
reg nlr_wen;
wire[3:0]nlr_rd0;
wire[3:0]nlr_rd1;
reg[3:0]nlr_wd;

simple_dual_port_ram #( .DATA_WIDTH(4), .ADDR_WIDTH(9) , .OUTPUT_REG ("FALSE") )
 nlr (
     //vcount[0] ==enable else write ff
    .wdata  ( (vcount[0] ? nlr_wd : 4'hf ) ),
    .waddr  ( (vcount[0] ? nlr_waddr : hcount_read[8:0]) ),


    .raddr  (nlr_raddr),
    .we ( vcount[0] ? nlr_wen : 1 ),
    .re (1),
    .wclk (~pclk6x),
    .rclk (clk_18432),
    .rdata (nlr_rd0)
	 
    );

    //~vcount[0]==enable
simple_dual_port_ram #( .DATA_WIDTH(4), .ADDR_WIDTH(9) , .OUTPUT_REG ("FALSE") )
 nlr2 (
    .wdata  (  ( ~vcount[0] ? nlr_wd : 4'hf )),
    .waddr  (  ( ~vcount[0] ? nlr_waddr : hcount_read[8:0]) ),

    .raddr  ( nlr_raddr),
    .we ( ~vcount[0] ? nlr_wen : 1),
    .re (1),
    .wclk   (~pclk6x),
    .rclk (clk_18432),
    .rdata (nlr_rd1)
	 
    );



reg [3:0] line_temp [15:0];
reg [2:0] count3x;
reg [7:0] offset;
//hcount -> 399 reset

reg [8:0] xpos;
reg [7:0] ypos;
reg [9:0] tileno;
reg [5:0] palno;
reg objflipx,objflipy;
reg line_match;

reg [8:0] y_v_add;

reg [1:0] xsize,ysize;

reg obj_on;

reg objdisable;

integer  i;


    wire [15:0]gfx2ab1_px = game_kind[3] ? 
                        (       AB_gfx2[13] ? 
                              {	    2'b00, gfx2bout[7],gfx2bout[3],
									2'b00, gfx2bout[6],gfx2bout[2],
									2'b00, gfx2bout[5],gfx2bout[1],
									2'b00, gfx2bout[4],gfx2bout[0] } :
                              {	    2'b00, gfx2aout[7],gfx2aout[3],
									2'b00, gfx2aout[6],gfx2aout[2],
									2'b00, gfx2aout[5],gfx2aout[1],
									2'b00, gfx2aout[4],gfx2aout[0] } ) 
                                    
                            : ( {   gfx2aout[7],gfx2aout[3],gfx2bout[7],gfx2bout[3],
									gfx2aout[6],gfx2aout[2],gfx2bout[6],gfx2bout[2],
									gfx2aout[5],gfx2aout[1],gfx2bout[5],gfx2bout[1],
									gfx2aout[4],gfx2aout[0],gfx2bout[4],gfx2bout[0]  } );
wire n_hreset = ~ ( hcount == 9'h1ff );
wire n_spr_in_progress;
reg s_match;
wire [4:0]adder;									
wire [4:0]adder_1 = adder + 1;

wire [10:0]abobj123;

reg [2:0] counter;	

always @(negedge pclk6x )

begin

    nopx = 1;
    
		if (hcount == 9'h1a8 ) begin //424
           			offset = 0;
					count3x = 0;
		end else 
        
        begin
        
        
		case ( count3x )
		0: begin
            abobj1 <= 11'h780 + offset;
            abobj2 <= 11'h780 + offset;
            abobj3 <= 11'h780 + offset;
            offset = (offset == 129 ) ? offset :  offset + ( n_spr_in_progress ) ;
            
		end
		
		1: begin
            abobj1 <= 11'h780 + offset;
            abobj2 <= 11'h780 + offset;
            abobj3 <= 11'h780 + offset;


			ypos = obj2in ; 
			tileno =  obj1in[7:0];
            objflipx = obj3in[0];
			objflipy = obj3in[1];
			xsize = obj3in[3:2];
			s_match = 0;
			
			
		end
		
		2: begin
			palno = obj1in[5:0];
			xpos = { obj3in[0], obj2in[7:0] };
			//objdisable = obj3in[1];
			y_v_add = ypos + delay_vcount[7:0] + ( xsize[1] ? 16 : 0) - 1; 
            s_match = (offset == 129 ) ? 0 :   (xsize[1]) ? ( y_v_add[8:5]==4'b0111 ) : (y_v_add[8:4]==5'b01110);
            offset = (offset == 129 ) ? offset  :  offset + ( n_spr_in_progress ) ;

            end

       endcase
		if (~n_spr_in_progress )
         begin
            nopx = 0;
        AB_gfx2   =   
        { tileno[7:2] ,  xsize[1] ? (objflipy ^ y_v_add[4]) : tileno[1]  , xsize[0] ? 1'b0 : tileno[0],  y_v_add[3]^objflipy, 2'b0, y_v_add[2:0]^{3{objflipy}}}	
            +  { adder_1[4],1'b0,adder_1[3:2] , 3'b000 } ;	

        end else 
        begin
             nopx = 1;
        end
                            
		count3x = (count3x==2) ? 0: count3x + n_spr_in_progress;

		if ( ~n_spr_in_progress )	s_match = 0;

    end
        
        
end
		assign AB_obj1 = abobj1;
		assign AB_obj2 = abobj2;
		assign AB_obj3 = abobj3;
		
reg [3:0]pxset[3:0];
    
wire [9:0]db_col4;
reg nopx;
reg [3:0] new_lram_temp;
reg [9:0] px;
reg [9:0] pxref; 

always @(negedge pclk6x)
begin		

    new_lram_temp = 4'hf;

	if ( ~n_spr_in_progress & ~objdisable & (nopx==0) )
		begin
                  
                  {pxset[0],pxset[1],pxset[2],pxset[3]}  = gfx2ab1_px;
            
    //  10bit     aaaaaa aaaa
    //   8bit     aaaaaa   aa
                    px = {palno, pxset[adder[1:0]] };
                    pxref = ( game_kind[3] ) ? { 2'b00, px[9:4] , px[1:0] } : px;
                new_lram_temp = palrom_data [ pxref ];
		end
end

always @(posedge pclk6x)
begin
	
    nlr_wd = 4'hf;
	nlr_waddr = 0; 

    if ( ~n_spr_in_progress) 
        begin
				nlr_waddr = ( xpos + (   adder[4:0]^{xsize[0] & objflipx,{4{objflipx}}}   )  ) ;
				nlr_wd = new_lram_temp;
                nlr_wen = (nlr_wd != 4'hf);
                
        end
end


reg [3:0]palrom_data [1023:0] ;
reg [9:0] j;
reg [1:0]pal_counter;

always @( negedge clk_18432)
// reg にパレットロム内容を読むこむ
begin
 case (pal_counter)
 
	0: begin
		spclut_addr = j ;
		if (n_main_reset & n_sub_reset) 
			pal_counter = pal_counter + 1;

		end
		
	1: pal_counter = pal_counter + 1;
	
	2: begin
		palrom_data[j] = spclut_out;
		pal_counter = pal_counter + 1;
		end

	3: begin 
		j = (j==1023) ? 1023 : j + 1;
		pal_counter = 0;
		end
		
endcase


end
 		
spr_adder  sa0	(
				.n_spr_in_progress ( n_spr_in_progress ),
				.adder ( adder ) ,
				.match ( s_match )	,
				.xsize ( xsize[0] ) ,
                .pclk   (pclk6x)
				);
//mp
      wire [11:0] ab_centr_mp = scrl_vcount[8:3]  << 5 | hcount[7:3] ;
//gr
      wire [9:0] ab_centr_gr = (scrl_vcount[8:3]  << 5 | hcount[7:3]) + 8'h40;

//mappy type
wire [11:0] ab_lr_centr_mp  = {5'b1111_1 , &hcount[6:4] , hcount[3] , 4'b0000, delay_vcount[3] } ;
wire [11:0] ab_lr_norml_mp = {5'b1111_1 , &hcount[6:4] , hcount[3] , delay_vcount[7:3] } + 2 ;
wire [11:0] ab_lr_mp = (delay_vcount[7:4]==4'b0111) ? ab_lr_centr_mp : ab_lr_norml_mp;

//grobda,pacnpal,spacman type
wire [9:0] ab_lr_gr  = {{4{ &hcount[6:4]}} ,hcount[3],delay_vcount[7:3] } + 2;

// multiplex
assign AB_tile  = (hcount[8]) ?  ( game_kind[3] ? ab_lr_gr : ab_lr_mp )    : (game_kind[3] ? ab_centr_gr : ab_centr_mp ) ; // L,R    / center

reg [2:0]rr;
reg [2:0]rg;
reg [1:0]rb;

reg [11:0] ref_addr;

reg [1:0] px_c;
reg [7:0] gfx_latch;
			
reg [7:0] pal_latch;
reg [7:0] line_out;
reg [1:0] disp_count;

reg prw;


wire [3:0] lo_0,lo_1;

reg [3:0] spr_lram_out;
always @(negedge clk_18432)
begin
//hcount[8]==0 -> center tile

   
	case (disp_count)
	
	default:	begin
	
		ref_addr = (hcount[8]) ?
							{ tile_ram_out, ~hcount[2], vcount[2:0] } :
							{ tile_ram_out, ~hcount[2], scrl_vcount[2:0] } ;
		disp_count = disp_count +1;
        nlr_raddr = hcount_read[8:0];
		spr_lram_out = vcount[0] ? nlr_rd0 : nlr_rd1;
		
	end
	3:begin
	
								
		if (hcount[1:0] == 2'b00)
		begin
            //mp
			//gfx_latch = gfx1_out;
            //gr
            // gfx_latch = ~gfx1_out;
                gfx_latch = game_kind[3] ? ~gfx1_out : gfx1_out;
				pal_latch = tile_pal_out;
		end
		
				px_c[1:0] =     hcount[1:0] == 2'b00 ? {~gfx_latch[7],~gfx_latch[3]} :
							    hcount[1:0] == 2'b01 ? {~gfx_latch[6],~gfx_latch[2]} :
							    hcount[1:0] == 2'b10 ? {~gfx_latch[5],~gfx_latch[1]} :
							    hcount[1:0] == 2'b11 ? {~gfx_latch[4],~gfx_latch[0]} : 1'b0;
								 
								 
		tileclut_addr =   ( { pal_latch[5:0] , 2'b00 }  | px_c[1:0] );
		disp_count = disp_count +1;
		
       if ( game_kind[3] )
        begin
           //gr,sp,pp
            color_latch = (spr_lram_out == 4'hf ) ? (~tileclut_out)|8'h10 : spr_lram_out ;
            color_latch = (prw & ( (~tileclut_out) != 4'hf )  ) ? (~tileclut_out)|8'h10 : color_latch;

            //if pacnpal, special priority
          if (game_kind==4'b1110)
            color_latch = ( spr_lram_out[3:1]==3'b0 ) ? spr_lram_out : color_latch;
        end
    else begin
        //mp,dr
            color_latch = (spr_lram_out == 4'hf ) ? tileclut_out|8'h10 : spr_lram_out ;
            color_latch = (  prw & ( tileclut_out != 4'hf )  ) ? tileclut_out|8'h10 : color_latch;
        end
		//1 clock delay reading priority
		prw = pal_latch[6];
		disp_count = disp_count + 1;
		
	end
	endcase
end

reg [7:0]color_latch;

wire [8:0] tline0r;
simple_dual_port_ram #( .DATA_WIDTH(8), .ADDR_WIDTH(10) , .OUTPUT_REG ("FALSE") )
 tline_1 (
    .wdata  ({pal_latch[6],color_latch}),
    .waddr  ({vcount[0],hcount}),
    .raddr  ({~vcount[0],delay_hcount}),
    .we (disp_count==3),
    .re (1),
    .wclk (~clk_18432),
    .rclk (clk_18432),//~pclk),
    .rdata (tline0r)
	 
    );
   

wire [9:0] hcountx;
wire [9:0] hcounty;

always @(negedge clk_18432)
begin						 
	clut_addr <= tline0r[4:0];
		
end

reg [7:0] clut_out_pclk;

always @(posedge pclk)
	clut_out_pclk = clut_out;
	

assign {b,g,r} = ( hblank | vblank ) ? 8'h00 : clut_out_pclk;

wire [7:0] gfx1_out = bg_data;

endmodule
