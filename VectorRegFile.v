module VectorRegFile (rd_addr_1, rd_addr_2, wr_dst, wr_data, wr_en, data_1, data_2);

input wr_en;
input [2:0] rd_addr_1, rd_addr_2, wr_dst;
input [255:0] wr_data;

output reg [255:0] data_1, data_2;

reg [7:0] regTable [255:0];

always @() begin
  data_1 = regTable[rd_addr_1];
  data_2 = regTable[rd_addr_2];
            
  if (wr_en) begin
    regTable[wr_dst] = wr_data;
  end
end

endmodule
