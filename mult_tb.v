module mult_tb;
  reg[15:0] A;
  reg [15:0] B;
  reg[15:0] out;
  `include "functions.v"
  initial begin
    $monitor("time=",$time, "In=%b, %b : Out=%b",A,B, out);
  end
  initial begin
    #5 A = 16'b1010000010010001;
       B = 16'b111100000100000;
       out = float_mult(A,B);
  end
endmodule