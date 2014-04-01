module ALU (clk, op_1, op_2, opcode, result);
  input clk;
  input [3:0] opcode;
  input [255:0] op_1, op_2;
  output reg [255:0] result;
  
  `include "functions.v"
  
  parameter VADD = 4'b0000,
            VDOT = 4'b0001,
            SMUL = 4'b0010,
            SST  = 4'b0011,
            VLD  = 4'b0100,
            VST  = 4'b0101,
            SLL  = 4'b0110,
            SLH  = 4'b0111,
            J    = 4'b1000,
            NOP  = 4'b1111;
            
  always @(posedge clk) begin
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
  
endmodule