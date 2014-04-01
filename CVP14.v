module CVP14(output [15:0] Addr, output RD, output WR, output V, output U, output [15:0] dataOut, 
            input Reset, input Clk1, input Clk2, input [15:0] DataIn);
wire enable, ready;
wire [2:0] addr1, addr2, wrDst;
wire[3:0] opCode;
wire [15:0] scalarData1, scalarData2, scalarWrData, instrAddr, dataAddr, addr;
wire [255:0] vectorData1, vectorData2, vectorWrData;

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

localparam vector = 1'b1;
localparam scalar = 1'b0;

PC pc(.Clk1(Clk1), .Clk2(Clk2), .rst(Reset), .next(ready), .nextAddr(nextAddr), .iAddr(instrAddr));
            
VectorRegFile vrf(.clk(Clk1), .rd_addr_1(addr1), .rd_addr_2(addr2), .wr_dst(wrDst),
                  .wr_data(wrData), .wr_en(enable), .data_1(vectorData1), .data_2(vectorData2));
                  
ScalarRegFile srf(.clk(Clk1), .rd_addr_1(addr1), .rd_addr_2(addr2), .wr_dst(wrDst),
                  .wr_data(wrData), .wr_en(enable), .data_1(scalarData1), .data_2(scalarData2));

ALU alu();

staticram DRAM(.DataOut(), .Addr(addr), .DataIn(), .clk1(), .clk2(), .RD(), .WR());

assign addr = ready ? instrAddr : dataAddr;

/* Set control signals */
always@(posedge Clk1, posedge Clk2) begin
  if(ready) begin /* Reevaluate control signals */
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
    default: /* NOP*/  
      begin
        addr1 = ;
        addr2 = ;
      end
  endcase
  end
end
endmodule
