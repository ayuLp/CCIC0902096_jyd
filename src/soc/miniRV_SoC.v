module miniRV_SoC(
input clk,
input rst_b

);

parameter mst_num = 3;
parameter slv_num = 2;

wire [31:0] rib_rdata_m0 = rib_rdata_mst[31:0];
wire [31:0] rib_wdata_m0 = 32'd0;
wire [31:0] rib_addr_m0  = 32'd0;
wire        rb_req_m0    = 1'd0;
wire        rib_wr_en_m0 = 1'b0;

wire [31:0] rib_rdata_m1 = rib_rdata_mst[32+31:32+0];
wire [31:0] rib_wdata_m1 = 32'd0;
wire [31:0] rib_addr_m1  = 32'd0;
wire        rb_req_m1    = 1'd0;
wire        rib_wr_en_m1 = 1'd0;

wire [31:0] rib_rdata_m2 = rib_rdata_mst[32*2+31:32*2+0];
wire [31:0] rib_wdata_m2;
wire [31:0] rib_addr_m2;
wire        rb_req_m2;
wire        rib_wr_en_m2;

wire [31:0] rib_rdata_s0;
wire [31:0] rib_wdata_s0 = rib_wdata_slv[31:0];
wire [31:0] rib_addr_s0  = rib_addr_slv[31:0] ;
wire        rb_req_s0    = rib_req_slv[0]     ;
wire        rib_wr_en_s0 = rib_wr_en_slv[0]   ;

wire [31:0] rib_rdata_s1;
wire [31:0] rib_wdata_s1 = rib_wdata_slv[32+31:32+0];
wire [31:0] rib_addr_s1  = rib_addr_slv[32+31:32+0] ;
wire        rb_req_s1    = rib_req_slv[1]     ;
wire        rib_wr_en_s1 = rib_wr_en_slv[1]   ;

wire        rib_core_hold;
wire [7:0]  ext_ini_flag_top = 8'd0;

wire [mst_num*32-1:0] rib_addr_mst  = {rib_addr_m2,rib_addr_m1,rib_addr_m0};
wire [mst_num*32-1:0] rib_wdata_mst = {rib_wdata_m2,rib_wdata_m1,rib_wdata_m0};
wire [mst_num*32-1:0] rib_rdata_mst;
wire [mst_num-1   :0] rib_req_mst   = {rb_req_m2,rb_req_m1,rb_req_m0};
wire [mst_num-1   :0] rib_wr_en_mst = {rib_wr_en_m2,rib_wr_en_m1,rib_wr_en_m0};

wire [slv_num*32-1:0] rib_addr_slv;
wire [slv_num*32-1:0] rib_wdata_slv;
wire [slv_num*32-1:0] rib_rdata_slv = {rib_rdata_s1,rib_rdata_s0};
wire [slv_num-1   :0] rib_req_slv;
wire [slv_num-1   :0] rib_wr_en_slv;


myCPU u0_myCPU(
  .clk(clk),
  .rst_b(rst_b),

  .mem_rdata_top  (rib_rdata_m2),
  .mem_addr_ctl   (rib_addr_m2),
  .mem_wdata_ctl  (rib_wdata_m2),
  .mem_wen_ctl    (rib_wr_en_m2),
  .mem_cs_en_ctl  (rb_req_m2),

  //ext hold
  .ext_hold_top (rib_core_hold),
  //ext irq
  .ext_ini_flag_top(ext_ini_flag_top)
);

riscv_rib #(
.mst_num(mst_num),
.slv_num(slv_num)
) u_riscv_rib (
.clk(clk),
.rst_b(rst_b),
.rib_addr_mst (rib_addr_mst ),
.rib_wdata_mst(rib_wdata_mst),
.rib_rdata_mst(rib_rdata_mst),
.rib_req_mst  (rib_req_mst  ),
.rib_wr_en_mst(rib_wr_en_mst),
.rib_addr_slv (rib_addr_slv ),
.rib_wdata_slv(rib_wdata_slv),
.rib_rdata_slv(rib_rdata_slv),
.rib_req_slv  (rib_req_slv  ),
.rib_wr_en_slv(rib_wr_en_slv),
.rib_core_hold(rib_core_hold)
);


riscv_mem u0_riscv_ram(
.clk        (clk  ),
.rst_b      (rst_b),
.addr_riscv (rib_addr_s1),
.wdata_riscv(rib_wdata_s1),
.wr_en_riscv(rib_wr_en_s1),
.cs_en_riscv(rb_req_s1),
.rdata_mem  (rib_rdata_s1)
);

riscv_mem u0_riscv_rom(
.clk        (clk  ),
.rst_b      (rst_b),
.addr_riscv (rib_addr_s0),
.wdata_riscv(rib_wdata_s0),
.wr_en_riscv(rib_wr_en_s0),
.cs_en_riscv(rb_req_s0),
.rdata_mem  (rib_rdata_s0)
);


endmodule
