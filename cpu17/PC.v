module PC(
    input clk,
    input reset,

    input pc_r,
    input [31:0]  nextpc,

    output reg [31:0] pc
    );
always @(posedge clk) begin
    if (reset) begin
        pc <= 32'h1bfffffc;     //trick: to make nextpc be 0x1c000000 during reset 
    end
    else if(pc_r) begin
        pc <= nextpc;
    end
end
endmodule
