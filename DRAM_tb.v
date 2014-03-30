module DRAM_tb ();
  wire Clk1, Clk2, RD, WR;
  wire [15:0] DataOut, DataIn, Addr; 
  
  clock_source clocks(.Clk1(Clk1), .Clk2(Clk2));
  
  DRAM memory(.DataOut(DataOut), 
              .DataIn(DataOut), 
              .Addr(Addr), 
              .Clk1(Clk1), 
              .Clk2(Clk2), 
              .RD(RD), .WR(WR));
  
  initial begin
    
  end

endmodule
