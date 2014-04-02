module decode(instr, cycleCount, op1, op2, functype, v_en,  s_en,
               offset, dstAddr, addr1, addr2, immediate);

input instr;

output v_en, s_en;
output [2:0] addr1, addr2, dstAddr;
output [3:0] cycleCount, functype;
output [5:0] offset;
output [7:0] immediate;

assign functype = instr[15:12];

endmodule
