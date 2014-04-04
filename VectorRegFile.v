module VectorRegFile (rst, rd_addr_1, rd_addr_2, wr_dst, wr_data, wr_en, data_1, data_2);

input wr_en, rst;
input [2:0] rd_addr_1, rd_addr_2, wr_dst;
input [255:0] wr_data;

output [255:0] data_1, data_2;

reg [255:0] regTable [0:7];

assign data_1 = regTable[rd_addr_1];
assign data_2 = regTable[rd_addr_2];
      
always @(rst, wr_en)
  if(rst) begin // Clear all registers
    regTable[7] = 255'd0;
    regTable[6] = 255'd0;
    regTable[5] = 255'd0;
    regTable[4] = 255'd0;
    regTable[3] = 255'd0;
    regTable[2] = 255'd0;
    regTable[1] = 255'd0;
    regTable[0] = 255'd0;
  end else if (wr_en)
    regTable[wr_dst] <= wr_data;

endmodule
