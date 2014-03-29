// Peter Collins, Matthew Wiemer, Luke Brandl
module ALU(src0, src1, ctrl, shamt, aluOp, dst, old_ov, old_zr, old_ne, ov, zr, ne);
  input [15:0] src0, src1;
  input [2:0] ctrl;
  input [3:0] shamt;
	input aluOp, old_ov, old_zr, old_ne;
	
  output [15:0] dst;
	output ov, zr, ne;

  wire [15:0] unsat, op1;

  localparam add = 3'b000; // Accounts for both add and addz
  localparam lhb = 3'b001;
  localparam sub = 3'b010;
  localparam andy = 3'b011;
  localparam nory = 3'b100;
  localparam sll = 3'b101;
  localparam srl = 3'b110;
  localparam sra = 3'b111;

  assign unsat = (ctrl==add) ? src0+src1:
                 (ctrl==lhb) ? {src1[15:8], src0[7:0]}:
                 (ctrl==sub) ? src0-src1:
                 (ctrl==andy)? src0&src1:
                 (ctrl==nory)? ~(src0|src1):
                 (ctrl==sll) ? src1<<shamt:
                 (ctrl==srl) ? src1>>shamt:
		 (ctrl==sra) ? {$signed(src1) >>> shamt}:
                 17'h00000; // It will never reach here logically

 	// When checking msbs for overflow, we need the actual bits operated on
	assign op1 = ctrl==sub ? ~src1 + 1'b1 : src1;          

  assign doingMath = ctrl==add || ctrl==sub; // i.e. set N and Z
  // Positive operands; Negative result
	assign negativeOverflow =(src0[15] && op1[15] && !unsat[15]);
  // Negative operands; Positive result
	assign positiveOverflow = (!src0[15] && !op1[15] && unsat[15]);
	// Determine zero from the unsaturated result!
	//assign zero = ~|unsat;

  // Set Result
  assign dst = (positiveOverflow && doingMath) ? 16'h7fff :
               (negativeOverflow && doingMath) ? 16'h8000 : unsat;


  assign ov = doingMath ? (positiveOverflow || negativeOverflow) : old_ov;

  assign zr = aluOp ? ~|dst : old_zr;

  assign ne = doingMath ? dst[15] : old_ne;
  
endmodule
  
