module ALU (clk, op_1, op_2, opcode, result);
  output reg [255:0] result;
  input clk, op_1, op_2;
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
      NOP:begin
            //result = NOPfunc(op_1, op2);
           end
      default: $display("error");
    endcase
  end

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