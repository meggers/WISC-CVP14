module ALU (op_1, op_2, opcode, result);
  
  input [3:0] opcode;
  input [255:0] op_1, op_2;
  
  output reg [255:0] result;
  
  localparam VADD = 4'b0000;
  localparam VDOT = 4'b0001;
  localparam SMUL = 4'b0010;
  localparam SST = 4'b0011;
  localparam VLD = 4'b0100;
  localparam VST = 4'b0101;
  localparam SLL = 4'b0110;
  localparam SLH = 4'b0111;
  localparam J = 4'b1000;
  localparam NOP = 4'b1111;
  
  always @(*)
    case(opcode)
      VADD:begin
            result = VADDfunc(op_1, op_2);
            end
      VDOT:begin
            //result = VDOTfunc(op_1, op2);
           end
      SMUL:begin
            //result = SMULfunc(op_1, op2);
           end
      SST:begin
            //result = SSTfunc(op_1, op2);
           end
      VLD:begin
            //result = VLDfunc(op_1, op2);
           end
      VST:begin
            //result = VSTfunc(op_1, op2);
           end
      SLL:begin
            //result = SLLfunc(op_1, op2);
           end
      SLH:begin
            //result = SLHfunc(op_1, op2);
           end
      J:begin
            //result = Jfunc(op_1, op2);
           end                                            
      default:begin /* NOP */
        
      end
    endcase

/* Add and entire vector of 16-bit FP numbers */
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

/* Add 2 16-bit FP numbers */
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
  
  begin
    exp_1 = float_1[exponent_msb : exponent_lsb] - exponent_bias;
    exp_2 = float_2[exponent_msb : exponent_lsb] - exponent_bias;
    exp_diff = exp_1 - exp_2;
        
    if (exp_diff > 0) begin
      exp_shifted = exp_1;
        
      mantissa_1 = {hidden_bit, float_1[mantissa_msb : mantissa_lsb]};
      mantissa_2 = {hidden_bit, float_2[mantissa_msb : mantissa_lsb]} >> exp_diff;
    end else if (exp_diff < 0) begin
      exp_shifted = exp_2;
        
      mantissa_1 = {hidden_bit, float_1[mantissa_msb : mantissa_lsb]} >> exp_diff;
      mantissa_2 = {hidden_bit, float_2[mantissa_msb : mantissa_lsb]};
    end else begin
      exp_shifted = exp_1;
      
      mantissa_1 = {hidden_bit, float_1[mantissa_msb : mantissa_lsb]};
      mantissa_2 = {hidden_bit, float_2[mantissa_msb : mantissa_lsb]};
    end
      
    mantissa_sum = mantissa_1 + mantissa_2;
      
    if (mantissa_sum[11]) begin
      mantissa_sum = mantissa_sum >> 1;
      exp_shifted = exp_shifted + 1;
    end
    
    exp_shifted = exp_shifted + exponent_bias;  
    float_add = {1'b0, exp_shifted, mantissa_sum[mantissa_msb : mantissa_lsb]};
  end

endfunction

/* Scalar Load Low */
function [15:0] ScalarLoadLow;
  input [15:0] op_1; // Contents of the register to be written to
  input [8:0] op_2;  // Immediate Value to be loaded
  
  reg [15:0] masked;
  
begin
  masked = op_1 & 16'hFF00; // Mask off lower bits
  
  ScalarLoadLow = masked | {8'h00, op_2};
end

endfunction

/* Scalar Load High */
function [15:0] ScalarLoadHigh;
  input [15:0] op_1; // Contents of the register to be written to
  input [8:0] op_2;  // Immediate Value to be loaded
  
  reg [15:0] masked;
  
begin
  masked = op_1 & 16'h00FF; // Maske off upper bits
  
  ScalarLoadHigh = masked | {op_2, 8'h00};
end

endfunction

endmodule



module float_add_t();
  `include "functions.v"
  
  reg [15:0] op_1 = 16'h3C00, 
             op_2 = 16'h3C00; 
            
  reg [15:0] result;

  initial begin
    result = float_add(op_1, op_2);
    $stop;
  end
endmodule