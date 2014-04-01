module ScalarRegFile (clk1, clk2, rd_addr_1, rd_addr_2, wr_dst, wr_data, wr_en, data_1, data_2);

input wr_en, clk1, clk2;
input [3:0] rd_addr_1, rd_addr_2, wr_dst;
input [15:0] wr_data;

output reg [15:0] data_1, data_2;

reg [7:0] regTable [15:0];

always @(posedge clk1, posedge clk2) begin
  data_1 = regTable[rd_addr_1];
  data_2 = regTable[rd_addr_2];
  
  if (wr_en) begin
    regTable[wr_dst] = wr_data;
  end
end

endmodule
