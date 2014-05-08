module mult_tb;
  reg[15:0] A;
  reg [15:0] B;
  reg[15:0] out;
//  `include "functions.v"
  initial begin
    $monitor("time=",$time, "In=%b, %b : Out=%b",A,B, out);
  end
  initial begin
    #5 A = 16'b0100001000000000;
       B = 16'b0100001100000000;
       out = float_mult(A,B);
  end
endmodule