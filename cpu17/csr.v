module csr(
    input           clk,
    input           reset,

    input  [13:0]   addr,
    output reg [31:0]   rdata,

    input           we,
    input  [31:0]   wdata,

    output [31:0]   counter_id,

    input           MEM_WB_valid,
    input           is_sys,
    input           is_break,
    input           is_ine,
    input           is_adef,
    input           is_ale,
    input           is_interrupt,
    input           is_ertn,
    input  [31:0]   exc_in_pc,
    input  [31:0]   ale_in_pc,

    output          Exception,
    output [31:0]   exc_pc,

    output          quit_Exception,
    output [31:0]   quit_pc,
    
    output  wire    Interrupt,

    output  wire    empty
    );

//0x0   当前模式信息
wire [31:0] CRMD;
reg   [1:0] CRMD_PLV;
reg         CRMD_IE;
reg         CRMD_DA;
reg         CRMD_PG;
reg   [1:0] CRMD_DATF;
reg   [1:0] CRMD_DATM;
wire [22:0] CRMD_0;

//0x1   例外前模式信息
wire [31:0] PRMD;
reg   [1:0] PRMD_PPLV;
reg         PRMD_PLE;
wire [28:0] PRMD_0;

//0x4   例外配置
wire [31:0] ECFG;
reg   [9:0] ECFG_LIE_1;
wire        ECFG_0_1;
reg   [1:0] ECFG_LIE_2;
wire [18:0] ECFG_0_2;

//0x5   例外状态
wire [31:0] ESTAT;
reg   [1:0] ESTAT_IS_1;
reg   [7:0] ESTAT_IS_2;
wire        ESTAT_0_0;
reg         ESTAT_IS_3;
reg         ESTAT_IS_4;
wire  [2:0] ESTAT_0_1;
reg   [5:0] ESTAT_Ecode;
reg   [8:0] ESTAT_EsubCode;
wire        ESTAT_0_2;

//0x6   例外返回地址
wire [31:0] ERA;
reg  [31:0] ERA_PC;

//0x7   出错虚地址
wire [31:0] BADV;
reg  [31:0] BADV_VAddr;

//0xc   例外入口地址
wire [31:0] EENTRY;
wire  [5:0] EENTRY_0;
reg  [25:0] EENTRY_VA;

//0x30-33   数据保存
wire [31:0] SEVE0;
wire [31:0] SEVE1;
wire [31:0] SEVE2;
wire [31:0] SEVE3;
reg  [31:0] SEVE0_Data;
reg  [31:0] SEVE1_Data;
reg  [31:0] SEVE2_Data;
reg  [31:0] SEVE3_Data;

//0x40  定时器编号
wire [31:0] TID;
reg  [31:0] TID_TID;

//0x41  定时器配置
wire [31:0] TCFG;
reg         TCFG_En;
reg         TCFG_Periodic;
reg  [29:0] TCFG_InitVal;

//0x42  定时器值
wire [31:0] TVAL;
reg  [31:0] TVAL_TimeVal;

//0x44 定时中断清除
wire [31:0] TICLR;
reg         TICLR_CLR;
wire [30:0] TICLR_0;

wire [11:0] int_vec;

