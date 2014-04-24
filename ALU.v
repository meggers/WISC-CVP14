module ALU (op_1, op_2, opcode, result);
  input [3:0] opcode;
  input [255:0] op_1, op_2;
  output reg [255:0] result;
  
  `include "functions.v"

 /* Instruction Codes */
  localparam VADD = 4'b0000;
  localparam VDOT = 4'b0001;
  localparam SMUL = 4'b0010;
  localparam SST = 4'b0011;
  localparam VLD = 4'b0100;
  localparam VST = 4'b0101;
  localparam SLL = 4'b0110;
  localparam SLH = 4'b0111;
  localparam NOP = 4'b1111;
  
  always @(*)
    case(opcode)
      VADD:
        begin
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
            result = {240'd0, (op_1[15:0] + op_2[15:0])};
           end
      VST:begin
            result = {240'd0, (op_1[15:0] + op_2[15:0])};
           end
      SLL:begin
            result = {240'd0, ScalarLoadLow(op_1[15:0], op_2[7:0])};
           end
      SLH:begin
            result = {240'd0, ScalarLoadHigh(op_1[15:0], op_2[7:0])};
           end                                          
      default:begin /* NOP */
        result = 255'd0;
      end
    endcase
endmodule

module float_add_t();
  `include "functions.v"
  
  reg [15:0] op_2 = 16'b0011110000000000, // 
             op_1 = 16'b0011110000000000; // 
            
  reg [15:0] result;

  initial begin
    result = float_add(op_1, op_2);
    $stop;
  end
endmodule