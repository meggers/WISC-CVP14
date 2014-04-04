/* Generates and outputs the two phase overlapping clock */

`timescale 1 ns / 1 ns

module clock_source (Clk1, Clk2);
  output reg Clk1, Clk2;
  
  initial begin
    Clk1 = 1'b0;
    Clk2 = 1'b0;
  end
  
  // Clk 1
  always begin
    #1 Clk1 = 1'b1;
    #1 Clk1 = 1'b0;
    #2;
  end
  
  // Clk 2
  always begin
    #3 Clk2 = 1'b1;
    #1 Clk2 = 1'b0; 
  end
endmodule