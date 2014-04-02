module ALU ();

/* Vector Add */
function [255:0] VADDfunc;
  
  input [255:0] op_1, op_2;
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
  
  reg [4:0] exp_shifted;
  
  reg [9:0] mantissa_1_shifted, mantissa_2_shifted;
  
  reg [10:0] mantissa_sum;
  
  begin
    for (dimension = 0; dimension < maxDimensions; dimension = dimension + 1) begin
      vector_1[dimension] = op_1[dimensionSize * dimension +: dimensionSize];
      vector_2[dimension] = op_2[dimensionSize * dimension +: dimensionSize];
      
      exp_1 = vector_1[dimension][dimensionSize - exponent_offset -: exponent_length] - exponent_bias;
      exp_2 = vector_2[dimension][dimensionSize - exponent_offset -: exponent_length] - exponent_bias;
      exp_diff = exp_1 - exp_2;
        
      if (exp_diff > 0) begin
        exp_shifted = exp_1;
        
        mantissa_1_shifted = vector_1[dimension][dimensionSize - mantissa_offset -: mantissa_length];
        mantissa_2_shifted = vector_2[dimension][dimensionSize - mantissa_offset -: mantissa_length] >> exp_diff;
      end else if (exp_diff < 0) begin
        exp_shifted = exp_2;
        
        mantissa_1_shifted = vector_1[dimension][dimensionSize - mantissa_offset -: mantissa_length] >> exp_diff;
        mantissa_2_shifted = vector_2[dimension][dimensionSize - mantissa_offset -: mantissa_length];
      end else begin
        exp_shifted = exp_1;
        
        mantissa_1_shifted = vector_1[dimension][dimensionSize - mantissa_offset -: mantissa_length];
        mantissa_2_shifted = vector_2[dimension][dimensionSize - mantissa_offset -: mantissa_length]; 
      end
      
      mantissa_sum = mantissa_1_shifted + mantissa_2_shifted;
      
      if (mantissa_sum[10]) begin
        mantissa_sum = mantissa_sum >> 1;
        exp_shifted = exp_shifted >> 1;
      end
      
      vector_sum[dimension] = {1'b0, exp_shifted, mantissa_sum[9:0]};
    end
  
    for (dimension = 0; dimension < maxDimensions; dimension = dimension + 1) begin 
      VADDfunc[dimensionSize * dimension +: dimensionSize] = vector_sum[dimension];
    end
  end
  
endfunction

/* Scalar Load Low */
function [15:0] SLL;
  input [15:0] op_1; // Contents of the register to be written to
  input [8:0] op_2;  // Immediate Value to be loaded
  
  reg [15:0] masked;
  
begin
  masked = op_1 & 16'hFF00; // Mask off lower bits
  
  SLL = masked | {8'h00, op_2};
end

endfunction

/* Scalar Load High */
function [15:0] SLH;
  input [15:0] op_1; // Contents of the register to be written to
  input [8:0] op_2;  // Immediate Value to be loaded
  
  reg [15:0] masked;
  
begin
  masked = op_1 & 16'h00FF; // Maske off upper bits
  
  SLH = masked | {op_2, 8'h00};
end

endfunction

endmodule