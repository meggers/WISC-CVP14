module ScalarRegFile (rst, rd_addr_1, rd_addr_2, wr_dst, wr_data, wr_en, data_1, data_2);

input wr_en, rst;
input [2:0] rd_addr_1, rd_addr_2, wr_dst;
input [15:0] wr_data;

output [15:0] data_1, data_2;

reg [15:0] regTable [0:7];

assign data_1 = regTable[rd_addr_1];
assign data_2 = regTable[rd_addr_2];
  
always @(wr_en, rst)
  if(rst) begin // Clear the registers
    regTable[7] = 16'h0000;
    regTable[6] = 16'h0000;
    regTable[5] = 16'h0000;
    regTable[4] = 16'h0000;
    regTable[3] = 16'h0000;
    regTable[2] = 16'h0000;
    regTable[1] = 16'h0000;
    regTable[0] = 16'h0000;
  end else if (wr_en)
    regTable[wr_dst] = wr_data;

endmodule
