module ScalarRegFile (rd_addr_1, rd_addr_2, wr_dst, wr_data, wr_en, data_1, data_2);

input wr_en;
input [3:0] rd_addr_1, rd_addr_2, wr_dst;
input [15:0] wr_data;

output [15:0] data_1, data_2;



endmodule
