module WB_reg(
    input clk,
    input reset,
    input valid,

    input           empty,
    input   [165:0] in_data,
    input   [31:0]  mem_result,
    input           data_sram_data_ok,
    output          wb_data_req_is_use,

    input    wire    MEM_WB_valid,
    output   wire    rf_we,
    output   [4:0]   rf_waddr,
    output   [31:0]  rf_wdata,

    output   [31:0]  debug_wb_pc,
    output   [3:0]   debug_wb_rf_we,
    output   [4:0]   debug_wb_rf_wnum,
    output   [31:0]  debug_wb_rf_wdata,

    input    [31:0] csr_rdata,
    output   [13:0] csr_addr,
    output          csr_we,
    output   [31:0] csr_wdata,

    input    [31:0] counter_id,
    input    [63:0] Counter,

    output          is_sys,
    output          is_break,
    output          is_ine,
    output          is_adef,
    output          is_ale,
    output          is_interrupt,
    output          is_ertn,

    output   [31:0] exc_in_pc,
    output   [31:0] ale_in_pc, 
 
    output   [37:0]  pre_data
);
wire        res_from_mem;
wire        mem_is_sign;
wire [31:0] rkd_value; 
wire [31:0] alu_result;
wire        is_byte;
wire        is_halfword;
wire        gr_we;
wire  [4:0] dest;
wire [31:0] pc;
wire [31:0] final_result;

wire    res_from_counter;
wire    counter_is_id;
wire    counter_is_upper;

wire        res_from_csr;
wire [31:0] rj_value;
wire        is_chg;

assign {res_from_mem,
        mem_is_sign,
        rkd_value,
        alu_result,
        is_byte,
        is_halfword,
        gr_we,
        dest,

        res_from_counter,
        counter_is_id,
        counter_is_upper,
        wb_data_req_is_use,

        res_from_csr,
        csr_addr,
        csr_we,
        rj_value,
        is_chg,

        is_sys,
        is_break,
        is_ine,
        is_adef,
        is_ale,
        is_interrupt,
        is_ertn,

        pc          } = in_data;

wire [31:0] byte0_result;
wire [31:0] byte1_result;
wire [31:0] byte2_result;
wire [31:0] byte3_result;
wire [31:0] byte_result;

wire [31:0] halfword0_result;
wire [31:0] halfword1_result;
wire [31:0] halfword_result;

wire [31:0] finial_mem_result;

wire [31:0] counter_result;

assign byte0_result  =  {{24{mem_result[7] && mem_is_sign}} , mem_result[7:0]};
assign byte1_result  =  {{24{mem_result[15] && mem_is_sign}} , mem_result[15:8]};
assign byte2_result  =  {{24{mem_result[23] && mem_is_sign}} , mem_result[23:16]};
assign byte3_result  =  {{24{mem_result[31] && mem_is_sign}} , mem_result[31:24]};

assign halfword0_result = {{16{mem_result[15] && mem_is_sign}} , mem_result[15:0]};
assign halfword1_result = {{16{mem_result[31] && mem_is_sign}} , mem_result[31:16]};

assign byte_result = ({32{!alu_result[0] & !alu_result[1]}} & byte0_result) |
                     ({32{alu_result[0] & !alu_result[1]}} & byte1_result) |
                     ({32{!alu_result[0] & alu_result[1]}} & byte2_result) |
                     ({32{alu_result[0] & alu_result[1]}} & byte3_result);

assign halfword_result = ({32{!alu_result[1]}} & halfword0_result) |
                         ({32{alu_result[1]}} & halfword1_result);

assign finial_mem_result   = is_byte ? byte_result : 
                                        (is_halfword ? halfword_result : mem_result);

assign counter_result = counter_is_id ? counter_id : 
                                        (counter_is_upper ? Counter[63:32] : Counter[31:0]);
                                
assign final_result = res_from_mem ? finial_mem_result : 
                                    (res_from_csr ? csr_rdata : 
                                                    (res_from_counter ? counter_result : alu_result));


assign rf_we    = ((gr_we && valid && MEM_WB_valid && !empty & !wb_data_req_is_use) | 
                    (gr_we && valid && MEM_WB_valid && !empty & wb_data_req_is_use & data_sram_data_ok));
assign rf_waddr = dest;
assign rf_wdata = final_result;

assign debug_wb_pc       = pc;
assign debug_wb_rf_we   = {4{rf_we & !empty}};
assign debug_wb_rf_wnum  = dest;
assign debug_wb_rf_wdata = final_result;

assign csr_wdata = is_chg ? (rkd_value & rj_value | ~rj_value & csr_rdata) : rkd_value;

assign exc_in_pc = pc;
assign ale_in_pc = alu_result;

assign pre_data = {
    gr_we,
    dest,
    final_result
};

endmodule