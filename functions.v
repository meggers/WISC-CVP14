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
function float_add;
  input [15:0] float_1, float_2;
  
  parameter exponent_bias   = 5'b01111,
            hidden_bit      = 1'b1;
            
  parameter sign_bit     = 15,
            exponent_msb = 14,
            exponent_lsb = 10, 
            mantissa_msb = 9,
            mantissa_lsb = 0,
            overflow     = 11,
            hidden       = 10;
            
  reg signed [4:0] exp_1, exp_2, exp_shifted;
  reg signed [5:0] exp_diff;
  
  reg [10:0] mantissa_1, mantissa_2; // Includes hidden bit
  reg [11:0] mantissa_sum; // Includes overflow bit
  
  reg sign;
  reg [3:0] leadingZeros;
  
  begin
    // Step 1a: Subtract exponents 
    exp_1 = float_1[exponent_msb : exponent_lsb] - exponent_bias;
    exp_2 = float_2[exponent_msb : exponent_lsb] - exponent_bias;
    exp_diff = exp_1 - exp_2;
        
    // Step 1b: Construct mantissas
    mantissa_1 = {hidden_bit, float_1[mantissa_msb : mantissa_lsb]};
    mantissa_2 = {hidden_bit, float_2[mantissa_msb : mantissa_lsb]};    
        
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
    if (mantissa_sum[overflow]) begin
      mantissa_sum = mantissa_sum >> 1;
      exp_shifted = exp_shifted + 1;
    end else if (~mantissa_sum[hidden]) begin
      leadingZeros = numLeadingZeros(mantissa_sum[9:0]);
      mantissa_sum = mantissa_sum << leadingZeros;
      exp_shifted = exp_shifted - leadingZeros;
    end
    
    // Reassable and return    
    exp_shifted = exp_shifted + exponent_bias;
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