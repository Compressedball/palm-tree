
module alu(
  input  wire        clk,
  input  wire        reset,
  input  wire [15:0] alu_op,
  input  wire        is_upper,
  input  wire [31:0] alu_src1,
  input  wire [31:0] alu_src2,
  output wire [31:0] alu_result,
  output wire        div_valid,
  output wire        divu_valid,

  input  wire        ID_EXE_valid
);

wire op_add;   //add operation
wire op_sub;   //sub operation
wire op_slt;   //signed compared and set less than
wire op_sltu;  //unsigned compared and set less than
wire op_and;   //bitwise and
wire op_nor;   //bitwise nor
wire op_or;    //bitwise or
wire op_xor;   //bitwise xor
wire op_sll;   //logic left shift
wire op_srl;   //logic right shift
wire op_sra;   //arithmetic right shift
wire op_lui;   //Load Upper Immediate

wire op_mul;
wire op_mulu;
wire op_div;
wire op_divu;

// control code decomposition
assign op_add  = alu_op[ 0];
assign op_sub  = alu_op[ 1];
assign op_slt  = alu_op[ 2];
assign op_sltu = alu_op[ 3];
assign op_and  = alu_op[ 4];
assign op_nor  = alu_op[ 5];
assign op_or   = alu_op[ 6];
assign op_xor  = alu_op[ 7];
assign op_sll  = alu_op[ 8];
assign op_srl  = alu_op[ 9];
assign op_sra  = alu_op[10];
assign op_lui  = alu_op[11];
assign op_mul  = alu_op[12];
assign op_mulu = alu_op[13];
assign op_div  = alu_op[14];
assign op_divu = alu_op[15];

wire [31:0] add_sub_result;
wire [31:0] slt_result;
wire [31:0] sltu_result;
wire [31:0] and_result;
wire [31:0] nor_result;
wire [31:0] or_result;
wire [31:0] xor_result;
wire [31:0] lui_result;
wire [31:0] sll_result;
wire [63:0] sr64_result;
wire [31:0] sr_result;
wire [63:0] mul_result;
wire [31:0] finial_mul_result;
wire [63:0] mulu_result;
wire [31:0] finial_mulu_result;


// 32-bit adder
wire [31:0] adder_a;
wire [31:0] adder_b;
wire        adder_cin;
wire [31:0] adder_result;
wire        adder_cout;

assign adder_a   = alu_src1;
assign adder_b   = (op_sub | op_slt | op_sltu) ? ~alu_src2 : alu_src2;  //src1 - src2 rj-rk
assign adder_cin = (op_sub | op_slt | op_sltu) ? 1'b1      : 1'b0;
assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;

// ADD, SUB result
assign add_sub_result = adder_result;

// SLT result
assign slt_result[31:1] = 31'b0;   //rj < rk 1
assign slt_result[0]    = (alu_src1[31] & ~alu_src2[31])
                        | ((alu_src1[31] ~^ alu_src2[31]) & adder_result[31]);

// SLTU result
assign sltu_result[31:1] = 31'b0;
assign sltu_result[0]    = ~adder_cout;

// bitwise operation
assign and_result = alu_src1 & alu_src2;
assign or_result  = alu_src1 | alu_src2;
assign nor_result = ~or_result;
assign xor_result = alu_src1 ^ alu_src2;
assign lui_result = alu_src2;

// SLL result
assign sll_result = alu_src1 << alu_src2[4:0];   //rj << i5

// SRL, SRA result
assign sr64_result = {{32{op_sra & alu_src1[31]}}, alu_src1[31:0]} >> alu_src2[4:0]; //rj >> i5

assign sr_result   = sr64_result[31:0];

assign mul_result = $signed(alu_src1) * $signed(alu_src2);
assign finial_mul_result = is_upper ? mul_result[63:32] : mul_result[31:0];

assign mulu_result = alu_src1 * alu_src2;
assign finial_mulu_result = is_upper ? mulu_result[63:32] : mulu_result[31:0];


