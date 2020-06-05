//Project: Homework2
//Module: CRC32
//Author: Caspar Chen
//E-mail:caspar_chen@pegatroncorp.com
//Date:20200210

`timescale 1ns/1ns 
module CRC32(rst_n, clk, sof, eof, data_v, data, full, err);
    parameter BUS_WIDTH = 8;
	 parameter CRC_BITS = 32;
//define input & output signals
    input rst_n;
    input clk;
	 input sof;
	 input eof;
	 input data_v;
	 input [BUS_WIDTH-1:0] data;
	 output reg full;
	 output reg err;
	 
//============================================================	 
//State Machine Control
//============================================================

	 parameter [1:0] INITIAL = 2'b00;
	 parameter [1:0] READY = 2'b01;
	 parameter [1:0] CALCULATE = 2'b11;
	 parameter [1:0] DONE = 2'b10;
	 reg crc_check;
	 reg [2:0] counter_full; 
	 reg [1:0] state_now, state_next;
	 
//State Machine for rst_n Timing Logic  	 
	 always @ (posedge clk or negedge rst_n) begin
	     if (!rst_n)
		      begin
				    state_now <= #1 INITIAL;
				end
		  else 
		      begin
				    state_now <= #1 state_next;
			   end
  	end
//State Machine for Combinatorial Logic
	 always @ (*) begin
	     case (state_now)
		      INITIAL:
				    if (sof)
		              begin
				            state_next = READY;
						      crc_check = 1'b0;		
					     end			
				    else begin
					     state_next = state_now;
						  crc_check = 1'b0;	
					 end
			   READY:
				    if(sof) 
					     begin
								state_next = CALCULATE;
								crc_check = 1'b0;
					     end 
					 else begin
					     state_next = state_now;
						  crc_check = 1'b0;	
					 end
				CALCULATE:
					 if (eof)
					     begin
					         state_next = DONE;
								crc_check = 1'b0;	
						  end	
				    else begin
						  state_next = state_now;
						  crc_check = 1'b0;	
					 end
				DONE:
		          if (sof)
					     begin
					         state_next = CALCULATE;
								crc_check = 1'b0;	
				        end
				    else begin
					     state_next = READY;
						  crc_check = 1'b1;	
					 end
				default:
		          begin

				    end	 
	     endcase    
	 end
	 
	 always @(posedge clk or negedge rst_n) begin
		  if(!rst_n)
			   begin
				    counter_full <=#1 3'd0;
				    full <= 1'b0;
			   end
		  else
			   begin
				    counter_full <=#1 counter_full+ 3'd1;					
				    if (counter_full== 3'd3)
					     full <= 1'b1;
				    else
					     full <= 1'b0;
			   end
    end    

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////                                         
// CRC32 parallel combinational logic from https://www.easics.com/webtools/crctool                               //                                                                                                             //
// Purpose : synthesizable CRC function                                                                          //
//   * polynomial: x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x^1 + 1 //
//   * data width: 8                                                                                             //
//   convention: the first serial bit is D[7]                                                                    //
//   *procedure:                                                                                                 //
//		1. Initial crc is 0xff ff ff ff                                                                            //
//		2.	Input reflected                                                                                         //
//		3.	Calculating next crc                                                                                    //
//		4. Results reflected                                                                                       //
//		5. Results xor with 0xff ff ff ff                                                                          //                                                                                                     //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////	 
    parameter INITIAL_CRC = 32'hffffffff;
	 parameter INITIAL_IN_DATA = 8'h00;
	 
	 reg [(BUS_WIDTH*4)-1:0] in_data;
	 reg [(CRC_BITS*4)-1:0] crc_shift_last_4;
	 reg [CRC_BITS-1:0] crc_now;
	 wire [CRC_BITS-1:0] crc_reflected;
	 wire [CRC_BITS-1:0] crc_next;
	 wire [BUS_WIDTH-1:0] in_data_reflected; 
	 wire compare;
	 
	 assign compare = (crc_shift_last_4[(CRC_BITS*4)-1:(CRC_BITS*3)] == in_data) ? 1'b1 : 1'b0;	 
//Input reflected	 
	 assign in_data_reflected[BUS_WIDTH-1] = in_data[(BUS_WIDTH-8)];
	 assign in_data_reflected[BUS_WIDTH-2] = in_data[(BUS_WIDTH-7)];
	 assign in_data_reflected[BUS_WIDTH-3] = in_data[(BUS_WIDTH-6)];
	 assign in_data_reflected[BUS_WIDTH-4] = in_data[(BUS_WIDTH-5)];
	 assign in_data_reflected[BUS_WIDTH-5] = in_data[(BUS_WIDTH-4)];
	 assign in_data_reflected[BUS_WIDTH-6] = in_data[(BUS_WIDTH-3)];
	 assign in_data_reflected[BUS_WIDTH-7] = in_data[(BUS_WIDTH-2)];
	 assign in_data_reflected[BUS_WIDTH-8] = in_data[(BUS_WIDTH-1)];
//Calculating next crc
    assign crc_next[CRC_BITS-32] = in_data_reflected[6] ^ in_data_reflected[0] ^ crc_now[24] ^ crc_now[30];
    assign crc_next[CRC_BITS-31] = in_data_reflected[7] ^ in_data_reflected[6] ^ in_data_reflected[1] ^ in_data_reflected[0] ^ crc_now[24] ^ crc_now[25] ^ crc_now[30] ^ crc_now[31];
    assign crc_next[CRC_BITS-30] = in_data_reflected[7] ^ in_data_reflected[6] ^ in_data_reflected[2] ^ in_data_reflected[1] ^ in_data_reflected[0] ^ crc_now[24] ^ crc_now[25] ^ crc_now[26] ^ crc_now[30] ^ crc_now[31];
    assign crc_next[CRC_BITS-29] = in_data_reflected[7] ^ in_data_reflected[3] ^ in_data_reflected[2] ^ in_data_reflected[1] ^ crc_now[25] ^ crc_now[26] ^ crc_now[27] ^ crc_now[31];
    assign crc_next[CRC_BITS-28] = in_data_reflected[6] ^ in_data_reflected[4] ^ in_data_reflected[3] ^ in_data_reflected[2] ^ in_data_reflected[0] ^ crc_now[24] ^ crc_now[26] ^ crc_now[27] ^ crc_now[28] ^ crc_now[30];
    assign crc_next[CRC_BITS-27] = in_data_reflected[7] ^ in_data_reflected[6] ^ in_data_reflected[5] ^ in_data_reflected[4] ^ in_data_reflected[3] ^ in_data_reflected[1] ^ in_data_reflected[0] ^ crc_now[24] ^ crc_now[25] ^ crc_now[27] ^ crc_now[28] ^ crc_now[29] ^ crc_now[30] ^ crc_now[31];
    assign crc_next[CRC_BITS-26] = in_data_reflected[7] ^ in_data_reflected[6] ^ in_data_reflected[5] ^ in_data_reflected[4] ^ in_data_reflected[2] ^ in_data_reflected[1] ^ crc_now[25] ^ crc_now[26] ^ crc_now[28] ^ crc_now[29] ^ crc_now[30] ^ crc_now[31];
    assign crc_next[CRC_BITS-25] = in_data_reflected[7] ^ in_data_reflected[5] ^ in_data_reflected[3] ^ in_data_reflected[2] ^ in_data_reflected[0] ^ crc_now[24] ^ crc_now[26] ^ crc_now[27] ^ crc_now[29] ^ crc_now[31];
    assign crc_next[CRC_BITS-24] = in_data_reflected[4] ^ in_data_reflected[3] ^ in_data_reflected[1] ^ in_data_reflected[0] ^ crc_now[0] ^ crc_now[24] ^ crc_now[25] ^ crc_now[27] ^ crc_now[28];
    assign crc_next[CRC_BITS-23] = in_data_reflected[5] ^ in_data_reflected[4] ^ in_data_reflected[2] ^ in_data_reflected[1] ^ crc_now[1] ^ crc_now[25] ^ crc_now[26] ^ crc_now[28] ^ crc_now[29];
    assign crc_next[CRC_BITS-22] = in_data_reflected[5] ^ in_data_reflected[3] ^ in_data_reflected[2] ^ in_data_reflected[0] ^ crc_now[2] ^ crc_now[24] ^ crc_now[26] ^ crc_now[27] ^ crc_now[29];
    assign crc_next[CRC_BITS-21] = in_data_reflected[4] ^ in_data_reflected[3] ^ in_data_reflected[1] ^ in_data_reflected[0] ^ crc_now[3] ^ crc_now[24] ^ crc_now[25] ^ crc_now[27] ^ crc_now[28];
    assign crc_next[CRC_BITS-20] = in_data_reflected[6] ^ in_data_reflected[5] ^ in_data_reflected[4] ^ in_data_reflected[2] ^ in_data_reflected[1] ^ in_data_reflected[0] ^ crc_now[4] ^ crc_now[24] ^ crc_now[25] ^ crc_now[26] ^ crc_now[28] ^ crc_now[29] ^ crc_now[30];
    assign crc_next[CRC_BITS-19] = in_data_reflected[7] ^ in_data_reflected[6] ^ in_data_reflected[5] ^ in_data_reflected[3] ^ in_data_reflected[2] ^ in_data_reflected[1] ^ crc_now[5] ^ crc_now[25] ^ crc_now[26] ^ crc_now[27] ^ crc_now[29] ^ crc_now[30] ^ crc_now[31];
    assign crc_next[CRC_BITS-18] = in_data_reflected[7] ^ in_data_reflected[6] ^ in_data_reflected[4] ^ in_data_reflected[3] ^ in_data_reflected[2] ^ crc_now[6] ^ crc_now[26] ^ crc_now[27] ^ crc_now[28] ^ crc_now[30] ^ crc_now[31];
	 assign crc_next[CRC_BITS-17] = in_data_reflected[7] ^ in_data_reflected[5] ^ in_data_reflected[4] ^ in_data_reflected[3] ^ crc_now[7] ^ crc_now[27] ^ crc_now[28] ^ crc_now[29] ^ crc_now[31];
    assign crc_next[CRC_BITS-16] = in_data_reflected[5] ^ in_data_reflected[4] ^ in_data_reflected[0] ^ crc_now[8] ^ crc_now[24] ^ crc_now[28] ^ crc_now[29];
    assign crc_next[CRC_BITS-15] = in_data_reflected[6] ^ in_data_reflected[5] ^ in_data_reflected[1] ^ crc_now[9] ^ crc_now[25] ^ crc_now[29] ^ crc_now[30];
    assign crc_next[CRC_BITS-14] = in_data_reflected[7] ^ in_data_reflected[6] ^ in_data_reflected[2] ^ crc_now[10] ^ crc_now[26] ^ crc_now[30] ^ crc_now[31];
    assign crc_next[CRC_BITS-13] = in_data_reflected[7] ^ in_data_reflected[3] ^ crc_now[11] ^ crc_now[27] ^ crc_now[31];
    assign crc_next[CRC_BITS-12] = in_data_reflected[4] ^ crc_now[12] ^ crc_now[28];
    assign crc_next[CRC_BITS-11] = in_data_reflected[5] ^ crc_now[13] ^ crc_now[29];
    assign crc_next[CRC_BITS-10] = in_data_reflected[0] ^ crc_now[14] ^ crc_now[24];
    assign crc_next[CRC_BITS-9] = in_data_reflected[6] ^ in_data_reflected[1] ^ in_data_reflected[0] ^ crc_now[15] ^ crc_now[24] ^ crc_now[25] ^ crc_now[30];
    assign crc_next[CRC_BITS-8] = in_data_reflected[7] ^ in_data_reflected[2] ^ in_data_reflected[1] ^ crc_now[16] ^ crc_now[25] ^ crc_now[26] ^ crc_now[31];
    assign crc_next[CRC_BITS-7] = in_data_reflected[3] ^ in_data_reflected[2] ^ crc_now[17] ^ crc_now[26] ^ crc_now[27];
    assign crc_next[CRC_BITS-6] = in_data_reflected[6] ^ in_data_reflected[4] ^ in_data_reflected[3] ^ in_data_reflected[0] ^ crc_now[18] ^ crc_now[24] ^ crc_now[27] ^ crc_now[28] ^ crc_now[30];
    assign crc_next[CRC_BITS-5] = in_data_reflected[7] ^ in_data_reflected[5] ^ in_data_reflected[4] ^ in_data_reflected[1] ^ crc_now[19] ^ crc_now[25] ^ crc_now[28] ^ crc_now[29] ^ crc_now[31];
    assign crc_next[CRC_BITS-4] = in_data_reflected[6] ^ in_data_reflected[5] ^ in_data_reflected[2] ^ crc_now[20] ^ crc_now[26] ^ crc_now[29] ^ crc_now[30];
    assign crc_next[CRC_BITS-3] = in_data_reflected[7] ^ in_data_reflected[6] ^ in_data_reflected[3] ^ crc_now[21] ^ crc_now[27] ^ crc_now[30] ^ crc_now[31];
    assign crc_next[CRC_BITS-2] = in_data_reflected[7] ^ in_data_reflected[4] ^ crc_now[22] ^ crc_now[28] ^ crc_now[31];
    assign crc_next[CRC_BITS-1] = in_data_reflected[5] ^ crc_now[23] ^ crc_now[29];
//crc result refelected and xor with 32'hffffffff
	 assign crc_reflected[CRC_BITS-1] = crc_next[CRC_BITS-32] ^ 1'b1;
  	 assign crc_reflected[CRC_BITS-2] = crc_next[CRC_BITS-31] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-3] = crc_next[CRC_BITS-30] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-4] = crc_next[CRC_BITS-29] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-5] = crc_next[CRC_BITS-28] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-6] = crc_next[CRC_BITS-27] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-7] = crc_next[CRC_BITS-26] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-8] = crc_next[CRC_BITS-25] ^ 1'b1;
    assign crc_reflected[CRC_BITS-9] = crc_next[CRC_BITS-24] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-10] = crc_next[CRC_BITS-23] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-11] = crc_next[CRC_BITS-22] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-12] = crc_next[CRC_BITS-21] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-13] = crc_next[CRC_BITS-20] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-14] = crc_next[CRC_BITS-19] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-15] = crc_next[CRC_BITS-18] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-16] = crc_next[CRC_BITS-17] ^ 1'b1;	
	 assign crc_reflected[CRC_BITS-17] = crc_next[CRC_BITS-16] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-18] = crc_next[CRC_BITS-15] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-19] = crc_next[CRC_BITS-14] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-20] = crc_next[CRC_BITS-13] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-21] = crc_next[CRC_BITS-12] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-22] = crc_next[CRC_BITS-11] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-23] = crc_next[CRC_BITS-10] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-24] = crc_next[CRC_BITS-9] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-25] = crc_next[CRC_BITS-8] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-26] = crc_next[CRC_BITS-7] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-27] = crc_next[CRC_BITS-6] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-28] = crc_next[CRC_BITS-5] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-29] = crc_next[CRC_BITS-4] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-30] = crc_next[CRC_BITS-3] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-31] = crc_next[CRC_BITS-2] ^ 1'b1;
	 assign crc_reflected[CRC_BITS-32] = crc_next[CRC_BITS-1] ^ 1'b1;
 
	 always @ (posedge clk or negedge rst_n)
	     begin
		      if(!rst_n)
			      begin
			  	       err <= #1 1'b0;
			      end
		  else if (crc_check)
		      begin
				    if (compare)
					     err <= #1 1'b0;
					 else
					     err <= #1 1'b1;    
			   end			
		  else begin
		      err <= #1 1'b0;
		  end
    end 
	 
	 always @ (posedge clk or negedge rst_n) begin
	     if (!rst_n)
		      begin
				    in_data[((BUS_WIDTH*4)-1):0] <=#1 32'b0;
				end
		  else if ((sof) && (data_v))
		      begin
					 in_data[((BUS_WIDTH*4)-1):0] <=#1 {in_data[((BUS_WIDTH*3)-1):0], data[(BUS_WIDTH-1):0]};
			   end
		  else if ((sof == 1'b0) && (data_v))
		      begin
					 in_data[((BUS_WIDTH*4)-1):0] <=#1 {in_data[((BUS_WIDTH*3)-1):0], data[(BUS_WIDTH-1):0]};
		      end
		  else if ((eof) && (data_v))
		      begin
					 in_data[((BUS_WIDTH*4)-1):0] <=#1 {in_data[((BUS_WIDTH*3)-1):0], data[(BUS_WIDTH-1):0]};
			   end
		  else begin
		      in_data <=#1 in_data;			
		  end
	 end
	 
	 always @ (posedge clk or negedge rst_n) begin
	     if (!rst_n)
		      begin

				end
		  else if ((sof) && (data_v))
		      begin
                crc_now <= #1 INITIAL_CRC;
			   end
		  else if ((sof == 1'b0) && (data_v))
		      begin
                crc_now <= #1 crc_next;
		      end
		  else if ((eof) && (data_v))
		      begin
                crc_now <= #1 crc_next;
			   end
		  else begin
		  
		  end
	 end
	 
	 always @ (posedge clk or negedge rst_n) begin
	     if (!rst_n)
		      begin
					 crc_shift_last_4[(CRC_BITS*4)-1:0] <=#1 128'b0;
				end
		  else if ((sof) && (data_v))
		      begin
					 crc_shift_last_4[(CRC_BITS*4)-1:0] <=#1 {crc_shift_last_4[95:0], crc_reflected[7:0], crc_reflected[15:8], crc_reflected[23:16], crc_reflected[31:24]};
			   end
		  else if ((sof == 1'b0) && (data_v))
		      begin
					 crc_shift_last_4[(CRC_BITS*4)-1:0] <=#1 {crc_shift_last_4[95:0], crc_reflected[7:0], crc_reflected[15:8], crc_reflected[23:16], crc_reflected[31:24]};
		      end
		  else if ((eof) && (data_v))
		      begin
					 crc_shift_last_4[(CRC_BITS*4)-1:0] <=#1 {crc_shift_last_4[95:0], crc_reflected[7:0], crc_reflected[15:8], crc_reflected[23:16], crc_reflected[31:24]};
			   end
		  else begin
            crc_shift_last_4 <=#1 crc_shift_last_4;				
		  end
	 end
endmodule