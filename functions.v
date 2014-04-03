function [255:0] VADDfunc;
  input [255:0] op_1, op_2;
  
  parameter maxDimensions = 16,
            floatWidth = 16;
  
  reg [5:0] dimension;
  reg [15:0] vector_1, vector_2;
  
  begin
    for (dimension = 0; dimension < maxDimensions; dimension = dimension + 1) begin
      vector_1 = op_1[floatWidth * dimension +: floatWidth];
      vector_2 = op_2[floatWidth * dimension +: floatWidth];
      
      VADDfunc[floatWidth * dimension +: floatWidth] = float_add(vector_1, vector_2);
    end
  end
  
endfunction

//http://en.wikipedia.org/wiki/Half-precision_floating-point_format
//http://pages.cs.wisc.edu/~smoler/x86text/lect.notes/arith.flpt.html
function float_add;
  input [15:0] float_1, float_2;
  
  parameter exponent_bias   = 5'b01111,
            hidden_bit      = 1'b1;
            
  parameter sign_bit     = 15,
            exponent_msb = 14,
            exponent_lsb = 10, 
            mantissa_msb = 9,
            mantissa_lsb = 0;
            
  reg signed [4:0] exp_1, exp_2, exp_shifted;
  reg signed [5:0] exp_diff;
  
  reg [10:0] mantissa_1, mantissa_2;
  reg [11:0] mantissa_sum;
  
  reg sign;
  reg [3:0] leadingZeros;
  
  begin
    // Step 1a: Subtract exponents 
    exp_1 = float_1[exponent_msb : exponent_lsb] - exponent_bias;
    exp_2 = float_2[exponent_msb : exponent_lsb] - exponent_bias;
    exp_diff = exp_1 - exp_2;
        
    // Step 1b: Introduce hidden bit and align radix
    if (exp_diff < 0) begin      
      exp_shifted = exp_2;
      exp_diff = ~exp_diff + 1; // Convert to positive diff for shifting 
        
      mantissa_1 = {hidden_bit, float_1[mantissa_msb : mantissa_lsb]} >> exp_diff;
      mantissa_2 = {hidden_bit, float_2[mantissa_msb : mantissa_lsb]};
    end else begin
      exp_shifted = exp_1;
        
      mantissa_1 = {hidden_bit, float_1[mantissa_msb : mantissa_lsb]};
      mantissa_2 = {hidden_bit, float_2[mantissa_msb : mantissa_lsb]} >> exp_diff;
      
      $display("mantissa_1 %b", mantissa_1);
      $display("mantissa_2 %b", mantissa_2);
    end
    
    // Step 1c: Account for negative values
    if (float_1[sign_bit] & float_2[sign_bit]) begin
      sign = 1;
    end else if (float_1[sign_bit]) begin
      sign = mantissa_1 > mantissa_2 ? 1 : 0;
      mantissa_1 = ~mantissa_1 + 1;
    end else if (float_2[sign_bit]) begin
      sign = mantissa_2 > mantissa_1 ? 1 : 0;
      mantissa_2 = ~mantissa_2 + 1;
    end else begin
      sign = 0;
    end
      
    // Step 2: Add
    mantissa_sum = mantissa_1 + mantissa_2;
      
    // Step 3: Normalize result
    if (mantissa_sum != 0) begin
      if (mantissa_sum[11]) begin
        mantissa_sum = mantissa_sum >> 1;
        exp_shifted = exp_shifted + 1;
      end else if (~mantissa_sum[10]) begin
        $display("this happened");
        leadingZeros = numLeadingZeros(mantissa_sum[9:0]);
        mantissa_sum = mantissa_sum << leadingZeros;
        exp_shifted = exp_shifted - leadingZeros;
      end
    end
    
    exp_shifted = exp_shifted + exponent_bias;  
    
    // Reassable and return
    $display("Result: %b", {sign, exp_shifted, mantissa_sum[mantissa_msb : mantissa_lsb]});
    float_add = {sign, exp_shifted, mantissa_sum[mantissa_msb : mantissa_lsb]};
  end

endfunction

function [3:0] numLeadingZeros;
  input [9:0] mantissa;
  
  parameter zero_mask  = 10'b1000000000,
            one_mask   = 10'b0100000000,
            two_mask   = 10'b0010000000,
            three_mask = 10'b0001000000,
            four_mask  = 10'b0000100000,
            five_mask  = 10'b0000010000,
            six_mask   = 10'b0000001000,
            seven_mask = 10'b0000000100,
            eight_mask = 10'b0000000010,
            nine_mask  = 10'b0000000001;
            
  parameter zero  = 0,
            one   = 1,
            two   = 2,
            three = 3,
            four  = 4,
            five  = 5,
            six   = 6,
            seven = 7,
            eight = 8,
            nine  = 9,
            ten   = 10;
  
  numLeadingZeros = mantissa & zero_mask  ? zero  :
                    mantissa & one_mask   ? one   :
                    mantissa & two_mask   ? two   :
                    mantissa & three_mask ? three :
                    mantissa & four_mask  ? four  :
                    mantissa & five_mask  ? five  :
                    mantissa & six_mask   ? six   :
                    mantissa & seven_mask ? seven :
                    mantissa & eight_mask ? eight :
                    mantissa & nine_mask  ? nine  : ten;
                    
endfunction

function [15:0] ScalarLoadLow;
   input [15:0] op_1; // Contents of the register to be written to
   input [7:0] op_2;  // Immediate Value to be loaded
   
   reg [15:0] masked;

 begin
   masked = op_1 & 16'hFF00; // Mask off lower bits
   ScalarLoadLow = masked | {8'h00, op_2};
 end
endfunction


function [15:0] ScalarLoadHigh;
   input [15:0] op_1; // Contents of the register to be written to
   input [7:0] op_2;  // Immediate Value to be loaded

   reg [15:0] masked;

begin
  masked = op_1 & 16'h00FF; // Mask off upper bits
  ScalarLoadHigh = masked | {op_2, 8'h00};
end

endfunction