module CVP14(output [15:0] Addr, output RD, output WR, output V, output [15:0] dataOut, 
            input Reset, input Clk1, input Clk2, input [15:0] DataIn);

/* State Definitions */
localparam Fetch = 4'd0;
localparam Decode = 4'd1;
localparam Execute = 4'd2;
localparam WriteBack = 4'd3;
localparam Load = 4'd4;
localparam Store = 4'd5;
localparam Jump = 4'd6;
localparam ScalarMultiply = 4'd7;
localparam VectorDot = 4'd8;
localparam VectorAdd = 4'd9;

/* Instruction Codes */
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

/* "Global" Variables */
localparam INFINITY = 16'h7C00;

reg vector_en, scalar_en, read, write, flow, overflow, fire;
reg [3:0] state, nextState;
reg [2:0] wrAddr;
reg [3:0] func;
reg [4:0] cycles;
reg [15:0] scalarToLoad,  scalarWrData, nextInstrAddr, memAddr, data, instrIn;
reg [255:0] op1, op2, vectorToLoad, vectorWrData;

wire wr_vector, wr_scalar;
wire [2:0] addr1, addr2, addrDst;
wire [3:0] code;
wire [4:0] count;
wire [5:0] offset;
wire [7:0] immediate;
wire [11:0] jumpOffset;
wire [15:0] scalarData1, scalarData2;
wire [255:0] data1, data2, vectorData1, vectorData2, result;

VectorRegFile vrf(.rst(Reset),
                  .rd_addr_1(addr1), 
                  .rd_addr_2(addr2), 
                  .wr_dst(wrAddr),
                  .wr_data(vectorWrData), 
                  .wr_en(vector_en), 
                  
                  .data_1(vectorData1), 
                  .data_2(vectorData2));
                  
ScalarRegFile srf(.rst(Reset),
                  .rd_addr_1(addr1), 
                  .rd_addr_2(addr2), 
                  .wr_dst(wrAddr),
                  .wr_data(scalarWrData), 
                  .wr_en(scalar_en), 
                  
                  .data_1(scalarData1), 
                  .data_2(scalarData2));
                  
ALU alu(.op_1(op1), 
        .op_2(op2), 
        .opcode(func), 
        
        .result(result));
                  
decode instr(.instr(instrIn), /* In */
      
              .v_en(wr_vector), /* Out */
              .s_en(wr_scalar),
              .dstAddr(addrDst),
              .addr1(addr1), 
              .addr2(addr2),
              .immediate(immediate), 
              .offset(offset),
              .cycleCount(count),
              .jumpOffset(jumpOffset),
              .functype(code));
                   
picker ofOps(.functype(code),  /* In */
             .vectorData1(vectorData1),
             .vectorData2(vectorData2),
             .scalarData1(scalarData1),
             .scalarData2(scalarData2),
             .immediate(immediate),
             .offset(offset),
             .jumpOffset(jumpOffset),
             .PC(memAddr),
                   
             .op1(data1), /* Out */
             .op2(data2));  
             
// The registers on the right hand side will only be asserted at the correct times.
assign RD = read;
assign WR = write;
assign V = flow;
assign Addr = memAddr;
assign dataOut = data;          
                  
/* Flop the new state in, using only one always block makes it much more likely
    that latches will be synthesized, which is undesirable */
always @(posedge Clk1)
  if(Reset) begin
    state <= Fetch;
    fire <= 1'b0; 
  end else begin
    state <= nextState;
    fire <= ~fire; // Force re-eval, ***doesn't simulate correctly if the other always block is @(posedge Clk1)***
  end
    
/* Determine what the inputs represent and what the outputs should be based on 
    the current state */ 
