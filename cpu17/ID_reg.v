module ID_reg(
    input clk,
    input reset,
    input valid,

    input  [65:0]       in_data,
    input               IF_ID_valid,

    input               ID_EXE_valid,
    input  [41:0]       EXE_pre_Data,
    input               EXE_MEM_valid,
    input  [40:0]       MEM_pre_Data,
    input               MEM_WB_valid,
    input  [37:0]       WB_pre_Data,

    output [4:0]        rf_raddr1,
    output [4:0]        rf_raddr2,
    input  [31:0]       rf_rdata1,
    input  [31:0]       rf_rdata2,

    output [32:0]       to_IF_Data,
    output [213:0]      out_data,

    output  wire        is_block,

    input   wire        is_interrupt

    );
wire [31:0] pc;
wire [31:0] inst;

wire [31:0] inst_1;

wire [ 5:0] op_31_26;
wire [ 3:0] op_25_22;
wire [ 1:0] op_21_20;
wire [ 4:0] op_19_15;
wire [ 4:0] rd;
wire [ 4:0] rj;
wire [ 4:0] rk;
wire [11:0] i12;
wire [19:0] i20;
wire [15:0] i16;
wire [25:0] i26;

wire [63:0] op_31_26_d;
wire [15:0] op_25_22_d;
wire [ 3:0] op_21_20_d;
wire [31:0] op_19_15_d;
wire [31:0] rj_d;
wire [31:0] rk_d;
wire [31:0] rd_d;

wire        inst_add_w;
wire        inst_sub_w;
wire        inst_slt;
wire        inst_sltu;
wire        inst_nor;
wire        inst_and;
wire        inst_or;
wire        inst_xor;
wire        inst_slli_w;
wire        inst_srli_w;
wire        inst_srai_w;
wire        inst_addi_w;
wire        inst_ld_w;
wire        inst_st_w;
wire        inst_jirl;
wire        inst_b;
wire        inst_bl;
wire        inst_beq;
wire        inst_bne;
wire        inst_lu12i_w;

wire        inst_slti;
wire        inst_sltui;
wire        inst_andi;
wire        inst_ori;
wire        inst_xori;
wire        inst_sll;
wire        inst_srl;
wire        inst_sra;
wire        inst_pcaddu12i;
wire        inst_mul_w;
wire        inst_mulh_w;
wire        inst_mulh_wu;
wire        inst_div_w;
wire        inst_mod_w;
wire        inst_div_wu;
wire        inst_mod_wu;

wire        inst_blt;
wire        inst_bge;
wire        inst_bltu;
wire        inst_bgeu;
wire        inst_ld_b;
wire        inst_ld_h;
wire        inst_ld_bu;
wire        inst_ld_hu;
wire        inst_st_b;
wire        inst_st_h;

wire        inst_csrrd;
wire        inst_csrwr;
wire        inst_csrxchg;
wire        inst_syscall;
wire        inst_ertn;

wire        inst_break;

wire        inst_rdtimel_w_tid;
wire        inst_rdtimel_w_tvl;
wire        inst_rdtimeh_w;

wire        need_ui5;
wire        need_si12;
wire        need_si16;
wire        need_si20;
wire        need_si26;
wire        src2_is_4;

wire        need_ui12;

wire        br_taken;
wire [31:0] br_target;
wire [31:0] br_offs;
wire [31:0] jirl_offs;
wire [31:0] seq_pc;

wire        src1_is_pc;
wire        src2_is_imm;
wire [31:0] imm;
wire        src_reg_is_rd;

wire [31:0] rj_value;
wire [31:0] rkd_value;
wire        rj_eq_rd;
wire        rj_smaller_rd;
wire        rj_smalleru_rd;

wire [31:0] alu_src1;
wire [31:0] alu_src2;
wire        is_upper;
wire [15:0] alu_op;

wire        addr1_is_use;
wire        addr2_is_use;
wire        addr1_use;
wire        addr2_use;

