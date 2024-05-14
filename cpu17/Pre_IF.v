module Pre_IF(
    input           clk,
    input           reset,

    input           is_div_block,
    input           is_divu_block,
    input           is_block,
    input           br_block,
    input           is_axi_block,

    output          in_allowin,
    input           in_valid,//进来的valid,为1

    input           out_allowin,//对方允不允许接收
    output          out_valid,//传走的valid

    input           is_use,
    input           inst_sram_data_ok,

    output          ready_go
);
reg         valid;

assign ready_go      =  (inst_sram_data_ok | is_use) & !is_axi_block & !is_block & !is_div_block & !is_divu_block & !br_block;
assign in_allowin       = !valid | (ready_go & out_allowin) | (br_block & !is_block & ! is_div_block & !is_divu_block & !is_axi_block);//为空 或 不为空且发送且接收
assign out_valid   = valid && ready_go;

always @(posedge clk) begin
    if(reset) begin
        valid <= 1'b0;
    end 
    else if (in_allowin) begin
        valid <= in_valid;
    end
end
endmodule