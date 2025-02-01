// Code your design here
module uart_top(clk,reset,rd_en,wr_en,d_in,d_out,tx_full,rx_empty,tx,rx);
input clk,reset,wr_en;
input rd_en,rx;  
input [7:0]d_in;
output tx;
output logic [7:0]d_out;
output logic rx_empty;
output logic tx_full;
logic [10:0]dvsr;
assign dvsr=11'd27;
logic  [7:0]ff_dout,d_out_rx;
logic tx_done,empty,done_rx;
logic baud_trig_rx,baud_trig_tx;
b_clk   b_c(clk,reset,dvsr,baud_trig_tx,baud_trig_rx);
uart_tx  tx1(clk,reset,empty,baud_trig_tx,ff_dout,tx_done,tx); 
uart_rx rx1(clk,reset,rx,done_rx,d_out_rx,baud_trig_rx);
fifo rx_ff(clk,reset,done_rx,rd_en,d_out_rx,d_out,rx_empty,fifo_full);
fifo  tx_ff(clk,reset,wr_en,tx_done,d_in,ff_dout,empty,tx_full);
endmodule

module b_clk(clk,rst,dvsr,baud_trig_tx,baud_trig_rx);
input clk,rst;
input logic [10:0]dvsr;
output logic baud_trig_tx,baud_trig_rx;
reg [10:0]b_reg_tx,b_next_tx;
reg [10:0]b_reg_rx,b_next_rx;

always_ff@(posedge clk, posedge rst) begin 
if(rst==1'b1)
b_reg_tx<=1'b0;
else
b_reg_tx<=b_next_tx;
end
endmodule

module uart_tx(clk,rst,wr_en,baud_trig,d_in,done,tx);
input logic clk,rst,wr_en;
input logic [7:0] d_in;
output logic tx,done;
input logic baud_trig;
logic wr_en_reg;
logic parity;
logic [9:0] d_reg;
logic tx_reg,done_reg;
localparam start_bit=1'b0, stop_bit=1'b1;
typedef enum {idel_state,start,data_f_state,stop}state;
state pr_st,nx_st;
logic [3:0]count;
assign parity=^d_in;   
always_ff @(posedge clk, posedge rst)
begin 
if(rst==1'b1)
pr_st<=idel_state;
else 
pr_st<=nx_st;
end

assign tx=tx_reg;
assign done=done_reg;

always_latch 
begin 
case(pr_st)
idel_state: 
begin 
tx_reg=1'b1;
done_reg=1'b0;
d_reg=8'd0;
count=4'd0;
nx_st=stop; 
end

stop: 
begin 
	tx_reg=1'b1;
  	done_reg=1'b0;
    if(wr_en_reg==1'b1)
	begin
    d_reg={parity,d_in,1'b1};
    $display("%b",d_reg);
    nx_st=start;
	end
else if(wr_en_reg==1'b0)
nx_st=stop;
end

start: 
begin
if(baud_trig==1'b1) begin
	tx_reg=1'b0;
	nx_st=data_f_state;
end
end
data_f_state:
begin
	if(baud_trig==1'b1)
	begin  
        	tx_reg=d_reg[9];
			d_reg=d_reg<<1;
			count=count+1;
    	if( count==4'd11)
			begin 
			count=4'd0;
          	done_reg=1'b1; 
            tx_reg=1'b1;
            nx_st=stop;
	     	end
	end
	else 
	nx_st=data_f_state;
end
endcase 
 end 
      
  always_ff@(posedge clk)
    begin 
      if(rst==1'b1) 
      wr_en_reg<=1'b0;  
      else 
      wr_en_reg<=wr_en;
       end
endmodule


module uart_rx(clk,rst,rx,done,d_out,baud_trig);
input logic clk,rst;
input logic  rx;
output logic [7:0]d_out;
output  logic done;
input logic baud_trig;
logic in_parity;
logic [10:0] d_reg;
logic done_reg;
localparam start_bit=1'b0, stop_bit=1'b1;
typedef enum {idel_state,start,data_f_state}state;
state pr_st,nx_st;
logic [3:0]count,count_reg;

always_ff @(posedge clk, posedge rst)
begin 
if(rst==1'b1)
pr_st<=idel_state;
else 
pr_st<=nx_st;
end
  
assign d_out=(done==1'b1)?d_reg[8:1]:8'hff;
assign done=(done_reg==1'b1); 

always_comb  begin 
case(pr_st)
idel_state: 
begin
nx_st=start;
end  
start:  begin
if(rx==1'b0)  nx_st=data_f_state;	
else 	
nx_st=start;
end
data_f_state:
begin
if(done_reg==1'b1)
nx_st=start;
else
nx_st=data_f_state;
end 
endcase end

always@(posedge clk) begin
case(pr_st)
idel_state :begin 
d_reg=11'b11111111111;
count<=4'd0;
end
  
start: begin  
d_reg=11'b11111111111;
count<=4'd0; 
d_reg[0]=rx;
end

data_f_state: begin
if(baud_trig==1'b1)
begin 
d_reg=d_reg<<1;
d_reg[0]=rx;
count<=count_reg;    
end end
endcase end 
  
assign count_reg=(count==4'd11||pr_st==2'd1)?4'd0:count+1'b1; 
assign done_reg=(count_reg==4'd11);  
assign in_parity=^d_reg[8:1];
 
endmodule

module fifo(clk,reset,wr_en,rd_en,d_in,d_out,fifo_empty,fifo_full);
input clk,reset,wr_en,rd_en;
input [7:0]d_in;
output logic [7:0]d_out;
output logic fifo_empty,fifo_full;
integer i;

logic [4:0] wr_ptr,rd_ptr;
reg [7:0] fifo_reg [0:15];
always @(posedge clk) 
begin 
if (reset==1'b1) begin
  for (i=0;i<16;i=i+1) begin 
    fifo_reg[i][7:0]=8'b0;
	end
	wr_ptr=5'd0;
	end
else
begin 
  if(wr_en==1'b1 && fifo_full==1'b0)   
        begin 
       fifo_reg[wr_ptr][7:0]=d_in[7:0];
		wr_ptr=wr_ptr+1'b1;
		if(wr_ptr>5'd15)
			wr_ptr=5'd0;
        end
end
end

always@(posedge clk)
begin
if(reset==1'b1) begin
rd_ptr=5'd0;
d_out=8'b00000000; 
end

else
begin
  if(rd_en==1'b1 && fifo_empty==1) 
	begin
		
	d_out=fifo_reg[rd_ptr];
    rd_ptr=rd_ptr+1'b1;
      if(rd_ptr>5'd15)
          rd_ptr=5'd0;
    end

end
end
 
assign fifo_empty=(rd_ptr==wr_ptr)?1'b0:1'b1;
assign fifo_full=(rd_ptr>wr_ptr)?(((rd_ptr-wr_ptr)==1)?1'b1:1'b0):(((wr_ptr-rd_ptr)>=5'd15)?1'b1:1'b0);

  
endmodule