wire        addr1_is_exe_pre;
wire        addr1_is_mem_pre;
wire        addr1_is_wb_pre;
wire        addr2_is_exe_pre;
wire        addr2_is_mem_pre;
wire        addr2_is_wb_pre;
wire        addr1_is_pre;
wire        addr2_is_pre;

wire [31:0] EXE_alu_result;
wire        EXE_gr_we;
wire  [4:0] EXE_dest;
wire        EXE_res_from_mem;
wire        EXE_res_from_csr;
wire        EXE_res_from_counter;
wire        EXE_div_op;

wire [31:0] MEM_final_result;
wire        MEM_gr_we;
wire  [4:0] MEM_dest;
wire        MEM_res_from_mem;
wire        MEM_res_from_csr;
wire        MEM_res_from_counter;

wire [31:0] WB_final_result;
wire        WB_gr_we;
wire  [4:0] WB_dest;

wire        dst_is_r1;
wire  [4:0] dest;
wire        res_from_mem;
wire        res_from_csr;
wire        gr_we;
wire        mem_we;
wire        is_chg;
wire [13:0] csr_addr;
wire        csr_we;

wire        res_from_counter;
wire        counter_is_id;
wire        counter_is_upper;

wire        is_sys;
wire        is_break;
wire        is_ine;
wire        is_adef;

wire        is_byte;
wire        is_halfword;
wire        mem_is_sign;

wire        ine_is_use;

assign {pc,
        inst_1,
        is_adef,
        ine_is_use      } = in_data;

assign inst = is_adef ? 32'h0000_0000 : inst_1;

assign {EXE_alu_result,//32
        EXE_res_from_mem,//1
        EXE_res_from_csr,
        EXE_res_from_counter,
        EXE_gr_we,//1
        EXE_dest,
        EXE_div_op      } = EXE_pre_Data;

assign {MEM_final_result,
        MEM_gr_we,
        MEM_dest,
        MEM_res_from_mem,
        MEM_res_from_csr,
        MEM_res_from_counter        } = MEM_pre_Data;

assign {WB_gr_we,
        WB_dest,
        WB_final_result } = WB_pre_Data;

assign seq_pc       = pc + 3'h4;

assign op_31_26  = inst[31:26];
assign op_25_22  = inst[25:22];
assign op_21_20  = inst[21:20];
assign op_19_15  = inst[19:15];

assign rd   = inst[ 4: 0];
assign rj   = inst[ 9: 5];
assign rk   = inst[14:10];

assign i12  = inst[21:10];
assign i20  = inst[24: 5];
assign i16  = inst[25:10];
assign i26  = {inst[ 9: 0], inst[25:10]};

decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));
decoder_5_32 u_dec4(.in(rj)       , .out(rj_d)       );
decoder_5_32 u_dec5(.in(rk)       , .out(rk_d)       );
decoder_5_32 u_dec6(.in(rd)       , .out(rd_d)       );

assign inst_add_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
assign inst_sub_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
assign inst_slt    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
assign inst_sltu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
assign inst_nor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
assign inst_and    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
assign inst_or     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
assign inst_xor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
assign inst_slli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
assign inst_srli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
assign inst_srai_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];
assign inst_ld_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
assign inst_st_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
assign inst_jirl   = op_31_26_d[6'h13];
assign inst_b      = op_31_26_d[6'h14];
assign inst_bl     = op_31_26_d[6'h15];
assign inst_beq    = op_31_26_d[6'h16];
assign inst_bne    = op_31_26_d[6'h17];
assign inst_lu12i_w= op_31_26_d[6'h05] & ~inst[25];

assign inst_slti   = op_31_26_d[6'h00] & op_25_22_d[4'h8];
assign inst_sltui  = op_31_26_d[6'h00] & op_25_22_d[4'h9];
assign inst_andi   = op_31_26_d[6'h00] & op_25_22_d[4'hd];
assign inst_ori    = op_31_26_d[6'h00] & op_25_22_d[4'he];
assign inst_xori   = op_31_26_d[6'h00] & op_25_22_d[4'hf];
assign inst_sll    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0e];
assign inst_srl    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0f];
assign inst_sra    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h10];
assign inst_pcaddu12i = op_31_26_d[6'h07] & ~inst[25];
assign inst_mul_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h18];
assign inst_mulh_w = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h19];
assign inst_mulh_wu = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h1a];
assign inst_div_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h00];
assign inst_mod_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h01];
assign inst_div_wu = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h02];
assign inst_mod_wu = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h03];

