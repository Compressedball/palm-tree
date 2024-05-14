module MEM_WB_reg(
    input           clk,
    input           reset,

    input           empty,

    output          in_allowin,
    input           in_valid,//进来的valid,为1
    input   [165:0]  in_data,

    input           out_allowin,//对方允不允许接收
    output          out_valid,//传走的valid
    output reg [165:0] out_data,

    output reg        valid,
    input             data_sram_data_ok,
    input             wb_data_req_is_use
);
wire        ready_go;//流水线缓存格式(¬､¬)

//assign ready_go      = data_sram_data_ok;
assign ready_go      = !wb_data_req_is_use | (wb_data_req_is_use & data_sram_data_ok);
assign in_allowin       = !valid | ready_go && out_allowin;//为空 或 不为空且发送且接收
assign out_valid   = valid && ready_go;

always @(posedge clk) begin
    if(reset) begin
        valid <= 1'b0;
    end 
    else if (in_allowin) begin
        valid <= in_valid;
    end
    if (empty) begin
        out_data <= 0;
    end
    else if(in_valid && out_allowin) begin
        out_data <= in_data;
    end
end

endmodule