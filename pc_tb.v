module pc_tb ();
  wire clk1, clk2;
  wire[15:0] iAddr;
  reg RST;
  reg [15:0] nAddr;
  
  clock_source clocks(.Clk1(clk1), .Clk2(clk2));
  PC pc(.Clk1(clk1), .Clk2(clk2), .rst(RST), .iAddr(iAddr), .nextAddr(nAddr));
  
  initial begin
    RST = 1'b0;
    nAddr = 16'h0000;
    #1;
    nAddr = 16'hCAFE;
    #2;
    nAddr = 16'hF00D;
    #3;
    nAddr = 16'h5555;
    #4;
    nAddr = 16'h3333;
    #5;
    RST = 1'b1;
  end
endmodule
