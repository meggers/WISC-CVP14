module ALU ();

endmodule

module VADD (clk, op_1, op_2, sum);
  
  input   clk;
  input  [255:0] op_1, op_2;
  output [255:0] sum;
  
  reg [5:0] dimension;
  
  localparam maxDimensions   = 16,
             dimensionSize   = 16,
             exponent_bias   = 15;
             
  localparam sign_offset     = 0,
             exponent_offset = 1,
             mantissa_offset = 6;
             
  localparam sign_length     = 1,
             exponent_length = 5,
             mantissa_length = 10;
  
  reg [15:0] vector_1 [15:0];
  reg [15:0] vector_2 [15:0];
  
  reg [15:0] vector_sum [15:0];
  
  reg [4:0] exp_1, exp_2;
  reg signed [5:0] exp_diff;
  
  reg [4:0] exp_1_shifted, exp_2_shifted;
  
  reg [9:0] mantissa_1_shifted, mantissa_2_shifted;
  
  always @(posedge clk) begin
    //sum <= vector_sum;
  end
  
  always @(op_1, op_2) begin
    for (dimension = 0; dimension < maxDimensions; dimension = dimension + 1) begin
      vector_1[dimension] <= op_1[dimensionSize * dimension +: dimensionSize];
      vector_2[dimension] <= op_2[dimensionSize * dimension +: dimensionSize];
      
      exp_1 <= vector_1[dimension][dimensionSize - exponent_offset -: exponent_length] - exponent_bias;
      exp_2 <= vector_2[dimension][dimensionSize - exponent_offset -: exponent_length] - exponent_bias;
      exp_diff = exp_1 - exp_2;
        
      if (exp_diff > 0) begin
        exp_1_shifted <= exp_1;
        exp_2_shifted <= exp_1;
        
        mantissa_1_shifted <= vector_1[dimension][dimensionSize - mantissa_offset -: mantissa_length];
        mantissa_2_shifted <= vector_2[dimension][dimensionSize - mantissa_offset -: mantissa_length] >> exp_diff;
      end else if (exp_diff < 0) begin
        exp_1_shifted <= exp_2;
        exp_2_shifted <= exp_2;
        
        mantissa_1_shifted <= vector_1[dimension][dimensionSize - mantissa_offset -: mantissa_length] >> exp_diff;
        mantissa_2_shifted <= vector_2[dimension][dimensionSize - mantissa_offset -: mantissa_length];
      end else begin
        exp_1_shifted <= exp_1;
        exp_2_shifted <= exp_2;
        
        mantissa_1_shifted <= vector_1[dimension][dimensionSize - mantissa_offset -: mantissa_length];
        mantissa_2_shifted <= vector_2[dimension][dimensionSize - mantissa_offset -: mantissa_length]; 
      end
      
    end
  end
  
endmodule