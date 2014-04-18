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
  
  parameter hidden_bit   = 1'b1;
  parameter sign_bit     = 15,
            exponent_msb = 14,
            exponent_lsb = 10, 
            mantissa_msb = 9,
            mantissa_lsb = 0,
            overflow     = 11,
            hidden       = 10,
            guard_bit    = 2,
            round_bit    = 1,
            sticky_bit   = 0;
            
  reg signed [4:0] exp_1, exp_2, exp_shifted;
  reg signed [5:0] exp_diff;
  
  reg [10:0] mantissa_1, mantissa_2; // Includes hidden bit
  reg [11:0] mantissa_sum;           // Includes hidden, overflow bits
  
  reg [2:0]  GRS; // Guard, Round, Sticky  
  
  reg sign;
  reg [3:0] leadingZeros;
  
  begin
    // Step 1a: Construct and subtract exponents 
    exp_1 = float_1[exponent_msb : exponent_lsb];
    exp_2 = float_2[exponent_msb : exponent_lsb];
    exp_diff = exp_1 - exp_2;
        
    // Step 1b: Construct mantissas
    mantissa_1 = {hidden_bit, float_1[mantissa_msb : mantissa_lsb]};
    mantissa_2 = {hidden_bit, float_2[mantissa_msb : mantissa_lsb]};    
        
    // Step 1c: Align radix
    // Step 2: Add
    if (exp_diff < 0) begin      
      exp_shifted = exp_2;
      exp_diff = ~exp_diff + 1; // Convert to positive diff for shifting
      GRS[sticky_bit] = |mantissa_1[exp_diff:0];      
      {mantissa_1, GRS[guard_bit:round_bit]} = mantissa_1 >> exp_diff;
      
      sign = float_2[sign_bit];
      mantissa_sum = (float_1[sign_bit] ~^ float_2[sign_bit]) ? mantissa_1 + mantissa_2 : mantissa_2 - mantissa_1;
    end else begin
      exp_shifted = exp_1;
      GRS[sticky_bit] = |mantissa_2[exp_diff - 2:0];
      {mantissa_2, GRS[guard_bit:round_bit]} = mantissa_2 >> exp_diff;
            
      sign = float_1[sign_bit];
      mantissa_sum = (float_1[sign_bit] ~^ float_2[sign_bit]) ? mantissa_1 + mantissa_2 : mantissa_1 - mantissa_2;  
    end
      
    // Step 3: Normalize result
    leadingZeros = numLeadingZeros(mantissa_sum[mantissa_msb:mantissa_lsb]);
    if (mantissa_sum[overflow]) begin              // If there is overflow, shift left
      GRS[sticky_bit] = GRS[sticky_bit] | GRS[round_bit];
      {mantissa_sum, GRS[guard_bit:round_bit]} = mantissa_sum >> 1;
      exp_shifted  = exp_shifted + 1;
    end else if (~mantissa_sum[hidden]) begin      // Else if hidden bit is 0
      {mantissa_sum, GRS[guard_bit:round_bit]} = {mantissa_sum, GRS} << leadingZeros;
      exp_shifted  = exp_shifted - leadingZeros;
    end else begin                                 // Otherwise already normalized
      GRS = GRS;
      mantissa_sum = mantissa_sum;
      exp_shifted  = exp_shifted;
    end
    
    // Step 4: Round to nearest even
    if (GRS[guard_bit] & (|GRS[round_bit : sticky_bit] | mantissa_sum[mantissa_lsb])) begin
      mantissa_sum = mantissa_sum + 1;
      exp_shifted  = |mantissa_sum[mantissa_msb : mantissa_lsb] ? exp_shifted : exp_shifted + 1;
    end else begin
      mantissa_sum = mantissa_sum;
      exp_shifted  = exp_shifted;
    end
    
    // Assemble and return
    $display("Result: %b", {sign, exp_shifted, mantissa_sum[mantissa_msb : mantissa_lsb]});
    float_add = {sign, exp_shifted, mantissa_sum[mantissa_msb : mantissa_lsb]};
  end

endfunction

function [3:0] numLeadingZeros;
  input [9:0] mantissa;
            
  casex(mantissa)
    10'b1xxxxxxxxx: numLeadingZeros = 4'd0;
    10'b01xxxxxxxx: numLeadingZeros = 4'd1;
    10'b001xxxxxxx: numLeadingZeros = 4'd2;
    10'b0001xxxxxx: numLeadingZeros = 4'd3;
    10'b00001xxxxx: numLeadingZeros = 4'd4;
    10'b000001xxxx: numLeadingZeros = 4'd5;
    10'b0000001xxx: numLeadingZeros = 4'd6;
    10'b00000001xx: numLeadingZeros = 4'd7;
    10'b000000001x: numLeadingZeros = 4'd8;
    10'b0000000001: numLeadingZeros = 4'd9;
    default:        numLeadingZeros = 4'd0;
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
