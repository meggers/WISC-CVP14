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
//http://users-tima.imag.fr/cis/guyot/Cours/Oparithm/english/Flottan.htm
function float_add;
  input [15:0] float_1, float_2;
  
  parameter exponent_bias   = 5'b01111,
            hidden_bit      = 1'b1,
            guard_bit       = 1'b0,
            round_bit       = 1'b0;
            
  parameter sign_bit     = 15,
            exponent_msb = 14,
            exponent_lsb = 10, 
            mantissa_msb = 9,
            mantissa_lsb = 0,
            ulp_bit      = 2;
            
  reg signed [4:0] exp_1, exp_2, exp_shifted;
  reg signed [5:0] exp_diff;
  
  reg [12:0] mantissa_1, mantissa_2; // Includes hidden, guard, and round bits
  reg [13:0] mantissa_sum; // Includes overflow, guard, and round bits
  
  reg sign, ulp;
  reg [3:0] leadingZeros;
  
  begin
    // Step 1a: Subtract exponents 
    exp_1 = float_1[exponent_msb : exponent_lsb] - exponent_bias;
    exp_2 = float_2[exponent_msb : exponent_lsb] - exponent_bias;
    exp_diff = exp_1 - exp_2;
        
    // Step 1b: Construct mantissas
    mantissa_1 = {hidden_bit, float_1[mantissa_msb : mantissa_lsb], guard_bit, round_bit};
    mantissa_2 = {hidden_bit, float_2[mantissa_msb : mantissa_lsb], guard_bit, round_bit};    
        
    // Step 1c: Introduce hidden bit and align radix
    // Step 2: Add
    if (exp_diff < 0) begin      
      exp_shifted = exp_2;
      exp_diff = ~exp_diff + 1; // Convert to positive diff for shifting      
      mantissa_1 = mantissa_1 >> exp_diff; 
      
      sign = float_2[sign_bit];
      mantissa_sum = (float_1[sign_bit] ~^ float_2[sign_bit]) ? mantissa_1 + mantissa_2 : mantissa_2 - mantissa_1;
    end else begin
      exp_shifted = exp_1;
      mantissa_2 = mantissa_2 >> exp_diff;
            
      sign = float_1[sign_bit];
      mantissa_sum = (float_1[sign_bit] ~^ float_2[sign_bit]) ? mantissa_1 + mantissa_2 : mantissa_1 - mantissa_2;  
    end
      
    // Step 3: Normalize result
    ulp = mantissa_sum[ulp_bit];
    if (mantissa_sum[11]) begin
      mantissa_sum = mantissa_sum >> 1;
      exp_shifted = exp_shifted + 1;
    end else if (~mantissa_sum[10]) begin
      leadingZeros = numLeadingZeros(mantissa_sum[9:0]);
      mantissa_sum = mantissa_sum << leadingZeros;
      exp_shifted = exp_shifted - leadingZeros;
    end
    
    exp_shifted = exp_shifted + exponent_bias;  
    
    // Step 4: Round Result
    //mantissa_sum 
    
    // Reassable and return
    $display("Result: %b", {sign, exp_shifted, mantissa_sum[mantissa_msb : mantissa_lsb]});
    float_add = {sign, exp_shifted, mantissa_sum[mantissa_msb : 2]};
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