module ALU_tb();
  reg [15:0] src0, src1;
  reg [2:0] ctrl;
  reg [3:0] shamt;

  wire [15:0] dst;
  wire ov, zr;

  ALU iDUT(.src0(src0), .src1(src1), .ctrl(ctrl), .shamt(shamt), .ov(ov), .zr(zr), .dst(dst));

  initial begin
    addChk(16'h0000, 16'h0000);
    addChk(16'h0001, 16'h0000);
    addChk(16'h0001, 16'h0001);
    addChk(16'hffff, 16'h0000);
    addChk(16'h8888, 16'h8888);
    addChk(16'hffff, 16'hffff);

    subChk(16'h0000, 16'h0000);
    subChk(16'h0001, 16'h0000);
    subChk(16'h0001, 16'h0001);
    subChk(16'hffff, 16'h0000);
    subChk(16'h8888, 16'h8888);
    subChk(16'hffff, 16'hffff);
    subChk(16'h0000, 16'h0001);
    subChk(16'h8888, 16'hffff);
    subChk(16'h0000, 16'hffff);

    andChk(16'h0000, 16'h0000);
    andChk(16'h0001, 16'h0000);
    andChk(16'h0001, 16'h0001);
    andChk(16'hffff, 16'h0000);
    andChk(16'h8888, 16'h8888);
    andChk(16'hffff, 16'hffff);

    norChk(16'h0000, 16'h0000);
    norChk(16'h0001, 16'h0000);
    norChk(16'h0001, 16'h0001);
    norChk(16'hffff, 16'h0000);
    norChk(16'h8888, 16'h8888);
    norChk(16'hffff, 16'hffff);

    sllChk(16'h0000, 4'h0);
    sllChk(16'h0001, 4'h0);
    sllChk(16'h0001, 4'hf);
    sllChk(16'hffff, 4'h0);
    sllChk(16'h8888, 4'h8);
    sllChk(16'hffff, 4'hf);

    srlChk(16'h0000, 4'h0);
    srlChk(16'h0001, 4'h0);
    srlChk(16'h0001, 4'hf);
    srlChk(16'hffff, 4'h0);
    srlChk(16'h8888, 4'h8);
    srlChk(16'hffff, 4'hf);

    sraChk(16'h0000, 4'h0);
    sraChk(16'h0001, 4'h0);
    sraChk(16'h0001, 4'hf);
    sraChk(16'hffff, 4'h0);
    sraChk(16'h8888, 4'h8);
    sraChk(16'hffff, 4'hf);

    lhbChk(16'h0000);
    lhbChk(16'h0001);
    lhbChk(16'h8888);
    lhbChk(16'hffff);
  end

  task addChk;
     input reg [15:0] insrc0, insrc1;
     begin
        src0 = insrc0;
        src1 = insrc1;
        ctrl = 3'b000;
        shamt = 4'b0000;
        #5;
        $display("Addition %h + %h = %h ov=%d zr=%d", src0, src1, dst, ov, zr);
        if (dst!=(src0+src1)&&(((src0+src1)>16'hffff)||ov!=1)&&((~|(src0+src1))!=zr))
        begin
           // Display the error
           $display("Error: Addition not working correctly!");
           $stop();
        end
     end
  endtask

  task subChk;
     input reg [15:0] insrc0, insrc1;
     begin
        src0 = insrc0;
        src1 = insrc1;
        ctrl = 3'b001;
        shamt = 4'b0000;
        #5;
        $display("Subtraction %h - %h = %h ov=%d zr=%d", src0, src1, dst, ov, zr);
        if (dst!=(src0-src1)&&(((src0-src1)<16'h0000)||ov!=1)&&((~|(src0-src1))!=zr))
        begin
           // Display the error
           $display("Error: Subtraction not working correctly!");
           $stop();
        end
     end
  endtask

  task andChk;
     input reg [15:0] insrc0, insrc1;
     begin
        src0 = insrc0;
        src1 = insrc1;
        ctrl = 3'b010;
        shamt = 4'b0000;
        #5;
        $display("And %h & %h = %h zr=%d", src0, src1, dst, zr);
        if (dst!=(src0&src1)&&((~|(src0&src1))!=zr))
        begin
           // Display the error
           $display("Error: And not working correctly!");
           $stop();
        end
     end
  endtask
  task norChk;
     input reg [15:0] insrc0, insrc1;
     begin
        src0 = insrc0;
        src1 = insrc1;
        ctrl = 3'b011;
        shamt = 4'b0000;
        #5;
        $display("Nor %h ~| %h = %h zr=%d", src0, src1, dst, zr);
        if (dst!=~(src0|src1)&&((~|(src0|src1))!=zr))
        begin
           // Display the error
           $display("Error: Nor not working correctly!");
           $stop();
        end
     end
  endtask
  task sllChk;
     input reg [15:0] insrc0;
     input reg [3:0] inshamt;
     begin
        src0 = insrc0;
        src1 = 16'h0000;
        ctrl = 3'b100;
        shamt = inshamt;
        #5;
        $display("Shift Left Logical %h << %h = %h zr=%d", src0, shamt, dst, zr);
        if (dst!=src0<<shamt&&((~|(src0<<shamt))!=zr))
        begin
           // Display the error
           $display("Error: Shift Left Logical not working correctly!");
           $stop();
        end
     end
  endtask

  task srlChk;
     input reg [15:0] insrc0;
     input reg [3:0] inshamt;
     begin
        src0 = insrc0;
        src1 = 16'h0000;
        ctrl = 3'b101;
        shamt = inshamt;
        #5;
        $display("Shift Right Logical %h >> %h = %h zr=%d", src0, shamt, dst, zr);
        if (dst!=src0>>shamt&&((~|(src0>>shamt))!=zr))
        begin
           // Display the error
           $display("Error: Shift Right Logical not working correctly!");
           $stop();
        end
     end
  endtask

  task sraChk;
     input reg [15:0] insrc0;
     input reg [3:0] inshamt;
     begin
        src0 = insrc0;
        src1 = 16'h0000;
        ctrl = 3'b110;
        shamt = inshamt;
        #5;
        $display("Shift Right Arithmetic %h >>> %h = %h zr=%d", src0, shamt, dst, zr);
        if (dst!=src0>>>shamt&&((~|(src0>>>shamt))!=zr))
        begin
           // Display the error
           $display("Error: Shift Right Arithmetic not working correctly!");
           $stop();
        end
     end
  endtask
  task lhbChk;
     input reg [15:0] insrc0;
     begin
        src0 = insrc0;
        src1 = 16'h0000;
        ctrl = 3'b111;
        shamt = 4'h0;
        #5;
        $display("Load High Byte lhb %h = %h zr=%d", src0, dst, zr);
        if (dst!={src0[15:8],8'h00}&&((~|({src0[15:8],8'h00}))!=zr))
        begin
           // Display the error
           $display("Error: Load High Byte not working correctly!");
           $stop();
        end
     end
  endtask
endmodule
