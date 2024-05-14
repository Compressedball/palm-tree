module MEM_reg(
    input clk,
    input reset,
    input valid,

    input            empty,
    input   wire     EXE_MEM_valid,
    input   [164:0]   in_data,

    output wire         data_sram_req,
    output wire         data_sram_wr,
    output wire  [1:0]  data_sram_size,
    output wire  [3:0]  data_sram_wstrb,
    output wire [31:0]  data_sram_addr,
    output wire [31:0]  data_sram_wdata,
    input  wire         data_sram_addr_ok,
    input  wire         data_sram_data_ok,
    output wire         data_req_is_use,

    output   [165:0]  out_data,
    output   [40:0]   MEM_pre_Data,

    input             MEM_WB_allowin,
    input             wb_data_req_is_use,
    input             MEM_WB_valid,

    output            is_axi_block
);

wire [31:0] alu_result;
wire        res_from_mem;
wire        is_byte;
wire        is_halfword;
wire [31:0] rkd_value;
wire        mem_is_sign;

wire [31:0] pc;
wire    res_from_counter;
wire    counter_is_id;
wire    counter_is_upper;

wire        res_from_csr;
wire [13:0] csr_addr;
wire        csr_we;
wire [31:0] rj_value;
wire        is_chg;

wire        is_sys;
wire        is_break;
wire        is_ine;
wire        is_adef;
wire        is_ale;
wire        is_interrupt;
wire        is_ertn;

wire        gr_we;
wire  [4:0] dest;


assign {alu_result,//32

        res_from_mem,//1
        is_byte,//1
        is_halfword,
        mem_is_sign,
        rkd_value,
        gr_we,//1
        mem_we,
        dest,//5

        res_from_counter,
        counter_is_id,
        counter_is_upper,

        res_from_csr,
        csr_addr,
        csr_we,
        rj_value,
        is_chg,

        is_sys,
        is_break,
        is_ine,
        is_adef,
        is_interrupt,
        is_ertn,

        pc//32
} = in_data;


wire  [ 3:0] byte_we;
wire  [31:0] byte_data;
wire  [ 3:0] halfword_we;
wire  [31:0] halfword_data;

assign is_ale = (!is_byte & !is_halfword & res_from_mem & (alu_result[1:0] != 2'b00)) |
                    (is_halfword & res_from_mem & (alu_result[0] != 1'b0)) |
                    (!is_byte & !is_halfword & mem_we & (alu_result[1:0] != 2'b00)) |
                    (is_halfword & mem_we & (alu_result[0] != 1'b0));

assign byte_we = ({4{!alu_result[0] & !alu_result[1]}} & {3'h0,{mem_we && valid && EXE_MEM_valid}}) |
                     ({4{alu_result[0] & !alu_result[1]}} & {2'h0,{mem_we && valid && EXE_MEM_valid},1'b0}) |
                     ({4{!alu_result[0] & alu_result[1]}} & {1'h0,{mem_we && valid && EXE_MEM_valid},2'h0}) |
                     ({4{alu_result[0] & alu_result[1]}} & {{mem_we && valid && EXE_MEM_valid},3'h0});

assign byte_data = ({32{!alu_result[0] & !alu_result[1]}} & rkd_value) |
                     ({32{alu_result[0] & !alu_result[1]}} & {rkd_value[23:0],8'h00}) |
                     ({32{!alu_result[0] & alu_result[1]}} & {rkd_value[15:0],16'h0000}) |
                     ({32{alu_result[0] & alu_result[1]}} & {rkd_value[7:0],24'h000000});

assign halfword_we = ({4{!alu_result[1]}} & {2'h0,{2{mem_we && valid && EXE_MEM_valid}}}) |
                         ({4{alu_result[1]}} & {{2{mem_we && valid && EXE_MEM_valid}},2'h0});

assign halfword_data = ({32{!alu_result[1]}} & rkd_value) |
                         ({32{alu_result[1]}} & {rkd_value[15:0],16'h0000});


assign is_axi_block = (!data_sram_addr_ok & data_sram_req & EXE_MEM_valid) | (wb_data_req_is_use & !data_sram_data_ok & MEM_WB_valid);

assign data_req_is_use = {res_from_mem | mem_we} && valid && EXE_MEM_valid & !is_ale;

assign data_sram_req   = (data_req_is_use) & EXE_MEM_valid & MEM_WB_allowin;
assign data_sram_wr    = !res_from_mem;
assign data_sram_size  = ({2{is_byte}} & 2'b00) | ({2{is_halfword}} & 2'b01) | ({2{!is_byte & !is_halfword}} & 2'b10);
assign data_sram_wstrb = {4{mem_we && valid && EXE_MEM_valid}};
assign data_sram_addr  = alu_result;
assign data_sram_wdata = is_byte ? byte_data :
                                 (is_halfword ? halfword_data : rkd_value);


assign MEM_pre_Data = {alu_result,//32
                       gr_we,//1
                       dest,//5
                       res_from_mem,
                       res_from_csr,
                       res_from_counter
};

//70
assign out_data     = {res_from_mem,
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
                        data_req_is_use,

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

                       pc
};

endmodule
