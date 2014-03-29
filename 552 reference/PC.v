module PC(clk, rst_n, hlt, iaddr, nextAddr);
  
	input [15:0] nextAddr;
  input clk, rst_n, hlt;
  output reg [15:0] iaddr;

  always @(posedge clk or negedge rst_n)
    if(!rst_n)
      iaddr <= 16'h0000;
    else if (!hlt)
      iaddr <= nextAddr;
	 	else
			iaddr <= iaddr;
endmodule  