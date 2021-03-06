/////////////////////////////////////////////////////////////////////////////////////////////////////////
/* Determines the operands op1 and op2, which will be used for the duration of the current instruction */
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module picker(functype, vectorData1, vectorData2, scalarData1,
               scalarData2, immediate, offset, jumpOffset, PC, op1, op2);
               
  input [3:0] functype;
  input [5:0] offset;
  input [7:0] immediate;
  input [11:0] jumpOffset;
  input [15:0] scalarData1, scalarData2;
  input [255:0] vectorData1, vectorData2;
  
  input [15:0] PC;
  
  output reg [255:0] op1, op2;
  
  /* Instruction Codes */
  localparam VADD = 4'b0000;
  localparam VDOT = 4'b0001;
  localparam SMUL = 4'b0010;
  localparam SST  = 4'b0011;
  localparam VLD  = 4'b0100;
  localparam VST  = 4'b0101;
  localparam SLL  = 4'b0110;
  localparam SLH  = 4'b0111;
  localparam J    = 4'b1000;
  localparam NOP  = 4'b1111;
  
  always @(*) begin

  case(functype) // Still need to add the rest of the instruction types
    VADD:
      begin
        op1 = vectorData1;
        op2 = vectorData2;
      end
    VLD:
      begin
        op1 = {240'd0, scalarData1};
        op2 = {240'd0, {{10{offset[5]}}, offset}}; // Sign extended offset
      end
    VDOT:
      begin
        op1 = vectorData1;
        op2 = vectorData2;
      end
    VST:
      begin
        op1 = {240'd0, scalarData1};
        op2 = {240'd0, {{10{offset[5]}}, offset}}; // Sign extended offset
      end
    SST:
      begin
        op1 = {240'd0, scalarData1};
        op2 = {240'd0, {{10{offset[5]}}, offset}}; // Sign extended offset  
      end
    SMUL:
      begin
        op1 = vectorData1;                        // Vector to multiply
        op2 = {240'd0, scalarData2};              // Scalar to multiply by
      end
    SLL:
      begin
        op1 = {240'd0, scalarData1};
        op2 = {248'd0, immediate};
      end
    SLH:
      begin
        op1 = {240'd0, scalarData1};
        op2 = {248'd0, immediate};
      end
    J:
      begin
        op1 = {240'd0, PC};
        op2 = {240'd0, {{4{jumpOffset[11]}}, jumpOffset}};
      end
    default:
      begin
        op1 = 255'd0;
        op2 = 255'd0;
      end
  endcase
end
  
endmodule
