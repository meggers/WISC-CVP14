module ALU (clk, op_1, op_2, opcode, result);
  output reg [255:0] result;
  input clk;
  input [255:0] op_1, op_2;
  input [3:0] opcode;
  parameter VADD = 4'b0000;
  parameter VDOT = 4'b0001;
  parameter SMUL = 4'b0010;
  parameter SST = 4'b0011;
  parameter VLD = 4'b0100;
  parameter VST = 4'b0101;
  parameter SLL = 4'b0110;
  parameter SLH = 4'b0111;
  parameter J = 4'b1000;
  parameter NOP = 4'b1111;
  always @(posedge clk) begin
    case(opcode)
      VADD:begin
            result <= VADDfunc(op_1, op_2);
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
      NOP:begin
            //result = NOPfunc(op_1, op2);
           end
      default: $display("error");
    endcase
  end

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

function float_add;
  input [15:0] float_1, float_2;
  
  parameter exponent_bias   = 15;
  
  parameter float_width     = 16;
  
  parameter sign_offset     = 0,
            exponent_offset = 1,
            mantissa_offset = 6;
             
  parameter sign_length     = 1,
            exponent_length = 5,
            mantissa_length = 10;
            
  reg [4:0] exp_1, exp_2;
  reg signed [5:0] exp_diff;
  
  reg [4:0] exp_shifted;
  
  reg [9:0] mantissa_1_shifted, mantissa_2_shifted;
  
  reg [10:0] mantissa_sum;
  
  begin
    exp_1 = float_1[float_width - exponent_offset -: exponent_length] - exponent_bias;
    exp_2 = float_2[float_width - exponent_offset -: exponent_length] - exponent_bias;
    exp_diff = exp_1 - exp_2;
        
    if (exp_diff > 0) begin
      exp_shifted = exp_1;
        
      mantissa_1_shifted = float_1[float_width - mantissa_offset -: mantissa_length];
      mantissa_2_shifted = float_2[float_width - mantissa_offset -: mantissa_length] >> exp_diff;
    end else if (exp_diff < 0) begin
      exp_shifted = exp_2;
        
      mantissa_1_shifted = float_1[float_width - mantissa_offset -: mantissa_length] >> exp_diff;
      mantissa_2_shifted = float_2[float_width - mantissa_offset -: mantissa_length];
    end else begin
      exp_shifted = exp_1;
        
      mantissa_1_shifted = float_1[float_width - mantissa_offset -: mantissa_length];
      mantissa_2_shifted = float_2[float_width - mantissa_offset -: mantissa_length]; 
    end
      
    mantissa_sum = mantissa_1_shifted + mantissa_2_shifted;
      
    if (mantissa_sum[10]) begin
      mantissa_sum = mantissa_sum >> 1;
      exp_shifted = exp_shifted >> 1;
    end
    
    float_add = {1'b0, exp_shifted, mantissa_sum[9:0]};
  end

endfunction

endmodule

module float_add_t();
  
  parameter op_1 = 16'h3C00, 
            op_2 = 16'h3C00; 
            
  reg [15:0] result;
  
  initial begin
    result <= float_add(op_1, op_2);
    $display("result: %h", result);
    $stop;
  end
  
function float_add;
  input [15:0] float_1, float_2;
  
  parameter exponent_bias   = 15;
  
  parameter float_width     = 15;
  
  parameter exponent_offset = 1,
            mantissa_offset = 6;
             
  parameter exponent_length = 4,
            mantissa_length = 9;
            
  reg signed [4:0] exp_1, exp_2, exp_shifted;
  reg signed [5:0] exp_diff;
  
  reg [9:0] mantissa_1, mantissa_2;
  reg [10:0] mantissa_sum;
  
  begin
    exp_1 = float_1[(float_width - exponent_offset) -: exponent_length] - exponent_bias;
    exp_2 = float_2[(float_width - exponent_offset) -: exponent_length] - exponent_bias;
    exp_diff = exp_1 - exp_2;
        
    if (exp_diff > 0) begin
      exp_shifted = exp_1;
        
      mantissa_1 = float_1[(float_width - mantissa_offset) -: mantissa_length];
      mantissa_2 = float_2[(float_width - mantissa_offset) -: mantissa_length] >> exp_diff;
    end else if (exp_diff < 0) begin
      exp_shifted = exp_2;
        
      mantissa_1 = float_1[(float_width - mantissa_offset) -: mantissa_length] >> exp_diff;
      mantissa_2 = float_2[(float_width - mantissa_offset) -: mantissa_length];
    end else begin
      exp_shifted = exp_1;
        
      mantissa_1 = float_1[(float_width - mantissa_offset) -: mantissa_length];
      mantissa_2 = float_2[(float_width - mantissa_offset) -: mantissa_length]; 
    end
      
    mantissa_sum = mantissa_1 + mantissa_2;
      
    if (mantissa_sum[10]) begin
      mantissa_sum = mantissa_sum >> 1;
      exp_shifted = exp_shifted >> 1;
    end
    
    float_add = {1'b0, exp_shifted, mantissa_sum[9:0]};
  end

endfunction
  
endmodule