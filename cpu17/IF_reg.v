module IF_reg(
input           clk,
input           reset,
input           valid,

input           Pre_IF_ready_go,
input           Exception,
input [31:0]    exc_pc,

input           quit_Exception,
input [31:0]    quit_pc,

input [32:0]    ID_Data,

input [31:0]    pc,
input [31:0]    inst_sram_rdata,

input           is_block,
input           is_div_block,
input           is_divu_block,
input           is_axi_block,
output          br_block,

output  [31:0]  nextpc,
output          pc_r,

input               IF_ID_allowin,
output wire         inst_sram_req,
output wire         inst_sram_wr,
output wire  [1:0]  inst_sram_size,
output wire  [3:0]  inst_sram_wstrb,
output wire [31:0]  inst_sram_addr,
output wire [31:0]  inst_sram_wdata,
input  wire         inst_sram_addr_ok,
input  wire         inst_sram_data_ok,

output  reg         is_use,

input               Pre_IF_allowin,

output [64:0]   out_data
);

wire         br_taken;
wire  [31:0] br_target;

wire         is_adef;
reg          csr_in_pc_use;
reg          csr_out_pc_use;
reg          is_inst_block;
assign {
    br_taken,
    br_target
}=ID_Data;

assign br_block = br_taken | Exception | quit_Exception | csr_in_pc_use | csr_out_pc_use;

assign pc_r           = inst_sram_addr_ok & inst_sram_req;
                            
assign nextpc = ((Exception | csr_in_pc_use) ? exc_pc :
                            (quit_Exception | csr_out_pc_use) ? quit_pc : 
                                            (br_taken ? br_target : pc+4));

assign inst_sram_req = reset ? 1'b1 : (!is_axi_block & !is_block & !is_div_block & !is_divu_block & Pre_IF_allowin & !is_inst_block);
assign inst_sram_wr  = 1'b0;
assign inst_sram_size = 2'b11;
assign inst_sram_addr = nextpc;
assign inst_sram_wstrb = 1'b0;
assign inst_sram_wdata = 32'h0000_0000;

always @(posedge clk) begin
    if (reset) begin
        is_inst_block = 1'b0;
    end else if (pc_r) begin
        is_inst_block = 1'b1;
    end else if (inst_sram_data_ok) begin
        is_inst_block = 1'b0;
    end
end


always @(posedge clk) begin
    if(reset) begin
        csr_in_pc_use = 1'b0;
    end
    if(Exception) begin
        csr_in_pc_use = 1'b1;
    end
    if (inst_sram_req & inst_sram_addr_ok) begin
        csr_in_pc_use = 1'b0;
    end
end


always @(posedge clk) begin
    if(reset) begin
        csr_out_pc_use = 1'b0;
    end
    if(quit_Exception) begin
        csr_out_pc_use = 1'b1;
    end
    if (inst_sram_req & inst_sram_addr_ok) begin
        csr_out_pc_use = 1'b0;
    end
end

reg [31:0] is_use_inst; 
wire    [31:0] inst;

always @(posedge clk) begin
    if (reset) begin
        is_use = 1'b0;
    end else if ((is_axi_block | is_block | is_div_block | is_divu_block) & inst_sram_data_ok) begin
        is_use = 1'b1;
        is_use_inst = inst_sram_rdata;
    end else if (Pre_IF_ready_go) begin
        is_use = 1'b0;
    end
end

assign inst = is_use ? is_use_inst : inst_sram_rdata;

// assign inst_sram_addr = nextpc;
// assign inst_sram_en   = reset ? 1'b1 : ((!is_block & !is_div_block & !is_divu_block) | Exception);
// assign inst_sram_we   = 1'b0;
// assign inst_sram_wdata = 32'h0000_0000;

assign is_adef = (nextpc[1:0] != 0);

assign out_data = {
    pc,
    inst,
    is_adef
};
endmodule
