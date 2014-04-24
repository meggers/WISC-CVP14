module CVP14(output [15:0] Addr, output RD, output WR, output V, output [15:0] dataOut, 
            input Reset, input Clk1, input Clk2, input [15:0] DataIn);
            
`include "functions.v"

/* State Definitions */
localparam Fetch = 4'd0;
localparam Decode = 4'd1;
localparam Execute = 4'd2;
localparam WriteBack = 4'd3;
localparam Load = 4'd4;
localparam Store = 4'd5;
localparam Jump = 4'd6;
localparam ScalarMultiply = 4'd7;
localparam VectorDot = 4'd8;
localparam VectorAdd = 4'd9;

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

/* "Global" Variables */
localparam INFINITY = 16'h7C00;

reg vector_en, scalar_en, read, write, flow, overflow, fire;
reg [3:0] state, nextState;
reg [2:0] wrAddr;
reg [3:0] func;
reg [4:0] cycles;
reg [15:0] scalarToLoad,  scalarWrData, nextInstrAddr, memAddr, data, instrIn;
reg [255:0] op1, op2, vectorToLoad, vectorWrData;

wire wr_vector, wr_scalar;
wire [2:0] addr1, addr2, addrDst;
wire [3:0] code;
wire [4:0] count;
wire [5:0] offset;
wire [7:0] immediate;
wire [15:0] scalarData1, scalarData2;
wire [255:0] data1, data2, vectorData1, vectorData2, result;

VectorRegFile vrf(.rst(Reset),
                  .rd_addr_1(addr1), 
                  .rd_addr_2(addr2), 
                  .wr_dst(wrAddr),
                  .wr_data(vectorWrData), 
                  .wr_en(vector_en), 
                  
                  .data_1(vectorData1), 
                  .data_2(vectorData2));
                  
ScalarRegFile srf(.rst(Reset),
                  .rd_addr_1(addr1), 
                  .rd_addr_2(addr2), 
                  .wr_dst(wrAddr),
                  .wr_data(scalarWrData), 
                  .wr_en(scalar_en), 
                  
                  .data_1(scalarData1), 
                  .data_2(scalarData2));
                  
ALU alu(.op_1(op1), 
        .op_2(op2), 
        .opcode(func), 
        
        .result(result));
                  
decode instr(.instr(instrIn), /* In */
      
              .v_en(wr_vector), /* Out */
              .s_en(wr_scalar),
              .dstAddr(addrDst),
              .addr1(addr1), 
              .addr2(addr2),
              .immediate(immediate), 
              .offset(offset),
              .cycleCount(count),
              .functype(code));
                   
picker ofOps(.functype(code),  /* In */
             .vectorData1(vectorData1),
             .vectorData2(vectorData2),
             .scalarData1(scalarData1),
             .scalarData2(scalarData2),
             .immediate(immediate),
             .offset(offset),
             .PC(memAddr),
                   
             .op1(data1), /* Out */
             .op2(data2));  
             
// The registers on the right hand side will only be asserted at the correct times.
assign RD = read;
assign WR = write;
assign V = flow;
assign Addr = memAddr;
assign dataOut = data;          
                  
/* Flop the new state in, using only one always block makes it much more likely
    that latches will be synthesized, which is undesirable */
always @(posedge Clk1)
  if(Reset) begin
    state <= Fetch;
    fire <= 1'b0; 
  end else begin
    state <= nextState;
    fire <= ~fire; // Force re-eval, ***doesn't simulate correctly if the other always block is @(posedge Clk1)***
  end
    
/* Determine what the inputs represent and what the outputs should be based on 
    the current state */ 
always @(fire) begin
  // Set to default values, again for avoiding latches (HA...)
  nextState = Fetch;
  vector_en = 1'b0;
  vectorWrData = 256'd0;
  scalar_en = 1'b0;
  read = 1'b0;
  write = 1'b0;
  data = 16'h0000;
  
  if(Reset) begin// Make sure that nextInstrAddr has mutually exclusive assignements
    nextInstrAddr = 16'h0000;
    flow = 1'b0;
  end
  
  case(state)
    Fetch: begin
      memAddr = nextInstrAddr;
      
      if(~Reset) begin // Make sure that nextInstrAddr has mutually exclusive assignements
        nextInstrAddr = nextInstrAddr + 1;
        flow = overflow;
      end
        
      read = 1'b1;
      nextState = Decode;
    end
   
    Decode: begin
      instrIn = DataIn; /* Outputs of decode and picker are now relevant until
                           the next fetch state, most notably data1 and data2. */
                   
      cycles = 4'h0; // Reset the counter
      
      nextState = Execute;
    end
    
    Execute: begin // State 2
      // Stimulate the ALU
      op1 = data1[15:0];
      op2 = data2[15:0];  
      overflow = 1'b0; // Reset for the executing instruction      
      func = code;
    
      if(code == VADD) begin
        nextState = VectorAdd;      
      end else if(code == VDOT) begin
        nextState = VectorDot;
      end else if(code == SMUL) begin
        nextState = ScalarMultiply;  
      end else if(code == J) begin          
        nextState = Jump;
      end else if(code == VLD)
        nextState = Load;
      else if(code == VST || code == SST)
        nextState = Store;
      else begin // Nothing else to do!
        nextState = WriteBack;
      end
    end
    
    VectorAdd: begin
      // Stimulate the ALU
      op1 = {240'd0, data1[((cycles+1)*16)+15 -: 16]}; // I couldn't tell you why this is -: 16, but it doesn't work with -: 15;
      op2 = {240'd0, data2[((cycles+1)*16)+15 -: 16]}; // I couldn't tell you why this is -: 16, but it doesn't work with -: 15;
      
      if(result == INFINITY)
        overflow = 1'b1;
      else
        overflow = overflow;
      
      if(cycles > 0)
        vectorToLoad = vectorToLoad | (result << 16*cycles);
      else
        vectorToLoad = result[15:0];
        
      if(cycles == count)
        nextState = WriteBack;
      else begin
        cycles = cycles + 1;
        nextState = VectorAdd; // Not done yet
      end
    end
    
    VectorDot: begin
      // Stimulate the ALU
      op1 = {240'd0, data1[((cycles+1)*16)+15 -: 16]}; // I couldn't tell you why this is -: 16, but it doesn't work with -: 15;
      op2 = {240'd0, data2[((cycles+1)*16)+15 -: 16]}; // I couldn't tell you why this is -: 16, but it doesn't work with -: 15;
      
      if(result == INFINITY)
        overflow = 1'b1;
      else
        overflow = overflow;
      
      if(cycles > 0)
        scalarToLoad = float_add(scalarToLoad, result[15:0]);
      else
        scalarToLoad = result[15:0];
        
      if(cycles == count)
        nextState = WriteBack;
      else begin
        cycles = cycles + 1;
        nextState = VectorDot; // Not done yet
      end
    end
    
    ScalarMultiply: begin
      // Stimulate the ALU
      op1 = {240'd0, data1[((cycles+1)*16)+15 -: 16]}; // I couldn't tell you why this is -: 16, but it doesn't work with -: 15
      op2 = {240'd0, data2[15:0]};
      
      if(cycles > 0)
        vectorToLoad = vectorToLoad | (result << 16*cycles);
      else
        vectorToLoad = {240'd0, result}; // First element doesn't need to be shifted
        
      if(result == INFINITY)
        overflow = 1'b1;
      else
        overflow = overflow;
        
      if(cycles == count)
        nextState = WriteBack;
      else begin
        cycles = cycles + 1;
        nextState = ScalarMultiply; // Not done yet
      end
    end
    
    Jump: begin
      if(~Reset)
        nextInstrAddr = result[15:0];
        
      nextState = Fetch;
    end
    
    Load: begin // Where things are forced to take multiple clock cycles
      memAddr = result[15:0] + cycles;
      read = 1'b1;
      
      if(cycles > 0) begin // Else we are still waiting for the first component
        if(cycles > 1)
          vectorToLoad = vectorToLoad | (DataIn << 16*(cycles-1));
        else
          vectorToLoad = vectorToLoad | DataIn; // First element doesn't need to be shifted
      end else
        vectorToLoad = 256'd0; // "Initialize" it
          
      if(cycles == count)
        nextState = WriteBack;
      else begin
        nextState = Load;
        cycles = cycles + 1;
      end
    end
    
    Store: begin // Where things are forced to take multiple clock cycles
      memAddr = result[15:0] + cycles;
      write = 1'b1;
      
      /* Obvious room for inprovement, I couldn't get 
        indexing logic to work and it's crunch time */
      if(cycles == 15)
        data = vectorData2[255:240];
      else if(cycles == 14)
        data = vectorData2[239:224];
      else if(cycles == 13)
        data = vectorData2[223:208];
      else if(cycles == 12)
        data = vectorData2[207:192];
      else if(cycles == 11)
        data = vectorData2[191:176];
      else if(cycles == 10)
        data = vectorData2[175:160];
      else if(cycles == 9)
        data = vectorData2[159:144];
      else if(cycles == 8)
        data = vectorData2[143:128];
      else if(cycles == 7)
        data = vectorData2[127:112];
      else if(cycles == 6)
        data = vectorData2[111:96];
      else if(cycles == 5)
        data = vectorData2[95:80];
      else if(cycles == 4)
        data = vectorData2[79:64];
      else if(cycles == 3)
        data = vectorData2[63:48];
      else if(cycles == 2)
        data = vectorData2[47:32];
      else if(cycles == 1)
        data = vectorData2[31:16];
      else
        if(code == SST)
          data = scalarData2;
        else
          data = vectorData2[15:0];
      
      if(cycles == count)
        nextState = Fetch;
      else begin
        nextState = Store;
        cycles = cycles + 1;
      end
    end
    
    WriteBack: begin
      
      if(wr_vector) begin
        vector_en = 1'b1;
        wrAddr = addrDst;
        
        if(code == VLD || code == SMUL || code == VDOT || code == VADD)
          vectorWrData = vectorToLoad;
        else
          vectorWrData = result;
          
      end else if(wr_scalar) begin
        scalar_en = 1'b1;
        wrAddr = addrDst;
        
        if(code == VDOT)
          scalarWrData = scalarToLoad;
        else
          scalarWrData = result[15:0];
      end
      
      nextState = Fetch;
    end
    
    default:
      nextState = Fetch;
  endcase
end
endmodule
