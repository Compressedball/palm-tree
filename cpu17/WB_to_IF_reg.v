module WB_IF_reg( 
    input           clk,
    input           reset,

    output          in_allowin,
    input           in_valid,//进来的valid,为1

    input           out_allowin,//对方允不允许接收
    output          out_valid//传走的valid
);
reg         valid;
wire        ready_go;//流水线缓存格式(¬､¬)

assign ready_go      = 1'b1;
assign in_allowin       = !valid || ready_go && out_allowin;//为空 或 不为空且发送且接收
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
