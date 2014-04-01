module ALU (clk, op_1, op_2, opcode, result);
  output [255:0] result;
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
            result = VADDfunc(op_1, op2);
            end
      VDOT:begin
            result = VDOTfunc(op_1, op2);
           end
      SMUL:begin
            result = SMULfunc(op_1, op2);
           end
      SST:begin
            result = SSTfunc(op_1, op2);
           end
      VLD:begin
            result = VLDfunc(op_1, op2);
           end
      VST:begin
            result = VSTfunc(op_1, op2);
           end
      SLL:begin
            result = SLLfunc(op_1, op2);
           end
      SLH:begin
            result = SLHfunc(op_1, op2);
           end
      J:begin
            result = Jfunc(op_1, op2);
           end                                            
      NOP:begin
            result = NOPfunc(op_1, op2);
           end
      default: $display("error");
    endcase
  end

function [255:0] VADDfunc (input [255:0]op_1, op_2);
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
  
  reg [5:0] i;

  always @(posedge clk) begin
    for (i = 0; i < maxDimensions; i = i + 1) begin 
      sum[dimensionSize * i +: dimensionSize] <= vector_sum[i];
    end
  end
  
  always @(op_1, op_2) begin
    for (dimension = 0; dimension < maxDimensions; dimension = dimension + 1) begin
      vector_1[dimension] <= op_1[dimensionSize * dimension +: dimensionSize];
      vector_2[dimension] <= op_2[dimensionSize * dimension +: dimensionSize];
      
      exp_1 <= vector_1[dimension][dimensionSize - exponent_offset -: exponent_length] - exponent_bias;
      exp_2 <= vector_2[dimension][dimensionSize - exponent_offset -: exponent_length] - exponent_bias;
      exp_diff = exp_1 - exp_2;
        
      if (exp_diff > 0) begin
        exp_shifted <= exp_1;
        
        mantissa_1_shifted <= vector_1[dimension][dimensionSize - mantissa_offset -: mantissa_length];
        mantissa_2_shifted <= vector_2[dimension][dimensionSize - mantissa_offset -: mantissa_length] >> exp_diff;
      end else if (exp_diff < 0) begin
        exp_shifted <= exp_2;
        
        mantissa_1_shifted <= vector_1[dimension][dimensionSize - mantissa_offset -: mantissa_length] >> exp_diff;
        mantissa_2_shifted <= vector_2[dimension][dimensionSize - mantissa_offset -: mantissa_length];
      end else begin
        exp_shifted <= exp_1;
        
        mantissa_1_shifted <= vector_1[dimension][dimensionSize - mantissa_offset -: mantissa_length];
        mantissa_2_shifted <= vector_2[dimension][dimensionSize - mantissa_offset -: mantissa_length]; 
      end
      
      mantissa_sum = mantissa_1_shifted + mantissa_2_shifted;
      
      if (mantissa_sum[10]) begin
         mantissa_sum = mantissa_sum >> 1;
         exp_shifted = exp_shifted >> 1;
      end
      
      vector_sum[dimension] = {1'b0, exp_shifted, mantissa_sum[9:0]};
      end
    end  
  endfunction
  function [255:0] VDOTfunc (input op_1, op_2);
    
  endfunction
  function [255:0] SMULfunc (input op_1, op_2);
  
  endfunction
  function [255:0] VLDfunc (input op_1, op_2);
  
  endfunction
  function [255:0] VSTfunc (input op_1, op_2);
  
  endfunction
  function [255:0] SLHfunc (input op_1, op_2);
  
  endfunction
  function [255:0] SLLfunc (input op_1, op_2);
  
  endfunction
  function [255:0] SSTfunc (input op_1, op_2);
  
  endfunction
  function [255:0] Jfunc (input op_1, op_2);
  
  endfunction
  function [255:0] NOPfunc (input op_1, op_2);
    
  endfunction
endmodule
