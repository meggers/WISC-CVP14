module ALU ();

endmodule

module VADD (clk, op_1, op_2, sum);
  
  input   clk;
  input  [255:0] op_1, op_2;
  output [255:0] sum;
  
  reg [4:0] dimension;
  
  localparam maxDimensions = 15;
  
  always @(posedge clk) begin
    for (dimension = 0; dimension <= maxDimensions; dimension = dimension + 1) begin
      
    end
  end
  
endmodule