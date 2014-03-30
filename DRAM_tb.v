module DRAM_tb ();
  wire Clk1, Clk2;
  wire [15:0] DataOut;
  reg RD, WR;
  reg [15:0] DataIn, Addr; 
  
  clock_source clocks(.Clk1(Clk1), .Clk2(Clk2));
  
  DRAM memory(.DataOut(DataOut), 
              .DataIn(DataIn), 
              .Addr(Addr), 
              .Clk1(Clk1), 
              .Clk2(Clk2), 
              .RD(RD), .WR(WR));
  
  initial begin
    Addr = 16'h5555;
    DataIn = 16'hF00D;
    WR = 1'b1;
    
    #5;
    WR = 1'b0;
    RD = 1'b1;
  end

endmodule
