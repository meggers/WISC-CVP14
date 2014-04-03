module ALU (op_1, op_2, opcode, result);
  `include "functions.v"
  
  input [3:0] opcode;
  input [255:0] op_1, op_2;
  output reg [255:0] result;
  
  `include "functions.v"
  
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
            result[15:0] = op_1[15:0] + op_2[15:0];
           end
      VST:begin
            result[15:0] = op_1[15:0] + op_2[15:0];
           end
      SLL:begin
            result[15:0] = ScalarLoadLow(op_1[15:0], op_2[7:0]);
           end
      SLH:begin
            result = ScalarLoadHigh(op_1[15:0], op_2[7:0]);
           end
      J:begin
            //result = Jfunc(op_1, op2);
           end                                            
      default:begin /* NOP */
        result = 155'd0;
      end
    endcase
  end

endmodule
