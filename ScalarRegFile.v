module ScalarRegFile (rd_addr_1, rd_addr_2, wr_dst, wr_data, wr_en, data_1, data_2);

input wr_en;
input [2:0] rd_addr_1, rd_addr_2, wr_dst;
input [15:0] wr_data;

output [15:0] data_1, data_2;

reg [7:0] regTable [15:0];

assign data_1 = regTable[rd_addr_1];
assign data_2 = regTable[rd_addr_2];
  
always
  if (wr_en)
    regTable[wr_dst] = wr_data;
  else
    regTable[wr_dst] = regTable[wr_dst];

endmodule
