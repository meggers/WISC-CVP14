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
  
  // Special Case Params
  parameter inf_exponent =  5'b11111,
            inf_mantissa = 10'b0;
  
  // Hidden bit Params
  parameter hidden_bit_high = 1'b1,
            hidden_bit_low  = 1'b0;
            
  // Floating point Params
  parameter sign_bit     = 15,
            exponent_msb = 14,
            exponent_lsb = 10, 
            mantissa_msb = 9,
            mantissa_lsb = 0;
            
  // Rounding Params
  parameter GRS_zero_fill = 15'b0,
            overflow_bit  = 26,
            hidden_bit    = 25,
            sum_msb       = 24,
            sum_lsb       = 15,
            guard_bit     = 14,
            round_bit     = 13,
            sticky_msb    = 12,
	          sticky_lsb    = 0;
            
  reg [4:0] exp_1, exp_2, exp_shifted, exp_diff;
  
  reg [25:0] mantissa_1, mantissa_2; // [1 Hidden bit, 10 Mantissa bits, 1 Guard bit, 1 Round bit, 13 Sticky bits]
  reg [26:0] mantissa_sum;           // [1 Overflow bit, 1 Hidden Bit, 10 Mantissa bits, 1 Guard bit, 1 Round bit, 13 Sticky bits]

  reg sign, overflow;
  reg [3:0] leadingZeros;
  
  begin
    // Set our overflow flag
    overflow = 0;
    
    // Step 1a: Construct exponents 
    exp_1 = float_1[exponent_msb : exponent_lsb];
    exp_2 = float_2[exponent_msb : exponent_lsb];
    
    // Check for infinity
    if (exp_1 == inf_exponent) begin
      float_add = float_1;
    end else if (exp_2 == inf_exponent) begin
      float_add = float_2;
    end else begin  
      
      // Step 1b: Subtract exponents
      exp_diff = exp_1 - exp_2;
        
      // Step 1c: Construct mantissas (for both normalized and denormalized numbers)
      mantissa_1 = {(|exp_1 ? hidden_bit_high : hidden_bit_low), float_1[mantissa_msb : mantissa_lsb], GRS_zero_fill};
      mantissa_2 = {(|exp_2 ? hidden_bit_high : hidden_bit_low), float_2[mantissa_msb : mantissa_lsb], GRS_zero_fill};   
        
      // Step 1d: Align radix
      // Step 2: Add
      if (exp_2 > exp_1) begin      
        exp_shifted = exp_2;
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
      if (~|mantissa_sum[overflow_bit : sum_lsb]) begin
        exp_shifted = 0;
        mantissa_sum = mantissa_sum;
      end else if (mantissa_sum[overflow_bit]) begin // If there is overflow of mantissa, shift left
        mantissa_sum = mantissa_sum >> 1;
        exp_shifted  = exp_shifted + 1;
        if (&exp_shifted) begin // Overflow of exponent
          overflow = 1;
        end else begin
          overflow = overflow;
        end
      end else if (~mantissa_sum[hidden_bit]) begin // Else if hidden bit is 0
        leadingZeros = numLeadingZeros(mantissa_sum[sum_msb : sum_lsb]);
        mantissa_sum[hidden_bit : round_bit] = mantissa_sum[hidden_bit : round_bit] << leadingZeros;
        exp_shifted  = exp_shifted - leadingZeros;
      end else begin
        mantissa_sum = mantissa_sum;
        exp_shifted  = exp_shifted;
        overflow = overflow;
      end
    
      // Step 4: Round to nearest even
      if (~overflow) begin
        if (mantissa_sum[guard_bit] & (|mantissa_sum[round_bit : sticky_lsb] | mantissa_sum[sum_lsb])) begin
          mantissa_sum = mantissa_sum + 1;
          exp_shifted  = |mantissa_sum[sum_msb : sum_lsb] ? exp_shifted : exp_shifted + 1; // Overflow of Mantissa
          if (&exp_shifted) begin // Overflow of exponent
            overflow = 1;
          end else begin
            overflow = overflow;
          end
        end
      end
    
      // Assemble and return
      if (~overflow) begin
        $display("Result: %b", {sign, exp_shifted, mantissa_sum[sum_msb : sum_lsb]});
        float_add = {sign, exp_shifted, mantissa_sum[sum_msb : sum_lsb]};
      end else begin
        $display("Result: %b", {sign, inf_exponent, inf_mantissa});
        float_add = {sign, inf_exponent, inf_mantissa};
      end
      
    end
    
  end

endfunction

function [3:0] numLeadingZeros;
  input [10:0] mantissa;
            
  casex(mantissa)
    11'b1xxxxxxxxxx: numLeadingZeros = 4'd0;
    11'b01xxxxxxxxx: numLeadingZeros = 4'd1;
    11'b001xxxxxxxx: numLeadingZeros = 4'd2;
    11'b0001xxxxxxx: numLeadingZeros = 4'd3;
    11'b00001xxxxxx: numLeadingZeros = 4'd4;
    11'b000001xxxxx: numLeadingZeros = 4'd5;
    11'b0000001xxxx: numLeadingZeros = 4'd6;
    11'b00000001xxx: numLeadingZeros = 4'd7;
    11'b000000001xx: numLeadingZeros = 4'd8;
    11'b0000000001x: numLeadingZeros = 4'd9;
    11'b00000000001: numLeadingZeros = 4'd10;
    default:         numLeadingZeros = 4'd0;
  endcase
                    
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