assign int_vec   = {ESTAT_IS_4,ESTAT_IS_3,ESTAT_IS_2,ESTAT_IS_1} & {ECFG_LIE_2,ECFG_LIE_1};
assign Interrupt = (int_vec != 12'h000) & {CRMD_IE};


assign Exception = (is_sys | is_break | is_ine | is_adef | is_ale | is_interrupt) & MEM_WB_valid;
assign quit_Exception = is_ertn & MEM_WB_valid;
assign empty = Exception | quit_Exception;

always @(posedge clk) begin
    if(reset) begin
        {CRMD_DATM , CRMD_DATF , CRMD_PG , CRMD_DA , CRMD_IE , CRMD_PLV} <= 9'h008;
        {ECFG_LIE_2 , ECFG_LIE_1} <= 12'h000;
        {ESTAT_IS_4 , ESTAT_IS_3 , ESTAT_IS_2 , ESTAT_IS_1} <= 11'h000;
        TCFG_En = 1'b0;
    end
end

//0x0
assign CRMD = {
    CRMD_0,
    CRMD_DATM,
    CRMD_DATF,
    CRMD_PG,
    CRMD_DA,
    CRMD_IE,
    CRMD_PLV
};
assign CRMD_0 = 23'h000000;
always @(posedge clk) begin
    if (we && addr == 14'h0000) begin
        {CRMD_DATM , CRMD_DATF , CRMD_PG , CRMD_DA , CRMD_IE , CRMD_PLV} <= wdata[8:0];
    end
    if(Exception) begin
        CRMD_PLV <= 2'h0;
        CRMD_IE  <= 1'b0;
        CRMD_DA  <= 1'b1;
    end
    if(quit_Exception) begin
        CRMD_PLV <= PRMD_PPLV;
        CRMD_IE  <= PRMD_PLE;
        if(ESTAT_Ecode == 6'h3f) begin
            CRMD_DA <= 1'b0;
            CRMD_PG <= 1'b1;
        end
    end
end

//0x1
assign PRMD = {
    PRMD_0,
    PRMD_PLE,
    PRMD_PPLV
};
assign PRMD_0 = 29'h0000_0000;
always @(posedge clk) begin
    if (we && addr == 14'h0001) begin
        {PRMD_PLE , PRMD_PPLV} <= wdata[2:0];
    end
    if(Exception) begin
        PRMD_PPLV <= CRMD_PLV;
        PRMD_PLE  <= CRMD_IE;
    end
end

//0x4
assign ECFG = {
    ECFG_0_2,
    ECFG_LIE_2,
    ECFG_0_1,
    ECFG_LIE_1
};
assign ECFG_0_1 = 1'b0;
assign ECFG_0_2 = 19'h00000;
always @(posedge clk) begin
    if(we && addr == 14'h0004) begin
        {ECFG_LIE_2 , ECFG_LIE_1} <= {wdata[12:11] , wdata[9:0]};
    end
end

//0x5
assign ESTAT = {
    ESTAT_0_2,
    ESTAT_EsubCode,
    ESTAT_Ecode,
    ESTAT_0_1,
    ESTAT_IS_4,
    ESTAT_IS_3,
    ESTAT_0_0,
    ESTAT_IS_2,
    ESTAT_IS_1
};
assign ESTAT_0_0 = 1'b0;
assign ESTAT_0_1 = 3'h0;
assign ESTAT_0_2 = 1'b0;
always @(posedge clk) begin
    if(we && addr == 14'h0005) begin
        {ESTAT_IS_1} <= {wdata[1:0]};
    end
    if(Exception) begin
        ESTAT_Ecode <= {{6{is_sys}} & 6'h0b} | {{6{is_break}} & 6'h0c} | {{6{is_ine}} & 6'h0d} | {{6{is_adef}} & 6'h08} 
                        | {{6{is_ale}} & 6'h09} | {{6{is_interrupt}} & 6'h00};
        ESTAT_EsubCode <= {{9{is_sys | is_break | is_ine | is_adef | is_ale | is_interrupt}} & 9'h000};
    end
end

//0x6
assign ERA = {
    ERA_PC
};
always @(posedge clk) begin
    if (we && addr == 14'h0006) begin
        {ERA_PC} <= wdata;
    end
    if(Exception) begin
        ERA_PC <= exc_in_pc;
    end
end

//0x7
assign BADV = {
    BADV_VAddr
};
always @(posedge clk) begin
    if(we && addr == 14'h0007) begin
        {BADV_VAddr} <= wdata;
    end
    if (is_adef & Exception) begin
        BADV_VAddr = exc_in_pc;
    end
    if(is_ale & Exception) begin
        BADV_VAddr = ale_in_pc;
    end
end

//0xc
assign EENTRY = {
    EENTRY_VA,
    EENTRY_0
};
assign EENTRY_0 = 6'h00;
always @(posedge clk) begin
    if (we && addr == 14'h000c) begin
        EENTRY_VA <= wdata[31:6];
    end
end

//0x30-33
assign SEVE0 = SEVE0_Data;
assign SEVE1 = SEVE1_Data;
assign SEVE2 = SEVE2_Data;
assign SEVE3 = SEVE3_Data;
always @(posedge clk) begin
    if (we && addr == 14'h0030) begin
        SEVE0_Data <= wdata;
    end
    else if (we && addr == 14'h0031) begin
        SEVE1_Data <= wdata;
    end
    else if (we && addr == 14'h0032) begin
        SEVE2_Data <= wdata;
    end
    else if (we && addr == 14'h0033) begin
        SEVE3_Data <= wdata;
    end
end

//0x40
assign TID = {
    TID_TID
};
always @(posedge clk) begin
    if (we && addr == 14'h0040) begin
        TID_TID <= wdata;
    end
end

reg        can_sub;
//0x41
assign TCFG = {
    TCFG_InitVal,//有未定义数
    TCFG_Periodic,
    TCFG_En
};
always @(posedge clk) begin
    if(we && addr == 14'h0041) begin
        {TCFG_InitVal , TCFG_Periodic , TCFG_En} = wdata;
        if(TCFG_En) begin
            TVAL_TimeVal = {TCFG_InitVal , 2'b00};
            can_sub = 1'b1;
        end
    end
end


//0x42
assign TVAL = {
    TVAL_TimeVal
};
always @(posedge clk) begin
    if(TCFG_En & can_sub) begin
        if(TVAL_TimeVal == 0) begin
            ESTAT_IS_3 = 1'b1;
            if(TCFG_Periodic) TVAL_TimeVal = {TCFG_InitVal , 2'b00};
            else can_sub = 1'b0;
        end
        TVAL_TimeVal = TVAL_TimeVal - 1;
    end
end

//0x44
assign TICLR = {
    TICLR_0,
    TICLR_CLR
};
assign TICLR_0 = 31'h0000_0000;
always @(posedge clk) begin
    if (we && addr == 14'h0044) begin
        TICLR_CLR <= wdata[0];
        if(wdata[0] == 1) ESTAT_IS_3 = 1'b0;
    end
end



always @(addr , CRMD , PRMD , ECFG , ESTAT , ERA , BADV , EENTRY , 
               SEVE0 , SEVE1 , SEVE2 , SEVE3 , TID , TCFG , TVAL , TICLR) begin
    if(addr == 14'h0000) rdata = CRMD;
    else if(addr == 14'h0001) rdata = PRMD;
    else if(addr == 14'h0004) rdata = ECFG;
    else if(addr == 14'h0005) rdata = ESTAT;
    else if(addr == 14'h0006) rdata = ERA;
    else if(addr == 14'h0007) rdata = BADV;
    else if(addr == 14'h000c) rdata = EENTRY;
    else if(addr == 14'h0030) rdata = SEVE0;
    else if(addr == 14'h0031) rdata = SEVE1;
    else if(addr == 14'h0032) rdata = SEVE2;
    else if(addr == 14'h0033) rdata = SEVE3;
    else if(addr == 14'h0040) rdata = TID;
    else if(addr == 14'h0041) rdata = TCFG;
    else if(addr == 14'h0042) rdata = TVAL;
    else if(addr == 14'h0044) rdata = 32'h0000_0000;
    else rdata = 32'h0000_0000;
end

assign quit_pc = ERA;
assign exc_pc = EENTRY;
assign counter_id = TID_TID;
endmodule
