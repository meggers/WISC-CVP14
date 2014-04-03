`timescale 1 ns / 1 ns

module the_test();
  reg rst;

  wire Clk1, Clk2, V;
  wire [15:0] dataTo, dataFrom, addr; // wrt to DRAM
  
  clock_source clocks(.Clk1(Clk1), .Clk2(Clk2));
  
  CVP14 processor(.Clk1(Clk1), 
                  .Clk2(Clk2), 
                  .Reset(rst), 
                  .DataIn(dataFrom),
                  
                  .Addr(addr),
                  .RD(RD),
                  .WR(WR),
                  .V(V),
                  .dataOut(dataTo));
  
  staticram DRAM(.clk1(Clk1), 
                 .clk2(Clk2),
                 .Addr(addr),
                 .DataIn(dataTo), 
                 .RD(RD), 
                 .WR(WR),
                 
                 .DataOut(dataFrom));
                 
  initial begin
    rst = 1'b1;
    #2;
    rst = 1'b0;
  end
endmodule
