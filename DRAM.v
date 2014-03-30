module DRAM(output[15:0] DataOut, input [15:0] Addr, input Clk1, input Clk2, input [15:0] DataIn, input RD, input WR);
  
  [15:0] mem [15:0]; // The memory structure
  
  always @(posedge Clk1) begin
    if(RD)
      DataOut = mem[Addr]
  end
  
  always @(posedge Clk2) begin
    if(WR)
      
  end
endmodule
