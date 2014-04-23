module decode(instr, cycleCount, functype, v_en,  s_en,
               offset, dstAddr, addr1, addr2, immediate);

input [15:0] instr;

output reg v_en, s_en;
output reg [2:0] addr1, addr2, dstAddr;
output [3:0] functype;
output reg [4:0] cycleCount;
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
localparam J = 4'b1000;
localparam NOP = 4'b1111;

assign functype = instr[15:12];

always @(*) begin // Re-evaluate control signals each instruction
  // Defaults so that flops get inferred
  v_en = 1'b0;
  s_en = 1'b0;
  addr1 = 3'b000;
  addr2 = 3'b000;
  dstAddr = 3'b000;
  cycleCount = 4'h0; // Will be 0(SST and other 1 calculation operations), 15(VST) or 16(VLD)
  offset = 6'd0;
  immediate = 8'h00;

  case(functype) // Still need to add the rest of the instruction types
    VADD:
      begin
        cycleCount = 5'd16;     // Cycles needed
        v_en = 1'b1;
        addr1 = instr[8:6];
        addr2 = instr[5:3];
        dstAddr = instr[11:9];
      end
    VDOT:
      begin
        s_en = 1'b1;            // We're writing to a scalar register later
        dstAddr = instr[11:9];   // Destination register (SRD)
        addr1 = instr[8:6];      // Operand 1 (VRS)
        addr2 = instr[5:3];      // Operand 2 (VRT)
        cycleCount = 4'd15;     // Cycles needed
      end
    VLD:
      begin
        v_en = 1'b1;
        addr1 =  instr[8:6];
        dstAddr = instr[11:9];
        cycleCount = 5'd16; // Need to delay one more cycle than a store
        offset = instr[5:0];
      end
    VST:
      begin
        addr1 = instr[8:6];   // Base register (SRS)
        addr2 = instr[11:9];  // Contents to store 
        cycleCount = 4'd15; 
        offset = instr[5:0];
      end
    SST:
      begin
        addr1 = instr[8:6];   // Base register (SRS)
        addr2 = instr[11:9];  // Contents to store
        offset = instr[5:0];
      end
    SMUL:
      begin
        v_en = 1'b1;            // We'll be writing a vector later
        dstAddr = instr[11:9];  // Destination register (VRD)
        addr1 = instr[8:6];     // Vector register (VRS)
        addr2 = instr[5:3];     // Scalar register (SRT)
        cycleCount = 5'd15;     // Cycles needed
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
    J:
      begin
        immediate = instr[7:0];
      end
    default: begin end /* NOP; leave it all zero */
  endcase
end
    
endmodule
