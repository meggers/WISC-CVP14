module CVP14(output [15:0] Addr, output RD, output WR, output V, output [15:0] dataOut, 
            input Reset, input Clk1, input Clk2, input [15:0] DataIn);
            
wire wr_Vector, wr_Scalar, ready;
wire [2:0] addr1, addr2, wrDst;
wire [15:0] scalarData1, scalarData2, scalarWrData, nextInstrAddr, dataAddr, addr;
wire [255:0] vectorData1, vectorData2, vectorWrData;

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
reg [1:0] state, nextState;
reg [2:0] dstAddr;
reg [3:0] cycles, count, code;
reg [15:0] op1, op2;

VectorRegFile vrf(.rd_addr_1(addr1), .rd_addr_2(addr2), .wr_dst(wrAddr),
                  .wr_data(vectorWrData), .wr_en(wr_Vector), .data_1(vectorData1), .data_2(vectorData2));
ScalarRegFile srf(.rd_addr_1(addr1), .rd_addr_2(addr2), .wr_dst(wrAddr),
                  .wr_data(scalarWrData), .wr_en(wr_Scalar), .data_1(scalarData1), .data_2(scalarData2));
                  
/* Flop the new state in, using only one always block makes it much more likely
    that latches will be synthesized, which is undesirable */
always @(posedge Clk1)
  if(Reset)
    state <= Fetch;
  else
    state <= nextState;
    
/* Determine what the inputs represent and what the outputs should be based on 
    the current state */
always @(*) begin
  // Set to default values, again for avoiding latches (552 trick)
  nextState = Fetch;
  Addr = 16'h0000;
  wr_Vector = 1'b0;
  wr_Scalar = 1'b0;
  RD = 1'b1;
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
      
      decode instr(.instr(DataIn), 
                   .dstAddr(dst),
                   .addr1(addr1), 
                   .addr2(addr2), 
                   .cycleCount(count),
                   .functype(code));
                   
      picker ofOps(.functype(code),
                   .vectorData1(vectorData1),
                   .vectorData2(vectorData2),
                   .scalarData1(scalarData1),
                   .scalarData2(scalarData2),
                   .immediate(immediate),
                   .op1(op1),
                   .op2(op2));
                   
      cycles = 4'h0;
      
      if(code == VLD)
        nextState = Load;
      else if(code == VST || code == SST)
        nextState = Store;
      else
        nextState = Execute;
    end
    
    Execute: begin
      RD = 1'b0;
      WR = 1'b0;
      
      // Apply inputs to the function file max wrote here
      
      if(cycles == count)
        cycles = 4'h0;
        nextState = WriteBack;
      else
        cycles = cycles + 1;
    end
    
    Load: begin
      Addr = op1 + cycles;
      RD = 1'b1;
      WR = 1'b0;
      
      if(cycles > 0)
        if(loadVector)
          vectorToLoad[((16*cycles)-1) -: 15] = DataIn;
        else
          scalarToLoad = DataIn;
          
      if(cycles == count)
        cycles = 4'h0;
        nextState = WriteBack;
      else
        cycles = cycles + 1;
    end
    
    Store: begin
      Addr = op1 + cycles
      RD = 1'b0;
      WR = 1'b1;
      
      if(cycles == count)
        nextState = Fetch;
      else
        cycles = cycles + 1;
    end
    
    WriteBack: begin
      
    end
    
    default:
      nextState = Fetch
end

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
endmodule
