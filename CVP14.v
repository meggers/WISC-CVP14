module CVP14(output [15:0] Addr, output RD, output WR, output V, output [15:0] dataOut, 
            input Reset, input Clk1, input Clk2, input [15:0] DataIn);

wire [15:0] dataAddr, addr;

/* State Definitions */
localparam Fetch = 3'd0;
localparam Decode = 3'd1;
localparam Execute = 3'd2;
localparam WriteBack = 3'd3;
localparam Load = 3'd4;
localparam Store = 3'd5;

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

/* "Global" Variables */
reg vector_en, scalar_en, read, write, flow;
reg [1:0] state, nextState;
reg [2:0] wrAddr;
reg [3:0] cycles, func;
reg [15:0] scalarToLoad,  scalarWrData, nextInstrAddr, memAddr, data, instrIn;
reg [255:0] op1, op2, vectorToLoad, vectorWrData;

wire wr_vector, wr_scalar;
wire [2:0] addr1, addr2, addrDst;
wire [3:0] count, code;
wire [5:0] offset;
wire [7:0] immediate;
wire [15:0] scalarData1, scalarData2;
wire [255:0] data1, data2, vectorData1, vectorData2, result;

VectorRegFile vrf(.rd_addr_1(addr1), 
                  .rd_addr_2(addr2), 
                  .wr_dst(wrAddr),
                  .wr_data(vectorWrData), 
                  .wr_en(vector_en), 
                  
                  .data_1(vectorData1), 
                  .data_2(vectorData2));
                  
ScalarRegFile srf(.rd_addr_1(addr1), 
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
    nextInstrAddr <= 16'h0000;
  end else
    state <= nextState;
    
/* Determine what the inputs represent and what the outputs should be based on 
    the current state */ 
always @(state, DataIn) begin
  // Set to default values, again for avoiding latches (552 trick)
  nextState = Fetch;
  memAddr = 16'h0000;
  vector_en = 1'b0;
  scalar_en = 1'b0;
  read = 1'b0;
  write = 1'b0;
  flow = 1'b0;
  instrIn = 16'h0000;
  data = 16'h0000;
  
  case(state)
    Fetch: begin
      memAddr = nextInstrAddr;
      nextInstrAddr = nextInstrAddr + 1;
      read = 1'b1;
      
      nextState = Decode;
    end
   
    Decode: begin
      instrIn = DataIn; /* Outputs of decode and picker are now relevant until
                           the next fetch state, most notably op1 and op2. */
                   
      cycles = 4'h0; // Reset the counter
      nextState = Execute;
    end
    
    Execute: begin // Where things happen in one clock cycle    
      
      // Stimulate the ALU
      op1 = data1;
      op2 = data2;
      func = code; // result is now relevant until the next fetch state
      
      if(code == VLD)
        nextState = Load;
      else if(code == VST)
        nextState = Store;
      else
        nextState = WriteBack;
    end
    
    Load: begin // Where things are forced to take multiple clock cycles
      memAddr = result[15:0] + cycles;
      read = 1'b1;
      
      if(cycles > 0) begin // Else we are still waiting for the first component
          vectorToLoad[((16*cycles)-1) -: 15] = DataIn;
      end
          
      if(cycles == count)
        nextState = WriteBack;
      else
        cycles = cycles + 1;
    end
    
    Store: begin // Where things are forced to take multiple clock cycles
      memAddr = result[15:0] + cycles;
      data = vectorData1[((cycles*16)-1) -: 15];
      write = 1'b1;
      
      if(cycles == count)
        nextState = Fetch;
      else
        cycles = cycles + 1;
    end
    
    WriteBack: begin
      
      if(wr_vector) begin
        vector_en = 1'b1;
        wrAddr = addrDst;
        
        if(code == VLD)
          vectorWrData = vectorToLoad;
        else
          vectorWrData = result;
          
      end else if(wr_scalar) begin
        scalar_en = 1'b1;
        wrAddr = addrDst;
        
        scalarWrData = result[15:0];
      end else /* NOP */ begin
        // Don't set either enable
      end
      
      nextState = Fetch;
    end
    
    default:
      nextState = Fetch;
  endcase
end

endmodule