wire          signed_data_in_tvalid;
wire          divisor_tready;
wire          dividend_tready;
wire [63:0]   div_result;
wire [31:0]   finial_div_result;

reg           signed_data_sent;

assign signed_data_in_tvalid = ID_EXE_valid & op_div & !signed_data_sent;
always @(posedge clk) begin
  if(reset) begin
    signed_data_sent <= 1'b0;
  end else if (signed_data_in_tvalid & divisor_tready) begin
    signed_data_sent <= 1'b1;
  end else if (div_valid) begin
    signed_data_sent <= 1'b0;
  end
end

Signed_div signed_div(
    .aclk(clk),                             // input wire aclk
    .s_axis_divisor_tvalid(signed_data_in_tvalid), // input wire s_axis_divisor_tvalid
    .s_axis_divisor_tdata(alu_src2),         // input wire [15 : 0] s_axis_divisor_tdata
    .s_axis_divisor_tready(divisor_tready),
    .s_axis_dividend_tvalid(signed_data_in_tvalid),// input wire s_axis_dividend_tvalid
    .s_axis_dividend_tdata(alu_src1),       // input wire [15 : 0] s_axis_dividend_tdata
    .s_axis_dividend_tready(dividend_tready),
    .m_axis_dout_tvalid(div_valid),         // output wire m_axis_dout_tvalid
    .m_axis_dout_tdata(div_result) 
);
assign finial_div_result = is_upper ? div_result[63:32] : div_result[31:0];


wire          unsigned_data_in_tvalid;
wire          unsigned_divisor_tready;
wire          unsigned_dividend_tready;
wire [63:0]   divu_result;
wire [31:0]   finial_divu_result;

reg           unsigned_data_sent;

assign unsigned_data_in_tvalid = ID_EXE_valid & op_divu & !unsigned_data_sent;
always @(posedge clk) begin
  if(reset) begin
    unsigned_data_sent <= 1'b0;
  end else if (unsigned_data_in_tvalid & unsigned_divisor_tready) begin
    unsigned_data_sent <= 1'b1;
  end else if (divu_valid) begin
    unsigned_data_sent <= 1'b0;
  end
end

Unsigned_div unisigned_div(
    .aclk(clk),                             // input wire aclk
    .s_axis_divisor_tvalid(unsigned_data_in_tvalid), // input wire s_axis_divisor_tvalid
    .s_axis_divisor_tdata(alu_src2),         // input wire [15 : 0] s_axis_divisor_tdata
    .s_axis_divisor_tready(unsigned_divisor_tready),
    .s_axis_dividend_tvalid(unsigned_data_in_tvalid),// input wire s_axis_dividend_tvalid
    .s_axis_dividend_tdata(alu_src1),       // input wire [15 : 0] s_axis_dividend_tdata
    .s_axis_dividend_tready(unsigned_dividend_tready),
    .m_axis_dout_tvalid(divu_valid),         // output wire m_axis_dout_tvalid
    .m_axis_dout_tdata(divu_result) 
);
assign finial_divu_result = is_upper ? divu_result[63:32] : divu_result[31:0];



// final result mux
assign alu_result = ({32{op_add|op_sub}} & add_sub_result)
                  | ({32{op_slt       }} & slt_result)
                  | ({32{op_sltu      }} & sltu_result)
                  | ({32{op_and       }} & and_result)
                  | ({32{op_nor       }} & nor_result)
                  | ({32{op_or        }} & or_result)
                  | ({32{op_xor       }} & xor_result)
                  | ({32{op_lui       }} & lui_result)
                  | ({32{op_sll       }} & sll_result)
                  | ({32{op_srl|op_sra}} & sr_result)
                  | ({32{op_mul       }} & finial_mul_result)
                  | ({32{op_mulu      }} & finial_mulu_result)
                  | ({32{op_div       }} & finial_div_result)
                  | ({32{op_divu      }} & finial_divu_result);


endmodule
