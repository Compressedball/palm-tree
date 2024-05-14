module IF_ID_reg(
    input           clk,
    input           reset,

    input           empty,

    input           is_div_block,
    input           is_divu_block,
    input           is_block,
    input           is_axi_block,
    
    output          in_allowin,
    input           in_valid,//进来的valid,为1
    input    [64:0] in_data,

    input           out_allowin,//对方允不允许接收
    output          out_valid,//传走的valid
    output reg [65:0] out_data,

    output reg        valid,
    
    input             br_block,
    input             inst_sram_addr_ok,
    input             inst_sram_req,
    output            ready_go
);
//wire        ready_go;//流水线缓存格式(¬､¬)

assign ready_go      = !is_block & !is_div_block & !is_divu_block & !is_axi_block & (!br_block | (inst_sram_addr_ok & inst_sram_req));
assign in_allowin       = !valid || ready_go && out_allowin;//为空 或 不为空且发送且接收
assign out_valid   = valid && ready_go;

always @(posedge clk) begin
    if(reset) begin
        valid <= 1'b0;
    end 
    else if (in_allowin) begin
        valid <= in_valid;
    end
    if(empty) begin
        out_data <= 0;
    end
    else if (in_valid && out_allowin) begin
        out_data <= {in_data,1'b1};
    end
end
endmodule