always @(fire) begin
  // Set to default values, again for avoiding latches (HA...)
  nextState = Fetch;
  vector_en = 1'b0;
  vectorWrData = 256'd0;
  scalarWrData = 16'd0;
  scalar_en = 1'b0;
  read = 1'b0;
  write = 1'b0;
  data = 16'h0000;
  
  if(Reset) begin// Make sure that nextInstrAddr has mutually exclusive assignements
    nextInstrAddr = 16'h0000;
    flow = 1'b0;
    overflow = 1'b0;
  end
  
  case(state)
    Fetch: begin
      memAddr = nextInstrAddr;
      
      if(~Reset) begin // Make sure that nextInstrAddr has mutually exclusive assignements
        nextInstrAddr = nextInstrAddr + 1;
        flow = overflow;
      end
        
      read = 1'b1;
      nextState = Decode;
    end
   
    Decode: begin
      instrIn = DataIn; /* Outputs of decode and picker are now relevant until
                           the next fetch state, most notably data1 and data2. */
                   
      cycles = 4'h0; // Reset the counter
      
      nextState = Execute;
    end
    
    Execute: begin // State 2
      // Stimulate the ALU
      op1 = data1[15:0];
      op2 = data2[15:0];  
      overflow = 1'b0; // Reset for the executing instruction      
      func = code;
    
      if(code == VADD) begin
        nextState = VectorAdd;      
      end else if(code == VDOT) begin
        nextState = VectorDot;
      end else if(code == SMUL) begin
        nextState = ScalarMultiply;  
      end else if(code == J) begin          
        nextState = Jump;
      end else if(code == VLD)
        nextState = Load;
      else if(code == VST || code == SST)
        nextState = Store;
      else begin // Nothing else to do!
        nextState = WriteBack;
      end
    end
    
    VectorAdd: begin
      // Stimulate the ALU
      op1 = {240'd0, data1[((cycles+1)*16)+15 -: 16]}; // I couldn't tell you why this is -: 16, but it doesn't work with -: 15;
      op2 = {240'd0, data2[((cycles+1)*16)+15 -: 16]}; // I couldn't tell you why this is -: 16, but it doesn't work with -: 15;
      
      if(result == INFINITY) begin // Recognize overflow!
        overflow = 1'b1;
        scalar_en = 1'b1;
        wrAddr = 3'd7;
        scalarWrData = memAddr;
        
        if(~Reset)
          nextInstrAddr = 16'hfff0; // From the spec
      end else
        overflow = overflow;
      
      if(cycles > 0)
        vectorToLoad = vectorToLoad | (result << 16*cycles);
      else
        vectorToLoad = result[15:0];
        
      if(cycles == count)
        nextState = WriteBack;
      else begin
        cycles = cycles + 1;
        nextState = VectorAdd; // Not done yet
      end
    end
    
    VectorDot: begin
      // Stimulate the ALU
      op1 = {240'd0, data1[((cycles+1)*16)+15 -: 16]}; // I couldn't tell you why this is -: 16, but it doesn't work with -: 15;
      op2 = {240'd0, data2[((cycles+1)*16)+15 -: 16]}; // I couldn't tell you why this is -: 16, but it doesn't work with -: 15;
      
      if(result == INFINITY) begin // Recognize overflow!
        overflow = 1'b1;
        scalar_en = 1'b1;
        wrAddr = 3'd7;
        scalarWrData = memAddr;
        
        if(~Reset)
          nextInstrAddr = 16'hfff0; // From the spec
      end else
        overflow = overflow;
      
      if(cycles > 0)
        scalarToLoad = float_add(scalarToLoad, result[15:0]);
      else
        scalarToLoad = result[15:0];
        
      if(cycles == count)
        nextState = WriteBack;
      else begin
        cycles = cycles + 1;
        nextState = VectorDot; // Not done yet
      end
    end
    
    ScalarMultiply: begin
      // Stimulate the ALU
      op1 = {240'd0, data1[((cycles+1)*16)+15 -: 16]}; // I couldn't tell you why this is -: 16, but it doesn't work with -: 15
      op2 = {240'd0, data2[15:0]};
      
      if(cycles > 0)
        vectorToLoad = vectorToLoad | (result << 16*cycles);
      else
        vectorToLoad = {240'd0, result}; // First element doesn't need to be shifted
        
      if(result == INFINITY) begin // Recognize overflow!
        overflow = 1'b1;
        scalar_en = 1'b1;
        wrAddr = 3'd7;
        scalarWrData = memAddr;
        
        if(~Reset)
          nextInstrAddr = 16'hfff0; // From the spec
      end else
        overflow = overflow;
        
      if(cycles == count)
        nextState = WriteBack;
      else begin
        cycles = cycles + 1;
        nextState = ScalarMultiply; // Not done yet
      end
    end
    
    Jump: begin
      if(~Reset)
        nextInstrAddr = result[15:0];
        
      nextState = Fetch;
    end
    
    Load: begin // Where things are forced to take multiple clock cycles
      memAddr = result[15:0] + cycles;
      read = 1'b1;
      
      if(cycles > 0) begin // Else we are still waiting for the first component
        if(cycles > 1)
          vectorToLoad = vectorToLoad | (DataIn << 16*(cycles-1));
        else
          vectorToLoad = vectorToLoad | DataIn; // First element doesn't need to be shifted
      end else
        vectorToLoad = 256'd0; // "Initialize" it
          
      if(cycles == count)
        nextState = WriteBack;
      else begin
        nextState = Load;
        cycles = cycles + 1;
      end
    end
    
    Store: begin // Where things are forced to take multiple clock cycles
      memAddr = result[15:0] + cycles;
      write = 1'b1;
      
      /* Obvious room for inprovement, I couldn't get 
        indexing logic to work and it's crunch time */
      if(cycles == 15)
        data = vectorData2[255:240];
      else if(cycles == 14)
        data = vectorData2[239:224];
      else if(cycles == 13)
        data = vectorData2[223:208];
      else if(cycles == 12)
        data = vectorData2[207:192];
      else if(cycles == 11)
        data = vectorData2[191:176];
      else if(cycles == 10)
        data = vectorData2[175:160];
      else if(cycles == 9)
        data = vectorData2[159:144];
      else if(cycles == 8)
        data = vectorData2[143:128];
      else if(cycles == 7)
        data = vectorData2[127:112];
      else if(cycles == 6)
        data = vectorData2[111:96];
      else if(cycles == 5)
        data = vectorData2[95:80];
      else if(cycles == 4)
        data = vectorData2[79:64];
      else if(cycles == 3)
        data = vectorData2[63:48];
      else if(cycles == 2)
        data = vectorData2[47:32];
      else if(cycles == 1)
        data = vectorData2[31:16];
      else
        if(code == SST)
          data = scalarData2;
        else
          data = vectorData2[15:0];
      
      if(cycles == count)
        nextState = Fetch;
      else begin
        nextState = Store;
        cycles = cycles + 1;
      end
    end
    
    WriteBack: begin
      
      if(wr_vector) begin
        vector_en = 1'b1;
        wrAddr = addrDst;
        
        if(code == VLD || code == SMUL || code == VDOT || code == VADD)
          vectorWrData = vectorToLoad;
        else
          vectorWrData = result;
          
      end else if(wr_scalar) begin
        scalar_en = 1'b1;
        wrAddr = addrDst;
        
        if(code == VDOT)
          scalarWrData = scalarToLoad;
        else
          scalarWrData = result[15:0];
      end
      
      nextState = Fetch;
    end
    
    default:
      nextState = Fetch;
  endcase
end

//http://en.wikipedia.org/wiki/Half-precision_floating-point_format
//http://pages.cs.wisc.edu/~smoler/x86text/lect.notes/arith.flpt.html
//http://users-tima.imag.fr/cis/guyot/Cours/Oparithm/english/Flottan.htm
function [15:0] float_add;
  input [15:0] float_1, float_2;
  
  // Special Case Params
  parameter inf_exponent =  5'b11111,
            inf_mantissa = 10'b0;
  
  // Hidden bit Params
  parameter hidden_bit_high = 1'b1,
            hidden_bit_low  = 1'b0;
            
  // Floating point Params
  parameter sign_bit     = 15,
            exponent_msb = 14,
            exponent_lsb = 10, 
            mantissa_msb = 9,
            mantissa_lsb = 0;
            
  // Rounding Params
  parameter GRS_zero_fill = 15'b0,
            overflow_bit  = 26,
            hidden_bit    = 25,
            sum_msb       = 24,
            sum_lsb       = 15,
            guard_bit     = 14,
            round_bit     = 13,
            sticky_msb    = 12,
	          sticky_lsb    = 0;
            
  reg [4:0] exp_1, exp_2, exp_shifted, exp_diff;
  
  reg [25:0] mantissa_1, mantissa_2; // [1 Hidden bit, 10 Mantissa bits, 1 Guard bit, 1 Round bit, 13 Sticky bits]
  reg [26:0] mantissa_sum;           // [1 Overflow bit, 1 Hidden Bit, 10 Mantissa bits, 1 Guard bit, 1 Round bit, 13 Sticky bits]

  reg sign, overflow;
  reg [3:0] leadingZeros;
  
  begin
    // Set our overflow flag
    overflow = 0;
    
    // Step 1a: Construct exponents 
    exp_1 = float_1[exponent_msb : exponent_lsb];
    exp_2 = float_2[exponent_msb : exponent_lsb];
    
    // Check for infinity
    if (exp_1 == inf_exponent) begin
      overflow = 1;
      sign = float_1[sign_bit];
    end else if (exp_2 == inf_exponent) begin
      overflow = 1;
      sign = float_2[sign_bit];
    end else begin
      // Step 1b: Subtract exponents
      exp_diff = exp_1 - exp_2;
        
      // Step 1c: Construct mantissas (for both normalized and denormalized numbers)
      mantissa_1 = {(|exp_1 ? hidden_bit_high : hidden_bit_low), float_1[mantissa_msb : mantissa_lsb], GRS_zero_fill};
      mantissa_2 = {(|exp_2 ? hidden_bit_high : hidden_bit_low), float_2[mantissa_msb : mantissa_lsb], GRS_zero_fill};   
        
      // Step 1d: Align radix
      // Step 2: Add
      if (exp_2 > exp_1) begin      
        exp_shifted = exp_2;
        mantissa_1 = mantissa_1 >> exp_diff;
      
        sign = float_2[sign_bit];
        mantissa_sum = (float_1[sign_bit] ~^ float_2[sign_bit]) ? mantissa_1 + mantissa_2 : mantissa_2 - mantissa_1;
      end else begin
        exp_shifted = exp_1;
        mantissa_2 = mantissa_2 >> exp_diff;
            
        sign = float_1[sign_bit];
        mantissa_sum = (float_1[sign_bit] ~^ float_2[sign_bit]) ? mantissa_1 + mantissa_2 : mantissa_1 - mantissa_2;  
      end
      
      // Step 3: Normalize result
      if (~|mantissa_sum[overflow_bit : sum_lsb]) begin // If its zero
        exp_shifted = 0;
        mantissa_sum = mantissa_sum;
      end else if (mantissa_sum[overflow_bit]) begin // If there is overflow of mantissa, shift left
        mantissa_sum = mantissa_sum >> 1;
        exp_shifted  = exp_shifted + 1;
        if (&exp_shifted) begin // Overflow of exponent
          overflow = 1;
        end else begin
          overflow = overflow;
        end
      end else if (~mantissa_sum[hidden_bit]) begin // Else if hidden bit is 0
        leadingZeros = numLeadingZeros(mantissa_sum[sum_msb : sum_lsb]);
        mantissa_sum[hidden_bit : round_bit] = mantissa_sum[hidden_bit : round_bit] << leadingZeros;
        exp_shifted  = exp_shifted - leadingZeros;
      end else begin
        mantissa_sum = mantissa_sum;
        exp_shifted  = exp_shifted;
        overflow = overflow;
      end
    
      // Step 4: Round to nearest even
      if (~overflow) begin
        if (mantissa_sum[guard_bit] & (|mantissa_sum[round_bit : sticky_lsb] | mantissa_sum[sum_lsb])) begin
          mantissa_sum = mantissa_sum + 1;
          exp_shifted  = |mantissa_sum[sum_msb : sum_lsb] ? exp_shifted : exp_shifted + 1; // Overflow of Mantissa
          if (&exp_shifted) begin // Overflow of exponent
            overflow = 1;
          end else begin
            overflow = overflow;
          end
        end
      end
      
      // Step 3: Normalize result
      if (~|mantissa_sum[overflow_bit : sum_lsb]) begin // If its zero
        exp_shifted = 0;
        mantissa_sum = mantissa_sum;
      end else if (mantissa_sum[overflow_bit]) begin // If there is overflow of mantissa, shift left
        mantissa_sum = mantissa_sum >> 1;
        exp_shifted  = exp_shifted + 1;
        if (&exp_shifted) begin // Overflow of exponent
          overflow = 1;
        end else begin
          overflow = overflow;
        end
      end else if (~mantissa_sum[hidden_bit]) begin // Else if hidden bit is 0
        leadingZeros = numLeadingZeros(mantissa_sum[sum_msb : sum_lsb]);
        mantissa_sum[hidden_bit : round_bit] = mantissa_sum[hidden_bit : round_bit] << leadingZeros;
        exp_shifted  = exp_shifted - leadingZeros;
      end else begin
        mantissa_sum = mantissa_sum;
        exp_shifted  = exp_shifted;
        overflow = overflow;
      end
    end
    
    // Assemble and Return
    float_add = overflow ? {sign, inf_exponent, inf_mantissa} : {sign, exp_shifted, mantissa_sum[sum_msb : sum_lsb]};
  end
endfunction

function [3:0] numLeadingZeros;
  input [10:0] mantissa;
            
  casex(mantissa)
    11'b1xxxxxxxxxx: numLeadingZeros = 4'd0;
    11'b01xxxxxxxxx: numLeadingZeros = 4'd1;
    11'b001xxxxxxxx: numLeadingZeros = 4'd2;
    11'b0001xxxxxxx: numLeadingZeros = 4'd3;
    11'b00001xxxxxx: numLeadingZeros = 4'd4;
    11'b000001xxxxx: numLeadingZeros = 4'd5;
    11'b0000001xxxx: numLeadingZeros = 4'd6;
    11'b00000001xxx: numLeadingZeros = 4'd7;
    11'b000000001xx: numLeadingZeros = 4'd8;
    11'b0000000001x: numLeadingZeros = 4'd9;
    11'b00000000001: numLeadingZeros = 4'd10;
    default:  numLeadingZeros = 4'd0;
  endcase
                    
endfunction

endmodule
