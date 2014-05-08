`timescale 1 ns / 1 ps
module PROJECT_TB;
parameter CLK = 16;
localparam CLK_FOUR = CLK/4;
localparam MEMSIZE = 65536;
localparam WORDSIZE = 16;

wire [15:0] Addr, DataOut, DataIn;
wire RD, WR, V;
reg Reset, Clk1, Clk2;
reg dump;
reg run;

CVP14 DUT(Addr, RD, WR, V, DataOut, Reset, Clk1, Clk2, DataIn);
testmem DRAM(DataIn, Addr, DataOut, Clk1, Clk2, RD, WR, dump);



//Clock Generator
always begin
	Clk1 <= 1'b1;
	#(CLK_FOUR);
	Clk1 <= 1'b0;
	#(CLK_FOUR);
	Clk2 <= 1'b1;
	#(CLK_FOUR);
	Clk2 = 1'b0;
	#(CLK_FOUR);

end



initial begin
	run = 1'b0;
	dump = 1'b0;
	Clk1 = 1'b0;
	Clk2 = 1'b0;
	Reset = 1'b0;

//LOAD THE MEMORY
	//mem_load;
	

//RUN UNTIL CONDITION IS MET
	run = 1'b1;
	Reset = 1'b1;
	@(posedge Clk1);
	@(posedge Clk1);
	@(posedge Clk1) Reset = 1'b0;

//DUMP/CHECK THE MEMORY
//The checkpoint conditions is very simple: access to memory address 0xFFFF
// We're also going to set a time limit to 100K clock cycles.
	#(CLK_FOUR*4*100000);
	$display("Time limit reach, we'll dump what we got.");
	dump = 1'b1;
	#5;
	$finish;

end

always@(Addr) begin
	//END OF TESTBENCH CONDITION
	$display("Addr = %h", Addr);
	if(Addr == 16'hffff) begin
		$display("MEM DUMP!");
		dump = 1'b1;
		#5;
		$finish;
	end
end









endmodule
module testmem(DataOut, Addr, DataIn, clk1, clk2, RD, WR, dump);
parameter WordSize=16;
parameter AddrWidth=16;
localparam MemSize  = (1 << AddrWidth);
input dump;
input [AddrWidth-1:0] Addr;
input [WordSize-1:0]  DataIn;
output reg [WordSize-1:0]  DataOut;
input clk1, clk2, RD, WR;

reg [AddrWidth-1:0] mAddr;
reg [WordSize-1:0] Memory [0:MemSize-1];
reg [WordSize-1:0] mData;

integer file;
integer i;
reg header;
always@(posedge dump) begin
   $display("Memory is beginning dump!");
   file = $fopen("dump.list");
   header = 1'b0;
   for(i = 0; i < MemSize; i = i + 1) begin
      if(Memory[i] == 0)
         header = 1'b1;
      else if (header == 1'b1) begin
         header = 1'b0;
         $fwrite(file, "@(%d)\n", i);
      end
      if(header == 1'b0)
         $fwrite(file, "%b\n", Memory[i]);
   end
   $fclose(file);
   $finish;
end

always @(posedge clk1) begin
   if (RD == 1'b1) begin
        DataOut <= Memory[mAddr];
		$display("Read of %h from %h", Memory[mAddr], mAddr);
//        $strobe($time, " clk1 = %b clk2 = %b MemAddr = %d DataOut = %d\n", clk1, clk2, mAddr, DataOut);
   end
   else begin
        if (WR == 1'b1) begin
           Memory[mAddr] <= DataIn;
		$display("Write of %h to %h", DataIn, mAddr);
//           $strobe($time, " clk1 = %b clk2 = %b MemAddr = %d DataIn = %d\n", clk1, clk2, mAddr, DataIn);
        end
        else begin
             DataOut <= {WordSize{1'bx}};
        end
   end
end
always @(posedge clk2) begin
    mAddr <= Addr;
end

initial begin
  $readmemb("mem.list", Memory);
end
endmodule