assign inst_blt    = op_31_26_d[6'h18];
assign inst_bge    = op_31_26_d[6'h19];
assign inst_bltu   = op_31_26_d[6'h1a];
assign inst_bgeu   = op_31_26_d[6'h1b];
assign inst_ld_b   = op_31_26_d[6'h0a] & op_25_22_d[4'h0];
assign inst_ld_h   = op_31_26_d[6'h0a] & op_25_22_d[4'h1];
assign inst_ld_bu  = op_31_26_d[6'h0a] & op_25_22_d[4'h8];
assign inst_ld_hu  = op_31_26_d[6'h0a] & op_25_22_d[4'h9];
assign inst_st_b   = op_31_26_d[6'h0a] & op_25_22_d[4'h4];
assign inst_st_h   = op_31_26_d[6'h0a] & op_25_22_d[4'h5];

assign inst_csrrd  = op_31_26_d[6'h01] & ~inst[25] & ~inst[24] & rj_d[5'h00];
assign inst_csrwr  = op_31_26_d[6'h01] & ~inst[25] & ~inst[24] & rj_d[5'h01];
assign inst_csrxchg = op_31_26_d[6'h01] & ~inst[25] & ~inst[24] & ~rj_d[5'h00] & ~rj_d[5'h01];
assign inst_syscall = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h16];
assign inst_ertn    = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & rk_d[5'h0e] & rj_d[5'h00] & rd_d[5'h00];

assign inst_break   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h14];

assign inst_rdtimel_w_tid = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h00] & rk_d[5'h18] & rd_d[5'h00];
assign inst_rdtimel_w_tvl = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h00] & rk_d[5'h18] & rj_d[5'h00];
assign inst_rdtimeh_w = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h00] & rk_d[5'h19] & rj_d[5'h00];

assign alu_op[ 0] = inst_add_w | inst_addi_w | inst_ld_w | inst_st_w
                    | inst_jirl | inst_bl | inst_pcaddu12i | inst_ld_b | inst_ld_h
                    | inst_ld_bu | inst_ld_hu | inst_st_b | inst_st_h;
assign alu_op[ 1] = inst_sub_w;
assign alu_op[ 2] = inst_slt | inst_slti;
assign alu_op[ 3] = inst_sltu | inst_sltui;
assign alu_op[ 4] = inst_and | inst_andi;
assign alu_op[ 5] = inst_nor;
assign alu_op[ 6] = inst_or | inst_ori;
assign alu_op[ 7] = inst_xor | inst_xori;
assign alu_op[ 8] = inst_slli_w | inst_sll;
assign alu_op[ 9] = inst_srli_w | inst_srl;
assign alu_op[10] = inst_srai_w | inst_sra;
assign alu_op[11] = inst_lu12i_w;
assign alu_op[12] = inst_mul_w | inst_mulh_w;
assign alu_op[13] = inst_mulh_wu;
assign alu_op[14] = inst_div_w | inst_mod_w;
assign alu_op[15] = inst_div_wu | inst_mod_wu;

assign is_upper   = inst_mulh_w | inst_mulh_wu | inst_div_w | inst_div_wu;

assign need_ui5   =  inst_slli_w | inst_srli_w | inst_srai_w;
assign need_si12  =  inst_addi_w | inst_ld_w | inst_st_w | inst_slti | inst_sltui | inst_ld_b | inst_ld_h | inst_ld_bu
                     | inst_ld_hu | inst_st_b | inst_st_h; 
assign need_si16  =  inst_jirl | inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu |inst_bgeu;
assign need_si20  =  inst_lu12i_w | inst_pcaddu12i;
assign need_si26  =  inst_b | inst_bl;
assign src2_is_4  =  inst_jirl | inst_bl;

assign need_ui12  =  inst_andi | inst_ori | inst_xori;

assign imm = src2_is_4 ? 32'h4                      :
             need_si20 ? {i20[19:0], 12'b0}         :
             need_ui5  ? rk                         :
             need_ui12 ? {{20{1'b0}}, i12[11:0]}    :
            /*need_si12*/{{20{i12[11]}}, i12[11:0]} ;

assign br_offs = need_si26 ? {{ 4{i26[25]}}, i26[25:0], 2'b0} :
                             {{14{i16[15]}}, i16[15:0], 2'b0} ;

assign jirl_offs = {{14{i16[15]}}, i16[15:0], 2'b0};

assign src_reg_is_rd = inst_beq | inst_bne | inst_st_w | inst_blt | inst_bge | inst_bltu | inst_bgeu | inst_st_b | inst_st_h
                        | inst_csrwr | inst_csrxchg;

assign src1_is_pc    = inst_jirl | inst_bl | inst_pcaddu12i;

assign src2_is_imm   = inst_slli_w |
                       inst_srli_w |
                       inst_srai_w |
                       inst_addi_w |
                       inst_ld_w   |
                       inst_st_w   |
                       inst_lu12i_w|
                       inst_jirl   |
                       inst_bl     |
                       inst_slti   |
                       inst_sltui  |
                       inst_andi   |
                       inst_ori    |
                       inst_xori   |
                       inst_pcaddu12i |
                       inst_ld_b   |
                       inst_ld_h   |
                       inst_ld_bu  |
                       inst_ld_hu  |
                       inst_st_b   |
                       inst_st_h;

assign res_from_mem  = inst_ld_w | inst_ld_b | inst_ld_h | inst_ld_bu | inst_ld_hu;
assign res_from_csr  = inst_csrrd | inst_csrwr | inst_csrxchg;

assign res_from_counter = inst_rdtimel_w_tvl | inst_rdtimeh_w | inst_rdtimel_w_tid;
assign counter_is_id = inst_rdtimel_w_tid;
assign counter_is_upper = inst_rdtimeh_w;

assign dst_is_r1     = inst_bl;
assign det_is_rj     = inst_rdtimel_w_tid;

assign gr_we         = ~inst_st_w & ~inst_beq & ~inst_bne & ~inst_b & ~inst_blt & ~inst_bge & ~inst_bltu & ~inst_bgeu
                        & ~inst_st_b & ~inst_st_h & ~is_ine;
assign mem_we        = inst_st_w | inst_st_b | inst_st_h;
assign dest          = dst_is_r1 ? 5'd1 
                                 : (det_is_rj ? rj : rd);

assign is_chg        = inst_csrxchg;
assign csr_addr      = inst[23:10];
assign csr_we        = inst_csrwr | inst_csrxchg;

assign is_sys        = inst_syscall;
assign is_ertn       = inst_ertn;
assign is_ine        = !inst_add_w & !inst_sub_w & !inst_slt & !inst_sltu & !inst_nor & !inst_and & !inst_or & !inst_xor 
                        & !inst_slli_w & !inst_srli_w & !inst_srai_w & !inst_addi_w & !inst_ld_w & !inst_st_w & !inst_jirl 
                        & !inst_b & !inst_bl & !inst_beq & !inst_bne & !inst_lu12i_w & !inst_slti & !inst_sltui & !inst_andi 
                        & !inst_ori & !inst_xori & !inst_sll & !inst_srl & !inst_sra & !inst_pcaddu12i & !inst_mul_w & !inst_mulh_w
                        & !inst_mulh_wu & !inst_div_w & !inst_mod_w & !inst_div_wu & !inst_mod_wu & !inst_blt & !inst_bge
                        & !inst_bltu & !inst_bgeu & !inst_ld_b & !inst_ld_h & !inst_ld_bu & !inst_ld_hu & !inst_st_b
                        & !inst_st_h & !inst_csrrd & !inst_csrwr & !inst_csrxchg & !inst_syscall & !inst_ertn & !inst_break
                        & ine_is_use & !is_adef & !inst_rdtimeh_w & !inst_rdtimel_w_tid & !inst_rdtimel_w_tvl 
                        & IF_ID_valid;

assign is_break      = inst_break;


assign rf_raddr1 = rj;
assign rf_raddr2 = src_reg_is_rd ? rd :rk;

//阻塞还没加
assign addr1_is_use = !inst_b && !inst_bl && !inst_lu12i_w && !inst_pcaddu12i && !inst_csrrd && !inst_csrwr
                        && !inst_syscall && !inst_ertn && !inst_break && !inst_rdtimel_w_tid && !inst_rdtimel_w_tvl
                        && !inst_rdtimeh_w;
assign addr2_is_use = !inst_slli_w && !inst_srli_w && !inst_srai_w && !inst_addi_w && !inst_ld_w && !inst_st_w
                       && !inst_jirl && !inst_b && !inst_bl && !inst_lu12i_w && !inst_slti && !inst_sltui
                       && !inst_andi && !inst_ori && !inst_xori && !inst_pcaddu12i && !inst_ld_b && ! inst_ld_h
                       && !inst_ld_bu && !inst_ld_hu && !inst_st_b && !inst_st_h && !inst_csrrd && !inst_syscall
                       && !inst_ertn && !inst_break && !inst_rdtimel_w_tid && !inst_rdtimel_w_tvl && !inst_rdtimeh_w;

assign addr1_use = ((EXE_gr_we && (rf_raddr1 == EXE_dest) && ID_EXE_valid) 
                    || (MEM_gr_we && (rf_raddr1 == MEM_dest) && EXE_MEM_valid)
                    || (WB_gr_we && (rf_raddr1 == WB_dest) && MEM_WB_valid)) && (rf_raddr1 != 5'h00);

assign addr2_use = ((EXE_gr_we && (rf_raddr2 == EXE_dest) && ID_EXE_valid) 
                    || (MEM_gr_we && (rf_raddr2 == MEM_dest) && EXE_MEM_valid)
                    || (WB_gr_we && (rf_raddr2 == WB_dest) && MEM_WB_valid)) && (rf_raddr2 != 5'h00);


assign addr1_is_exe_pre = (!EXE_res_from_counter && !EXE_res_from_csr && !EXE_res_from_mem && EXE_gr_we && (rf_raddr1 == EXE_dest) && ID_EXE_valid) && (rf_raddr1 != 5'h00);

assign addr1_is_mem_pre = (!((rf_raddr1 == EXE_dest) && EXE_gr_we & (EXE_res_from_counter | EXE_res_from_csr | EXE_res_from_mem)) &
                                !MEM_res_from_counter && !MEM_res_from_csr && !MEM_res_from_mem && MEM_gr_we && (rf_raddr1 == MEM_dest) && EXE_MEM_valid) && (rf_raddr1 != 5'h00);

assign addr1_is_wb_pre  = (!((rf_raddr1 == EXE_dest) && EXE_gr_we & (EXE_res_from_counter | EXE_res_from_csr | EXE_res_from_mem)) &
                                !((rf_raddr1 == MEM_dest) && MEM_gr_we & (MEM_res_from_counter | MEM_res_from_csr | MEM_res_from_mem)) &
                                        WB_gr_we && (rf_raddr1 == WB_dest) && MEM_WB_valid) && (rf_raddr1 != 5'h00);


assign addr2_is_exe_pre = (!EXE_res_from_counter && !EXE_res_from_csr && !EXE_res_from_mem && EXE_gr_we && (rf_raddr2 == EXE_dest) && ID_EXE_valid) && (rf_raddr2 != 5'h00);
assign addr2_is_mem_pre = (!((rf_raddr2 == EXE_dest) && EXE_gr_we & (EXE_res_from_counter | EXE_res_from_csr | EXE_res_from_mem)) &
                                !MEM_res_from_counter && !MEM_res_from_csr && !MEM_res_from_mem && MEM_gr_we && (rf_raddr2 == MEM_dest) && EXE_MEM_valid) && (rf_raddr2 != 5'h00);
assign addr2_is_wb_pre  = (!((rf_raddr2 == EXE_dest) && EXE_gr_we & (EXE_res_from_counter | EXE_res_from_csr | EXE_res_from_mem)) &
                                !((rf_raddr2 == MEM_dest) && MEM_gr_we & (MEM_res_from_counter | MEM_res_from_csr | MEM_res_from_mem)) &
                                         WB_gr_we && (rf_raddr2 == WB_dest) && MEM_WB_valid) && (rf_raddr2 != 5'h00);

assign addr1_is_pre = addr1_is_exe_pre | addr1_is_mem_pre | addr1_is_wb_pre;
assign addr2_is_pre = addr2_is_exe_pre | addr2_is_mem_pre | addr2_is_wb_pre;

assign is_block = ((addr1_is_use && addr1_use && !addr1_is_pre) || (addr2_is_use && addr2_use && !addr2_is_pre)) & IF_ID_valid;

assign rj_value  = addr1_is_exe_pre ? EXE_alu_result :
                                      (addr1_is_mem_pre ? MEM_final_result : 
                                                         (addr1_is_wb_pre ? WB_final_result : rf_rdata1));
assign rkd_value = addr2_is_exe_pre ? EXE_alu_result :
                                      (addr2_is_mem_pre ? MEM_final_result : 
                                                         (addr2_is_wb_pre ? WB_final_result : rf_rdata2));


assign rj_eq_rd = (rj_value == rkd_value);
assign rj_smaller_rd = ($signed(rj_value) < $signed(rkd_value));
assign rj_smalleru_rd = (rj_value < rkd_value);

assign br_taken = (   inst_beq  &&  rj_eq_rd
                   || inst_bne  && !rj_eq_rd
                   || inst_jirl
                   || inst_bl
                   || inst_b
                   || inst_blt  && rj_smaller_rd
                   || inst_bge  && !rj_smaller_rd
                   || inst_bltu && rj_smalleru_rd
                   || inst_bgeu && !rj_smalleru_rd
                   ) && IF_ID_valid;
assign br_target = (inst_beq || inst_bne || inst_bl || inst_b || inst_blt || inst_bge || inst_bltu || inst_bgeu) ? (pc + br_offs) :
                                                   /*inst_jirl*/ (rj_value + jirl_offs);

assign alu_src1 = src1_is_pc  ? pc[31:0] : rj_value;
assign alu_src2 = src2_is_imm ? imm : rkd_value;

assign is_byte  = inst_ld_b | inst_ld_bu | inst_st_b;
assign is_halfword = inst_ld_h | inst_ld_hu | inst_st_h;
assign mem_is_sign = inst_ld_b | inst_ld_h;

assign out_data = {alu_op,//16
                   is_upper,//1
                   alu_src1,//32
                   alu_src2,//32

                   rkd_value,//32
                   res_from_mem,//1
                   is_byte,//1
                   is_halfword,
                   mem_is_sign,
                   mem_we,//1
                   gr_we,//1
                   dest,//5

                   res_from_counter,
                   counter_is_id,
                   counter_is_upper,

                   res_from_csr,//1
                   csr_addr,//14
                   csr_we,//1
                   rj_value,//32
                   is_chg,

                   is_sys,
                   is_break,
                   is_ine,
                   is_adef,

                   is_interrupt,

                   is_ertn,

                   pc//32
                   };

//地址前递 65bits
assign to_IF_Data = {
        br_taken,
        br_target
};
endmodule
