module ALU ();

endmodule

module VADD (clk, op_1, op_2, sum);
  
  input   clk;
  input  [255:0] op_1, op_2;
  output [255:0] sum;
  
  reg [5:0] dimension;
  
  localparam maxDimensions = 16,
             dimensionSize = 16;
  
  reg [15:0] vector_1 [15:0];
  reg [15:0] vector_2 [15:0];
  
  reg [15:0] vector_sum [15:0];
  
  always @(posedge clk) begin
    sum <= vector_sum;
  end
  
  always @(op_1, op_2) begin
    for (dimension = 0; dimension < maxDimensions; dimension = dimension + 1) begin
      vector_1[dimension] <= op_1[dimensionSize * dimension +: dimensionSize];
      vector_2[dimension] <= op_2[dimensionSize * dimension +: dimensionSize];
      
    end
  end
  
endmodule