module Stable_Counter(
    input   clk,
    input   reset,
    input [31:0] counter_id,
    output reg [63:0] Counter
    );
always @(posedge clk) begin
    if(reset) begin
        Counter = 0;
    end
    else begin
        Counter = Counter + 1;
    end
end
endmodule
