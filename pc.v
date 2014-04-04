module PC(Clk1, Clk2, rst, next, iAddr, nextAddr);
  input Clk1, Clk2, rst, next;
  input [15:0] nextAddr;
  
  output reg [15:0] iAddr;
  
  always @(posedge Clk1, posedge Clk2)
    if(rst)
      iAddr <= 16'h0000;
    else if(next)
      iAddr <= nextAddr;
    else
      iAddr <= iAddr; 
endmodule
