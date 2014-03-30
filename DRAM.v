module DRAM(output[15:0] DataOut, input [15:0] Addr, input Clk1,
  input Clk2, input [15:0] DataIn, input RD, input WR);
  
  reg latchedRD, latchedWR;
  reg [15:0] latchedAddr, latchedDataOut, latchedDataIn;
  reg [15:0] mem [15:0]; // The memory structure
  
  assign DataOut = latchedDataOut;
  
  always @(posedge Clk1) begin
    latchedAddr <= Addr;
    
    if(latchedRD)
      latchedDataOut <= mem[latchedAddr];
    if(latchedWR)
      mem[latchedAddr] <= latchedDataIn;
  end
  
  always @(posedge Clk2) begin
    latchedRD <= RD;
    latchedWR <= WR;
    latchedDataIn <= DataIn;
  end
endmodule
