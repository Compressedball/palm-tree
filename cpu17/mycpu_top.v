module mycpu_top(
    input  wire        aclk,
    input  wire        aresetn,
    // // inst sram interface
    // output wire         inst_sram_req,
    // output wire         inst_sram_wr,
    // output wire  [1:0]  inst_sram_size,
    // output wire  [3:0]  inst_sram_wstrb,
    // output wire [31:0]  inst_sram_addr,
    // output wire [31:0]  inst_sram_wdata,
    // input  wire         inst_sram_addr_ok,
    // input  wire         inst_sram_data_ok,
    // input  wire [31:0]  inst_sram_rdata,
    // // data sram interface
    // output wire         data_sram_req,
    // output wire         data_sram_wr,
    // output wire  [1:0]  data_sram_size,
    // output wire  [3:0]  data_sram_wstrb,
    // output wire [31:0]  data_sram_addr,
    // output wire [31:0]  data_sram_wdata,
    // input  wire         data_sram_addr_ok,
    // input  wire         data_sram_data_ok,
    // input  wire [31:0]  data_sram_rdata,
    //cpu axi
    output  wire [3 :0] arid   ,
    output  wire [31:0] araddr ,
    output  wire [7 :0] arlen  ,
    output  wire [2 :0] arsize ,
    output  wire [1 :0] arburst,
    output  wire [1 :0] arlock ,
    output  wire [3 :0] arcache,
    output  wire [2 :0] arprot ,
    output  wire        arvalid,
    input   wire        arready,
    
    input   wire [3 :0] rid    ,
    input   wire [31:0] rdata  ,
    input   wire [1 :0] rresp  ,
    input   wire        rlast  ,
    input   wire        rvalid ,
    output  wire        rready ,

    output  wire [3 :0] awid   ,
    output  wire [31:0] awaddr ,
    output  wire [7 :0] awlen  ,
    output  wire [2 :0] awsize ,
    output  wire [1 :0] awburst,
    output  wire [1 :0] awlock ,
    output  wire [3 :0] awcache,
    output  wire [2 :0] awprot ,
    output  wire        awvalid,
    input   wire        awready,

    output  wire [3 :0] wid    ,
    output  wire [31:0] wdata  ,
    output  wire [3 :0] wstrb  ,
    output  wire        wlast  ,
    output  wire        wvalid ,
    input   wire        wready ,

    input   wire [3 :0] bid    ,
    input   wire [1 :0] bresp  ,
    input   wire        bvalid ,
    output  wire        bready ,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

wire         inst_sram_req;
wire         inst_sram_wr;
wire  [1:0]  inst_sram_size;
wire  [3:0]  inst_sram_wstrb;
wire [31:0]  inst_sram_addr;
wire [31:0]  inst_sram_wdata;
wire         inst_sram_addr_ok;
wire         inst_sram_data_ok;
wire [31:0]  inst_sram_rdata;
// data sram interface
wire         data_sram_req;
wire         data_sram_wr;
wire  [1:0]  data_sram_size;
wire  [3:0]  data_sram_wstrb;
wire [31:0]  data_sram_addr;
wire [31:0]  data_sram_wdata;
wire         data_sram_addr_ok;
wire         data_sram_data_ok;
wire [31:0]  data_sram_rdata;

reg         reset;
always @(posedge aclk) reset <= ~aresetn;

reg         valid;
always @(posedge aclk) begin
    if (reset) begin
        valid <= 1'b0;
    end
    else begin
        valid <= 1'b1;
    end
end

wire [31:0] pc;
wire        pc_r;
wire [31:0] nextpc;

wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;
wire        rf_we;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;

wire [13:0] csr_addr;
wire [31:0] csr_rdata;
wire        csr_we;
wire [31:0] csr_wdata;

wire Pre_IF_ready_go;
wire Pre_IF_allowin;
wire Pre_IF_in_valid;

wire IF_ID_allowin;
wire IF_ID_in_valid;
wire IF_ID_valid;
wire [64:0] IF_outdata;

wire ID_EXE_allowin;
wire ID_EXE_in_valid;
wire ID_EXE_valid;
wire [65:0]  ID_indata;
wire [213:0] ID_outdata;

wire EXE_MEM_allowin;
wire EXE_MEM_in_valid;
wire EXE_MEM_valid;
wire [213:0] EXE_indata;
wire [164:0] EXE_outdata;

wire MEM_WB_allowin;
wire MEM_WB_in_valid;
wire MEM_WB_valid;
wire [164:0] MEM_indata;
wire [165:0] MEM_outdata;

wire        last_WB_allowin;
wire        last_WB_in_valid;

wire [165:0] WB_indata;

wire [32:0] ID_to_IF_Data;
wire [41:0] EXE_pre_Data;
wire [40:0] MEM_pre_Data;
wire [37:0] WB_pre_Data;

wire        is_block;
wire        is_div_block;
wire        is_divu_block;

wire        is_sys;
wire        is_break;
wire        is_ine;
wire        is_adef;
wire        is_ale;
wire        is_interrupt;
wire        is_ertn;

wire        Interrupt;

wire        Exception;
wire [31:0] exc_in_pc;
wire [31:0] ale_in_pc;
wire [31:0] exc_pc;
wire        empty;

wire        quit_Exception;
wire [31:0] quit_pc;

wire [31:0] counter_id;
wire [63:0] Counter;

wire is_use;
wire mem_is_use;
wire wb_data_req_is_use;
wire data_req_is_use;
wire [31:0] MEM_pc;
wire        is_axi_block;

assign Pre_IF_in_valid = inst_sram_addr_ok & inst_sram_req | (br_block & !is_block & ! is_div_block & !is_divu_block);
assign last_WB_allowin = 1'b1;

PC u_pc(
    .clk(aclk),
    .reset(reset),
    .pc_r(pc_r),
    .nextpc(nextpc),

    .pc(pc)
);

regfile u_regfile(
    .clk    (aclk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (rf_we    ),
    .waddr  (rf_waddr ),
    .wdata  (rf_wdata )
);

csr u_csr(
    .clk(aclk),
    .reset(reset),
    .addr(csr_addr),
    .rdata(csr_rdata),
    .we(csr_we),
    .wdata(csr_wdata),

    .counter_id(counter_id),

    .MEM_WB_valid(MEM_WB_valid),
    .is_sys(is_sys),
    .is_break(is_break),
    .is_ine(is_ine),
    .is_adef(is_adef),
    .is_ale(is_ale),
    .is_interrupt(is_interrupt),
    .is_ertn(is_ertn),
    .exc_in_pc(exc_in_pc),
    .ale_in_pc(ale_in_pc),

    .Exception(Exception),
    .exc_pc(exc_pc),

    .quit_Exception(quit_Exception),
    .quit_pc(quit_pc),

    .Interrupt(Interrupt),//上标记

    .empty(empty)
);

Stable_Counter u_stable_counter(
    .clk(aclk),
    .reset(reset),

    .counter_id(counter_id),
    .Counter(Counter)
);

Pre_IF u_pre_if(
    .clk(aclk),
    .reset(reset),

    .is_div_block(is_div_block),
    .is_divu_block(is_divu_block),
    .is_block(is_block),
    .br_block(br_block),
    .is_axi_block(is_axi_block),

    .in_allowin(Pre_IF_allowin),
    .in_valid(Pre_IF_in_valid),//进来的valid,为1

    .out_allowin(IF_ID_allowin),//对方允不允许接收
    .out_valid(IF_ID_in_valid),//传走的valid

    .is_use(is_use),
    .inst_sram_data_ok(inst_sram_data_ok),

    .ready_go(Pre_IF_ready_go)
);

IF_reg u_IF_reg(
    .clk(aclk),
    .reset(reset),
    .valid(valid),

    .Pre_IF_ready_go(Pre_IF_ready_go),
    .Exception(Exception),
    .exc_pc(exc_pc),

    .quit_Exception(quit_Exception),
    .quit_pc(quit_pc),

    .ID_Data(ID_to_IF_Data),
    .pc(pc),
    .inst_sram_rdata(inst_sram_rdata),

    .is_div_block(is_div_block),
    .is_divu_block(is_divu_block),
    .is_block(is_block),
    .br_block(br_block),
    .is_axi_block(is_axi_block),

    .pc_r(pc_r),
    .nextpc(nextpc),

    .IF_ID_allowin(IF_ID_allowin),
    .inst_sram_req(inst_sram_req),
    .inst_sram_wr(inst_sram_wr),
    .inst_sram_size(inst_sram_size),
    .inst_sram_wstrb(inst_sram_wstrb),
    .inst_sram_addr(inst_sram_addr),
    .inst_sram_wdata(inst_sram_wdata),
    .inst_sram_addr_ok(inst_sram_addr_ok),
    .inst_sram_data_ok(inst_sram_data_ok),

    .is_use(is_use),

    .Pre_IF_allowin(Pre_IF_allowin),

    .out_data(IF_outdata)
);

IF_ID_reg u_IF_ID_reg(
    .clk(aclk),
    .reset(reset),

    .empty(empty),

    .is_div_block(is_div_block),
    .is_divu_block(is_divu_block),
    .is_block(is_block),
    .is_axi_block(is_axi_block),

    .in_allowin(IF_ID_allowin),
    .in_valid(IF_ID_in_valid),
    .in_data(IF_outdata),

    .out_allowin(ID_EXE_allowin),//对方允不允许接收
    .out_valid(ID_EXE_in_valid),//传走的valid
    .out_data(ID_indata),

    .valid(IF_ID_valid),

    .br_block(br_block),
    .inst_sram_addr_ok(inst_sram_addr_ok),
    .inst_sram_req(inst_sram_req),
    .ready_go(IF_ID_ready_go)
);

ID_reg u_ID_reg(
    .clk(aclk),
    .reset(reset),
    .valid(valid),

    .in_data(ID_indata),
    .IF_ID_valid(IF_ID_valid),

    .ID_EXE_valid(ID_EXE_valid),
    .EXE_pre_Data(EXE_pre_Data),
    .EXE_MEM_valid(EXE_MEM_valid),
    .MEM_pre_Data(MEM_pre_Data),
    .MEM_WB_valid(MEM_WB_valid),
    .WB_pre_Data(WB_pre_Data),

    .rf_raddr1(rf_raddr1),
    .rf_raddr2(rf_raddr2),
    .rf_rdata1(rf_rdata1),
    .rf_rdata2(rf_rdata2),

    .to_IF_Data(ID_to_IF_Data),
    .out_data(ID_outdata),

    .is_block(is_block),

    .is_interrupt(Interrupt)
);

ID_EXE_reg u_ID_EXE_reg(
    .clk(aclk),
    .reset(reset),

    .empty(empty),

    .is_div_block(is_div_block),
    .is_divu_block(is_divu_block),
    .is_axi_block(is_axi_block),

    .in_allowin(ID_EXE_allowin),
    .in_valid(ID_EXE_in_valid),
    .in_data(ID_outdata),

    .out_allowin(EXE_MEM_allowin),//对方允不允许接收
    .out_valid(EXE_MEM_in_valid),//传走的valid
    .out_data(EXE_indata),

    .valid(ID_EXE_valid)
);

EXE_reg u_EXE_reg(
    .clk(aclk),
    .reset(reset),
    .valid(valid),

    .in_data(EXE_indata),
    .out_data(EXE_outdata),

    .ID_EXE_valid(ID_EXE_valid),

    .EXE_pre_Data(EXE_pre_Data),
    .is_div_block(is_div_block),
    .is_divu_block(is_divu_block)
);

EXE_MEM_reg u_EXE_MEM_reg(
    .clk(aclk),
    .reset(reset),

    .empty(empty),

    .is_axi_block(is_axi_block),

    .in_allowin(EXE_MEM_allowin),
    .in_valid(EXE_MEM_in_valid),//进来的valid,为1
    .in_data(EXE_outdata),

    .out_allowin(MEM_WB_allowin),//对方允不允许接收
    .out_valid(MEM_WB_in_valid),//传走的valid
    .out_data(MEM_indata),

    .valid(EXE_MEM_valid)
);

MEM_reg u_MEM_reg(
    .clk(aclk),
    .reset(reset),
    .valid(valid),

    .empty(empty),
    .EXE_MEM_valid(EXE_MEM_valid),
    .in_data(MEM_indata),

    .data_sram_req(data_sram_req),
    .data_sram_wr(data_sram_wr),
    .data_sram_size(data_sram_size),
    .data_sram_wstrb(data_sram_wstrb),
    .data_sram_addr(data_sram_addr),
    .data_sram_wdata(data_sram_wdata),
    .data_sram_addr_ok(data_sram_addr_ok),
    .data_sram_data_ok(data_sram_data_ok),
    .data_req_is_use(data_req_is_use),


    .out_data(MEM_outdata),
    .MEM_pre_Data(MEM_pre_Data),

    .MEM_WB_allowin(MEM_WB_allowin),
    .wb_data_req_is_use(wb_data_req_is_use),
    .MEM_WB_valid(MEM_WB_valid),

    .is_axi_block(is_axi_block)
);

MEM_WB_reg u_MEM_WB_reg(
    .clk(aclk),
    .reset(reset),

    .empty(empty),

    .in_allowin(MEM_WB_allowin),
    .in_valid(MEM_WB_in_valid),//进来的valid,为1
    .in_data(MEM_outdata),

    .out_allowin(last_WB_allowin),//对方允不允许接收
    .out_valid(last_WB_in_valid),//传走的valid
    .out_data(WB_indata),

    .valid(MEM_WB_valid),
    .data_sram_data_ok(data_sram_data_ok),
    .wb_data_req_is_use(wb_data_req_is_use)
);

WB_reg u_WB_reg(
    .clk(aclk),
    .reset(reset),
    .valid(valid),

    .empty(empty),
    .in_data(WB_indata),
    .mem_result(data_sram_rdata),
    .data_sram_data_ok(data_sram_data_ok),
    .wb_data_req_is_use(wb_data_req_is_use),

    .MEM_WB_valid(MEM_WB_valid),
    .rf_we(rf_we),
    .rf_waddr(rf_waddr),
    .rf_wdata(rf_wdata),

    .debug_wb_pc(debug_wb_pc),
    .debug_wb_rf_we(debug_wb_rf_we),
    .debug_wb_rf_wnum(debug_wb_rf_wnum),
    .debug_wb_rf_wdata(debug_wb_rf_wdata),

    .csr_rdata(csr_rdata),
    .csr_addr(csr_addr),
    .csr_we(csr_we),
    .csr_wdata(csr_wdata),

    .counter_id(counter_id),
    .Counter(Counter),

    .is_sys(is_sys),
    .is_break(is_break),
    .is_ine(is_ine),
    .is_adef(is_adef),
    .is_ale(is_ale),
    .is_interrupt(is_interrupt),
    .is_ertn(is_ertn),
    .exc_in_pc(exc_in_pc),
    .ale_in_pc(ale_in_pc),

    .pre_data(WB_pre_Data)
);

// reg    data_inst;
// wire   data_or_inst;

// always @(posedge aclk) begin
//     if(reset) begin
//         data_inst = 1'b0;
//     end if (data_sram_addr_ok) begin
//         data_inst = 1'b1;
//     end if (inst_sram_addr_ok) begin
//         data_inst = 1'b0;
//     end
// end

// assign data_or_inst = data_sram_req ? 1'b1 : 1'b0;

// assign arid     = 4'b0000;
// assign araddr   = (data_or_inst) ? data_sram_addr : inst_sram_addr;
// assign arlen    = 8'h00;
// assign arsize   = (data_or_inst) ? data_sram_size : inst_sram_size;
// assign arburst  = 2'b01;
// assign arlock   = 2'b00;
// assign arcache  = 4'h0;
// assign arprot   = 3'b000;
// assign arvalid  = (data_or_inst) ? (data_sram_req & !data_sram_wr) : (inst_sram_req & !inst_sram_wr);

// assign rready   = 1'b1;

// assign awid     = 4'h1;
// assign awaddr   = data_sram_addr;
// assign awlen    = 8'h00;
// assign awsize   = data_sram_size;
// assign awburst  = 2'b01;
// assign awlock   = 2'b00;
// assign awcache  = 4'h0;
// assign awprot   = 3'b000;
// assign awvalid  = data_sram_req & data_sram_wr;

// assign wid      = 4'h1;
// assign wdata    = data_sram_wdata;
// assign wstrb    = data_sram_wstrb;
// assign wlast    = 1'b1;
// assign wvalid   = data_sram_req & data_sram_wr;

// assign bready   = 1'b1;

// assign inst_sram_addr_ok    = (!data_or_inst) & arready;
// assign inst_sram_rdata      = rdata;
// assign inst_sram_data_ok    = (!data_inst)  & rvalid;

// reg     axi_awready_use;
// reg     axi_wready_use;

// assign data_sram_addr_ok    = ((data_or_inst) & arready) | ((awready | axi_awready_use) & (wready | axi_wready_use));
// assign data_sram_rdata      = rdata;
// assign data_sram_data_ok    = ((data_inst)  & rvalid)  | bvalid;


// always @(posedge aclk) begin
//     if(reset) begin
//         axi_awready_use = 1'b0;
//         axi_wready_use = 1'b0;
//     end if(awvalid & awready) begin
//         axi_awready_use = 1'b1;
//     end if (wvalid & wready) begin
//         axi_wready_use = 1'b1;
//     end if(data_sram_addr_ok) begin
//         axi_awready_use = 1'b0;
//         axi_wready_use = 1'b0;
//     end
// end



//addr
reg do_req;
reg do_req_or; //req is inst or data;1:data,0:inst
reg        do_wr_r;
reg [1 :0] do_size_r;
reg [31:0] do_addr_r;
reg [31:0] do_wdata_r;
wire data_back;

assign inst_sram_addr_ok = !do_req&&!data_sram_req;
assign data_sram_addr_ok = !do_req;
always @(posedge aclk)
begin
    do_req     <= !aresetn                       ? 1'b0 : 
                  (inst_sram_req||data_sram_req)&&!do_req ? 1'b1 :
                  data_back                     ? 1'b0 : do_req;
    do_req_or  <= !aresetn ? 1'b0 : 
                  !do_req ? data_sram_req : do_req_or;

    do_wr_r    <= data_sram_req&&data_sram_addr_ok ? data_sram_wr :
                  inst_sram_req&&inst_sram_addr_ok ? inst_sram_wr : do_wr_r;
    do_size_r  <= data_sram_req&&data_sram_addr_ok ? data_sram_size :
                  inst_sram_req&&inst_sram_addr_ok ? inst_sram_size : do_size_r;
    do_addr_r  <= data_sram_req&&data_sram_addr_ok ? data_sram_addr :
                  inst_sram_req&&inst_sram_addr_ok ? inst_sram_addr : do_addr_r;
    do_wdata_r <= data_sram_req&&data_sram_addr_ok ? data_sram_wdata :
                  inst_sram_req&&inst_sram_addr_ok ? inst_sram_wdata :do_wdata_r;
end

//inst sram-like
assign inst_sram_data_ok = do_req&&!do_req_or&&data_back;
assign data_sram_data_ok = do_req&& do_req_or&&data_back;
assign inst_sram_rdata   = rdata;
assign data_sram_rdata   = rdata;

//---axi
reg addr_rcv;
reg wdata_rcv;

assign data_back = addr_rcv && (rvalid&&rready||bvalid&&bready);
always @(posedge aclk)
begin
    addr_rcv  <= !aresetn          ? 1'b0 :
                 arvalid&&arready ? 1'b1 :
                 awvalid&&awready ? 1'b1 :
                 data_back        ? 1'b0 : addr_rcv;
    wdata_rcv <= !aresetn        ? 1'b0 :
                 wvalid&&wready ? 1'b1 :
                 data_back      ? 1'b0 : wdata_rcv;
end
//ar
assign arid    = 4'd0;
assign araddr  = do_addr_r;
assign arlen   = 8'd0;
assign arsize  = do_size_r;
assign arburst = 2'd0;
assign arlock  = 2'd0;
assign arcache = 4'd0;
assign arprot  = 3'd0;
assign arvalid = do_req&&!do_wr_r&&!addr_rcv;
//r
assign rready  = 1'b1;

//aw
assign awid    = 4'd0;
assign awaddr  = do_addr_r;
assign awlen   = 8'd0;
assign awsize  = do_size_r;
assign awburst = 2'd0;
assign awlock  = 2'd0;
assign awcache = 4'd0;
assign awprot  = 3'd0;
assign awvalid = do_req&&do_wr_r&&!addr_rcv;
//w
assign wid    = 4'd0;
assign wdata  = do_wdata_r;
assign wstrb  = do_size_r==2'd0 ? 4'b0001<< do_addr_r[1:0] :
                do_size_r==2'd1 ? 4'b0011<< do_addr_r[1:0] : 4'b1111;
assign wlast  = 1'd1;
assign wvalid = do_req&&do_wr_r&&!wdata_rcv;
//b
assign bready  = 1'b1;

endmodule
