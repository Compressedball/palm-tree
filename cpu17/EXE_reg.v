module EXE_reg(
    input clk,
    input reset,
    input valid,

    input [213:0]   in_data,
    output [164:0]   out_data,

    input  wire        ID_EXE_valid,

    output wire [41:0] EXE_pre_Data,
    output wire        is_div_block,
    output wire        is_divu_block
);

wire [15:0] alu_op;
wire        is_upper;
wire [31:0] alu_src1;
wire [31:0] alu_src2;
wire [31:0] rkd_value;
wire [31:0] alu_result;

wire        gr_we;
wire [4:0]  dest;
wire        res_from_mem;
wire        is_byte;
wire        is_halfword;
wire        mem_is_sign;
wire        mem_we;
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
wire        is_ine;
wire        is_adef;
wire        is_ertn;
wire        is_interrupt;

wire        is_break;

wire        div_valid;
wire        divu_valid;

assign {alu_op,//16
        is_upper,
        alu_src1,//32
        alu_src2,//32
        rkd_value,//32

        res_from_mem,//1
        is_byte,
        is_halfword,
        mem_is_sign,
        mem_we,//1
        gr_we,//1
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

alu u_alu(
    .clk        (clk),
    .reset      (reset),
    .alu_op     (alu_op    ),
    .is_upper   (is_upper  ),
    .alu_src1   (alu_src1  ),
    .alu_src2   (alu_src2  ),
    .alu_result (alu_result),
    .div_valid  (div_valid ),
    .divu_valid (divu_valid),
    .ID_EXE_valid(ID_EXE_valid)
    );

assign out_data = {alu_result,//32

                   res_from_mem,//1
                   is_byte,//1
                   is_halfword,
                   mem_is_sign,
                   rkd_value,//32
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

                   is_sys,//例外的处理
                   is_break,
                   is_ine,
                   is_adef,

                   is_interrupt,

                   is_ertn,
                   
                   pc//32
};

assign EXE_pre_Data = {alu_result,//32
                       res_from_mem,//1
                       res_from_csr,
                       res_from_counter,
                       gr_we,//1
                       dest,//5
                       alu_op[14]//1
};

assign is_div_block = ID_EXE_valid && alu_op[14] && !div_valid;
assign is_divu_block = ID_EXE_valid && alu_op[15] && !divu_valid;
endmodule