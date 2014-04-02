module decode(instr, cycleCount, op1, op2, functype);

input instr;

output [3:0] cycleCount, functype;
output [15:0] op1, op2;

wire addr1, addr2, wrAddr, 

assign functype = instr[15:12];



endmodule
