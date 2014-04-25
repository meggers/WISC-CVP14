function [255:0] SMULfunc;
  input [255:0] op_1;
  input [15:0] scalar;
  
  parameter maxDimensions = 16,
            floatWidth = 16;
  
  reg [5:0] dimension;
  reg [15:0] vector;
  
  begin
    for (dimension = 0; dimension < maxDimensions; dimension = dimension + 1) begin
      vector = op_1[floatWidth * dimension +: floatWidth];
      
      SMULfunc[floatWidth * dimension +: floatWidth] = float_mult(vector, scalar);
    end
  end
  
endfunction

function [15:0] float_mult;
  input [15:0] float_1, float_2;
  
  parameter sign_bit     = 15,
            exponent_msb = 14,
            exponent_lsb = 10, 
            mantissa_msb = 9,
            mantissa_lsb = 0,
            overflow     = 21,
            hidden       = 20,
            exponent_bias   = 5'b01111,
            hidden_bit      = 1'b1;
  
  reg [4:0] exp_1, exp_2;
  reg [5:0] exp_sum;
  
  reg [10:0] mantissa_1, mantissa_2; // Includes hidden bit
  reg [21:0] mantissa_prod;
  
  reg sign;
  reg [3:0] leadingZeros;
  reg [1:0] signs;
  
  begin
    //Step 0: check for 0s
    exp_1 = float_1[exponent_msb : exponent_lsb];
    exp_2 = float_2[exponent_msb : exponent_lsb];
    mantissa_1 = {hidden_bit, float_1[mantissa_msb : mantissa_lsb]};
    mantissa_2 = {hidden_bit, float_2[mantissa_msb : mantissa_lsb]};
    if((exp_1 != 0 && mantissa_1[9:0] !=0) || (exp_2 != 0 && mantissa_2[9:0])) begin
      //Step 1: xor the sign bits
      signs[1] = float_1[sign_bit];
      signs[0] = float_2[sign_bit];
      sign = ^(signs);
    
      mantissa_prod = mantissa_1 * mantissa_2;
      //Step 2: Add the exponents
      if (mantissa_prod[overflow]) begin
        mantissa_prod = mantissa_prod >> 1;
        if(exp_1>exponent_bias)begin
          exp_1 = exp_1 - exponent_bias;
          if(exp_2>exponent_bias)begin
            exp_2 = exp_2 - exponent_bias;
            exp_sum = exp_1 + exp_2+1;
          end else begin
            exp_sum = exp_1 - exp_2;
          end
        end else begin
          if(exp_2>exponent_bias)begin
            exp_2 = exp_2 - exponent_bias;
            exp_sum = exp_2 - exp_1;
          end else begin
            exp_sum = 6'b110001;
          end
        end
      end else begin
        if(exp_1>exponent_bias)begin
          exp_1 = exp_1 - exponent_bias;
          if(exp_2>exponent_bias)begin
            exp_2 = exp_2 - exponent_bias;
            exp_sum = exp_1 + exp_2;
          end else begin
            exp_sum = exp_1 - exp_2;
          end
        end else begin
          if(exp_2>exponent_bias)begin
            exp_2 = exp_2 - exponent_bias;
            exp_sum = exp_2 - exp_1;
          end else begin
            exp_sum = 6'b110001;
          end
        end
      end
    end else begin
      sign = 0;
      exp_sum = 6'b010001;
      mantissa_prod = 0;
    end 
    // Step 5: Put it back together
    exp_sum = exp_sum + exponent_bias;
    if (exp_sum[5]) //if the addition has overflowed
        exp_sum[4:0] = 5'b11111;
    float_mult = {sign, exp_sum[4:0], mantissa_prod[19 : 10]};
  end
  
endfunction


/*
function [10:0] MULTfunc;
  parameter width=10,
            N = 10/2;
            
  input[width-1:0]x, y;
  
  reg [2:0] cc[N-1:0];
  reg [width:0] pp[N-1:0];
  reg [width+width-1:0] spp[N-1:0];
  reg [width+width-1:0] prod;
  reg [width:0] inv_x;
  integer kk,ii;
  
  begin
    inv_x = {~x[width-1],~x}+1;
    cc[0] = {y[1],y[0],1'b0};
    for(kk=1;kk<N;kk=kk+1)
      cc[kk] = {y[2*kk+1],y[2*kk],y[2*kk-1]};
    for(kk=0;kk<N;kk=kk+1)begin
    case(cc[kk])  
      3'b001 , 3'b010 : pp[kk] = {x[width-1],x};
      3'b011 : pp[kk] = {x,1'b0};
      3'b100 : pp[kk] = {inv_x[width-1:0],1'b0};
      3'b101 , 3'b110 : pp[kk] = inv_x;
      default : pp[kk] = 0;
    endcase
    spp[kk] = $signed(pp[kk]);
    for(ii=0;ii<kk;ii=ii+1)
      spp[kk] = {spp[kk],2'b00}; //multiply by 2 to the power x or shifting operation
  end //for(kk=0;kk<N;kk=kk+1)
  prod = spp[0];
  for(kk=1;kk<N;kk=kk+1)
    prod = prod + spp[kk];
  MULTfunc = prod;
  end
endfunction*/

//http://en.wikipedia.org/wiki/Half-precision_floating-point_format
//http://pages.cs.wisc.edu/~smoler/x86text/lect.notes/arith.flpt.html
//http://users-tima.imag.fr/cis/guyot/Cours/Oparithm/english/Flottan.htm
function [15:0] float_add;
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
      overflow = 1;
      sign = float_1[sign_bit];
    end else if (exp_2 == inf_exponent) begin
      overflow = 1;
      sign = float_2[sign_bit];
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
      if (~|mantissa_sum[overflow_bit : sum_lsb]) begin // If its zero
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
      
      // Step 3: Normalize result
      if (~|mantissa_sum[overflow_bit : sum_lsb]) begin // If its zero
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
      
    end
    
    // Assemble and Return
    float_add = overflow ? {sign, inf_exponent, inf_mantissa} : {sign, exp_shifted, mantissa_sum[sum_msb : sum_lsb]};
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
