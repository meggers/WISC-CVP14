module CVP14(output [15:0] Addr, output RD, output WR, output V, output U, output [15:0] dataOut, 
            input Reset, input Clk1, input Clk2, input [15:0] DataIn);
reg enable;
reg [2:0] addr1, addr2, wrDst;
reg [3:0] opCode;
reg [255:0] data1, data2, wrData;

parameter VADD = 4'b0000;
parameter VDOT = 4'b0001;
parameter SMUL = 4'b0010;
parameter SST = 4'b0011;
parameter VLD = 4'b0100;
parameter VST = 4'b0101;
parameter SLL = 4'b0110;
parameter SLH = 4'b0111;
parameter J = 4'b1000;
parameter NOP = 4'b1111;
            
VectorRegFile vrf(.clk(Clk1), .rd_addr_1(addr1), .rd_addr_2(addr2), .wr_dst(wrDst),
                  .wr_data(wrData), .wr_en(enable), .data_1(data1), .data_2(data2));
ScalarRegFile srf(.clk(Clk1), .rd_addr_1(addr1), .rd_addr_2(addr2), .wr_dst(wrDst),
                  .wr_data(wrData), .wr_en(enable), .data_1(data1), .data_2(data2));
ALU alu();
//VADD vadd();
//vadd vadd1(.clk(Clk1), .op_1(data1), .op_2(data2), .sum(wrData));

always@(*) begin
  opCode[3:0] = DataIn[15:12];
  case(opCode)
    VADD:begin addr1 <= DataIn[8:6];
           addr2 <= DataIn[5:3];
           enable <= 0;
           
         end
      
    
    default: $display("error");
  endcase
end
endmodule
