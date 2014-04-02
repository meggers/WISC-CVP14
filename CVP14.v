module CVP14(output [15:0] Addr, output RD, output WR, output V, output [15:0] dataOut, 
            input Reset, input Clk1, input Clk2, input [15:0] DataIn);

`include "functions.v"

wire wr_Vector, wr_Scalar, ready;

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
reg wr_vector, wr_scalar;
reg [1:0] state, nextState;
reg [2:0] addr1, addr2, addrDst, wrAddr;
reg [3:0] cycles, count, code, func;
reg [5:0] offset;
reg [7:0] immediate;
reg [15:0] scalarToLoad, scalarData1, scalarData2, scalarWrData, nextInstrAddr;
reg [255:0] op1, op2, data1, data2, vectorToLoad, vectorData1, vectorData2, vectorWrData, result;

VectorRegFile vrf(.rd_addr_1(addr1), .rd_addr_2(addr2), .wr_dst(wrAddr),
                  .wr_data(vectorWrData), .wr_en(vector_en), .data_1(vectorData1), .data_2(vectorData2));
ScalarRegFile srf(.rd_addr_1(addr1), .rd_addr_2(addr2), .wr_dst(wrAddr),
                  .wr_data(scalarWrData), .wr_en(scalar_en), .data_1(scalarData1), .data_2(scalarData2));
                  
ALU alu(.op_1(op1), .op_2(op2), .opcode(func), .result(result));
                  
/* Flop the new state in, using only one always block makes it much more likely
    that latches will be synthesized, which is undesirable */
always @(posedge Clk1)
  if(Reset) begin
    state <= Fetch;
    nextInstrAddr <= 16'h0000;
  end
  else
    state <= nextState;
    
/* Determine what the inputs represent and what the outputs should be based on 
    the current state */
always @(*) begin
  // Set to default values, again for avoiding latches (552 trick)
  nextState = Fetch;
  Addr = 16'h0000;
  vector_en = 1'b0;
  scalar_en = 1'b0;
  RD = 1'b0;
  WR = 1'b0;
  V = 1'b0;
  dataOut = 16'h0000;
  
  case(state)
    Fetch: begin
      Addr = nextInstrAddr;
      nextInstrAddr = nextInstrAddr + 1;
      RD = 1'b1;
      WR = 1'b0;
      
      nextState = Decode;
    end
   
    Decode: begin
      RD = 1'b0;
      WR = 1'b0;
      
      decode instr(.instr(DataIn), /* In */
      
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
                   
                   .op1(data1), /* Out */
                   .op2(data2));
                   
      cycles = 4'h0;
      
      if(code == VLD)
        nextState = Load;
      else if(code == VST || code == SST)
        nextState = Store;
      else
        nextState = Execute;
    end
    
    Execute: begin // Where things happen in one clock cycle
      RD = 1'b0;
      WR = 1'b0;
      
      // Stimulate the ALU; Result will be in result
      op1 = data1;
      op2 = data2;
      func = code;
      
      nextState = WriteBack;
    end
    
    Load: begin // Where things are forced to take multiple clock cycles
      Addr = op1 + cycles;
      RD = 1'b1;
      WR = 1'b0;
      
      if(cycles > 0) begin
          vectorToLoad[((16*cycles)-1) -: 15] = DataIn;
          scalarToLoad = DataIn;
      end
          
      if(cycles == count)
        nextState = WriteBack;
      else
        cycles = cycles + 1;
    end
    
    Store: begin // Where things are forced to take multiple clock cycles
      Addr = op1 + cycles;
      RD = 1'b0;
      WR = 1'b1;
      
      if(cycles == count)
        nextState = Fetch;
      else
        cycles = cycles + 1;
    end
    
    WriteBack: begin
      RD = 1'b0;
      WR = 1'b0;
      
      if(wr_vector) begin
        vector_en = 1'b1;
        scalar_en = 1'b0;
        
        if(code == VLD)
          vectorWrData = vectorToLoad;
        else
          vectorWrData = result;
          
      end else if(wr_scalar) begin
        scalar_en = 1'b1;
        vector_en = 1'b0;
        
        scalarWrData = result[15:0];
        
      end else begin
        scalar_en = 1'b0;
        vector_en = 1'b0;
      end
      
      nextState = Fetch;
    end
    
    default:
      nextState = Fetch;
  endcase
end

endmodule

/*


PC pc(.Clk1(Clk1), .Clk2(Clk2), .rst(Reset), .next(ready), .nextAddr(nextAddr), .iAddr(instrAddr));
            
VectorRegFile vrf(.clk(Clk1), .rd_addr_1(addr1), .rd_addr_2(addr2), .wr_dst(wrDst),
                  .wr_data(wrData), .wr_en(enable), .data_1(data1), .data_2(data2));
ScalarRegFile srf(.clk(Clk1), .rd_addr_1(addr1), .rd_addr_2(addr2), .wr_dst(wrDst),
                  .wr_data(wrData), .wr_en(enable), .data_1(data1), .data_2(data2));
ALU alu();

assign addr = ready ? instrAddr : dataAddr;

Set control signals 
always@(posedge Clk1, posedge Clk2) begin
  if(ready) begin /* Reevaluate control signals 
    ready = 1'b0;
    
  opCode = DataIn[15:12];
  
  case(opCode)
    VADD:
      begin 
        addr1 = DataIn[8:6];
        addr2 = DataIn[5:3];
      end
    VDOT:
      begin
        addr1 = DataIn[8:6];
        addr2 = DataIn[5:3];
      end
    SMUL:
      begin
        addr1 = DataIn[8:6];
        addr2 = DataIn[5:3];
      end
    SST:
      begin
        addr1 = DataIn[11:9];
        
      end
    VLD:
      begin
        addr1 = ;
        addr2 = ;
      end
    VST:
      begin
        addr1 = ;
        addr2 = ;
      end
    SLL:
      begin
        addr1 = ;
        addr2 = ;
      end
    SLH:
      begin
        addr1 = ;
        addr2 = ;
      end
    J:
      begin
        addr1 = ;
        addr2 = ;
      end
    default:  NOP 
      begin
        addr1 = ;
        addr2 = ;
      end
  endcase
  end
end
*/

