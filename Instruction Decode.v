module decode(instr, cycleCount, functype, v_en,  s_en,
               offset, dstAddr, addr1, addr2, immediate);

input [15:0] instr;

output reg v_en, s_en;
output reg [2:0] addr1, addr2, dstAddr;
output [3:0] functype;
output reg [3:0] cycleCount;
output reg [5:0] offset;
output reg [7:0] immediate;

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

assign functype = instr[15:12];

always @(functype) begin // Re-evaluate control signals each instruction
  // Defaults so that flops get inferred
  v_en = 1'b0;
  s_en = 1'b0;
  addr1 = 3'b000;
  addr2 = 3'b000;
  dstAddr = 3'b000;
  cycleCount = 4'h1; // Will be 1 or 16, instruction dependant
  offset = 6'd0;
  immediate = 8'h00;

  case(functype) // Still need to add the rest of the instruction types
    VADD:
      begin
        v_en = 1'b1;
        addr1 = instr[8:6];
        addr2 = instr[5:3];
        dstAddr = instr[11:9];
      end
    VLD:
      begin
        v_en = 1'b1;
        addr1 =  instr[8:6];
        dstAddr = instr[11:9];
        cycleCount = 4'd16; // Need to delay one more cycle than a store
        offset = instr[5:0];
      end
    VST:
      begin
        v_en = 1'b1;
        addr1 = instr[8:6];
        dstAddr = instr[11:9];
        cycleCount = 4'd15;
        offset = instr[5:0];
      end
    SLL:
      begin
        s_en = 1'b1;
        addr1 = instr[11:9];
        dstAddr = instr[11:9];
        immediate = instr[7:0];
      end
    SLH:
      begin
        s_en = 1'b1;
        addr1 = instr[11:9];
        dstAddr = instr[11:9];
        immediate = instr[7:0];
      end
    default: begin end /* NOP; leave it all zero */
  endcase
end
    
endmodule
