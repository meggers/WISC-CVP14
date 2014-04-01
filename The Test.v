module the_test();
  wire Clk1, Clk2;
  
  clock_source clocks(.Clk1(Clk1), .Clk2(Clk2));
  
  CVP14 processor();
  
  staticram DRAM();
endmodule
