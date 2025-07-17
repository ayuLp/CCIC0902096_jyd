module top_ctrl(
  //===== 系统信号 =====//
  input clk,                // 主时钟
  input rst_b,              // 低有效异步复位

  //===== 跳转控制输入 =====//
  input         jump_en_exe,        // 执行阶段跳转使能
  input  [31:0] jump_addr_exe,      // 执行阶段跳转地址
  input         ini_jump_intp,      // 中断跳转请求
  input  [31:0] ini_jump_addr_intp, // 中断跳转地址
  input         ini_clear_intp,     // 中断清除信号

  //===== 流水线控制信号 =====//
  input ext_hold_top,       // 外部全局暂停信号

  //===== 数据冒险检测接口 =====//
  input load_exe,           // EXE阶段加载指令标记
  input load_mem,           // MEM阶段加载指令标记
  input [31:0] reg_rdata1_reg, // 原始寄存器1数据
  input [31:0] reg_rdata2_reg, // 原始寄存器2数据
  input [31:0] reg_wdata_exe,  // EXE阶段写回数据
  input [31:0] reg_wdata_mem,  // MEM阶段写回数据
  input [31:0] reg_wdata_wb_pre,// WB预写数据（MEM级旁路）
  input [31:0] reg_wdata_wb,   // WB阶段写回数据
  input reg_ren1_dec,       // 译码阶段寄存器1读使能
  input reg_ren2_dec,       // 译码阶段寄存器2读使能
  input [4:0] reg_raddr1_dec, // 译码阶段读地址1
  input [4:0] reg_raddr2_dec, // 译码阶段读地址2
  input reg_wen_exe,        // EXE阶段写使能
  input reg_wen_mem,        // MEM阶段写使能
  input reg_wen_wb,         // WB阶段写使能
  input [4:0] reg_waddr_exe, // EXE阶段写地址
  input [4:0] reg_waddr_mem, // MEM阶段写地址
  input [4:0] reg_waddr_wb,  // WB阶段写地址

  //===== 数据前推输出 =====//
  output reg [31:0] reg_rdata1_ctl, // 前推后的寄存器1数据
  output reg [31:0] reg_rdata2_ctl, // 前推后的寄存器2数据

  //===== 总线仲裁接口 =====//
  input [31:0]  pc_if_pre,      // 预取指PC地址
  input         pc_req_if_pre,  // 取指请求
  output [31:0] inst_if_ctl,    // 最终指令数据
  input [31:0]  mem_addr_mem_pre, // MEM预访问地址
  input         mem_cs_en_mem_pre, // MEM内存使能
  input         mem_wen_mem_pre, // MEM写使能
  output [31:0] mem_rdata_mem_ctl, // MEM读数据
  input [31:0]  mem_addr_wb_pre,  // WB预访问地址
  input [31:0]  mem_wdata_wb_pre,  // WB写数据
  input         mem_cs_en_wb_pre,  // WB内存使能
  input         mem_wen_wb_pre,    // WB写使能
  output [31:0] mem_addr_ctl,     // 仲裁后内存地址
  output [31:0] mem_wdata_ctl,    // 仲裁后写数据
  output        mem_cs_en_ctl,     // 仲裁后内存使能
  output        mem_wen_ctl,      // 仲裁后写使能
  input  [31:0] mem_rdata_top,    // 原始内存读数据

  //===== 流水线控制输出 =====//
  output reg hold_if_ctl,    // IF级保持
  output reg hold_dec_ctl,   // DEC级保持
  output reg hold_exe_ctl,   // EXE级保持
  output reg hold_mem_ctl,   // MEM级保持
  output reg hold_wb_ctl,    // WB级保持
  output reg clear_if_ctl,   // IF级清除
  output reg clear_dec_ctl,  // DEC级清除
  output reg clear_exe_ctl,  // EXE级清除
  output reg clear_mem_ctl,  // MEM级清除
  output reg clear_wb_ctl,   // WB级清除
  output reg jump_if_ctl,    // IF级跳转
  output reg [31:0] jump_addr_if_ctl // 跳转地址
);
//======= 数据前推逻辑 =======//

//reg data out
wire reg_rdata1_from_exe_flg = (reg_raddr1_dec == reg_waddr_exe) & (reg_raddr1_dec != 5'd0) & reg_ren1_dec & reg_wen_exe & ~load_exe;  
wire reg_rdata2_from_exe_flg = (reg_raddr2_dec == reg_waddr_exe) & (reg_raddr2_dec != 5'd0) & reg_ren2_dec & reg_wen_exe & ~load_exe;  

wire reg_rdata1_from_mem_flg = (reg_raddr1_dec == reg_waddr_mem) & (reg_raddr1_dec != 5'd0) & reg_ren1_dec & reg_wen_mem & ~load_mem;  
wire reg_rdata2_from_mem_flg = (reg_raddr2_dec == reg_waddr_mem) & (reg_raddr2_dec != 5'd0) & reg_ren2_dec & reg_wen_mem & ~load_mem;  

wire reg_rdata1_from_wb_pre_flg = (reg_raddr1_dec == reg_waddr_mem) & (reg_raddr1_dec != 5'd0) & reg_ren1_dec & reg_wen_mem & load_mem;  
wire reg_rdata2_from_wb_pre_flg = (reg_raddr2_dec == reg_waddr_mem) & (reg_raddr2_dec != 5'd0) & reg_ren2_dec & reg_wen_mem & load_mem;

wire reg_rdata1_from_wb_flg = (reg_raddr1_dec == reg_waddr_wb) & (reg_raddr1_dec != 5'd0) & reg_ren1_dec & reg_wen_wb;  
wire reg_rdata2_from_wb_flg = (reg_raddr2_dec == reg_waddr_wb) & (reg_raddr2_dec != 5'd0) & reg_ren2_dec & reg_wen_wb;  

// 寄存器1数据选择器
always @(*) begin
  if(reg_rdata1_from_exe_flg)
    reg_rdata1_ctl = reg_wdata_exe;
  else if(reg_rdata1_from_mem_flg)
    reg_rdata1_ctl = reg_wdata_mem;
  else if(reg_rdata1_from_wb_pre_flg)
    reg_rdata1_ctl = reg_wdata_wb_pre;
  else if(reg_rdata1_from_wb_flg)
    reg_rdata1_ctl = reg_wdata_wb;
  else
    reg_rdata1_ctl = reg_rdata1_reg;
end
// 寄存器2数据选择器
always @(*) begin
  if(reg_rdata2_from_exe_flg)
    reg_rdata2_ctl = reg_wdata_exe;
  else if(reg_rdata2_from_mem_flg)
    reg_rdata2_ctl = reg_wdata_mem;
  else if(reg_rdata2_from_wb_pre_flg)
    reg_rdata2_ctl = reg_wdata_wb_pre;
  else if(reg_rdata2_from_wb_flg)
    reg_rdata2_ctl = reg_wdata_wb;
  else
    reg_rdata2_ctl = reg_rdata2_reg;
end

//bus arbiter总线仲裁逻辑
wire if_access_bus_en  = ~mem_cs_en_wb_pre & ~mem_cs_en_mem_pre & pc_req_if_pre;
wire mem_access_bus_en = ~mem_cs_en_wb_pre & mem_cs_en_mem_pre;
wire wb_access_bus_en  = mem_cs_en_wb_pre;

reg if_access_bus_en_d,mem_access_bus_en_d;
always @(posedge clk or negedge rst_b) begin
  if(~rst_b) begin
    if_access_bus_en_d  <= 1'b0;
    mem_access_bus_en_d <= 1'b0;
  end
  else begin
    if_access_bus_en_d  <= if_access_bus_en;
    mem_access_bus_en_d <= mem_access_bus_en;
  end
end
// 总线信号分配
assign mem_addr_ctl = mem_cs_en_wb_pre ? mem_addr_wb_pre : (mem_cs_en_mem_pre ? mem_addr_mem_pre : pc_if_pre);
assign mem_wdata_ctl = mem_cs_en_wb_pre ? mem_wdata_wb_pre : 32'd0;
assign mem_cs_en_ctl = mem_cs_en_wb_pre | mem_cs_en_mem_pre | pc_req_if_pre;
assign mem_wen_ctl = mem_cs_en_wb_pre ? mem_wen_wb_pre : (mem_cs_en_mem_pre ? mem_wen_mem_pre : 1'b0);

assign inst_if_ctl = mem_rdata_top & {32{if_access_bus_en_d}};
assign mem_rdata_mem_ctl = mem_rdata_top & {32{mem_access_bus_en_d}};

wire bus_mem_en_wb_en = mem_cs_en_wb_pre & mem_cs_en_mem_pre;
wire bus_if_en_mem_or_wb_en = pc_req_if_pre & (mem_cs_en_wb_pre | mem_cs_en_mem_pre);

//======= 流水线控制逻辑 =======//
//hold & clear out
//data hazard hold
wire exe_rs_mem_ld_rd_en = ((reg_raddr1_dec == reg_waddr_exe) & (reg_raddr1_dec != 5'd0) & reg_ren1_dec & reg_wen_exe & load_exe) |
                           ((reg_raddr2_dec == reg_waddr_exe) & (reg_raddr2_dec != 5'd0) & reg_ren2_dec & reg_wen_exe & load_exe) ;// 加载使用冒险检测


always @(*) begin
hold_if_ctl      = 1'd0;
hold_dec_ctl     = 1'd0;
hold_exe_ctl     = 1'd0;
hold_mem_ctl     = 1'd0;
hold_wb_ctl      = 1'd0;

clear_if_ctl     = 1'd0;
clear_dec_ctl    = 1'd0;
clear_exe_ctl    = 1'd0;
clear_mem_ctl    = 1'd0;
clear_wb_ctl     = 1'd0;

jump_if_ctl      = 1'd0;
jump_addr_if_ctl = 32'd0;  

if(ext_hold_top) begin
  hold_if_ctl        = 1'd1;
  hold_dec_ctl       = 1'd1;
  hold_exe_ctl       = 1'd1;
  hold_mem_ctl       = 1'd1;
  hold_wb_ctl       = 1'd1;
end
if(ini_jump_intp) begin
  jump_if_ctl      = 1'd1;
  jump_addr_if_ctl = ini_jump_addr_intp;
  clear_if_ctl    = 1'd1;
  clear_dec_ctl    = 1'd1;
  clear_exe_ctl    = 1'd1;
end
else if(ini_clear_intp & bus_mem_en_wb_en) begin
  clear_if_ctl      = 1'd1;
  clear_dec_ctl    = 1'd1;
  hold_exe_ctl    = 1'd1;
  clear_mem_ctl    = 1'd1;
end
else if(ini_clear_intp) begin
  clear_if_ctl      = 1'd1;
  clear_dec_ctl    = 1'd1;
  clear_exe_ctl    = 1'd1;
end
else if(bus_mem_en_wb_en) begin
  hold_if_ctl    = 1'd1;
  hold_dec_ctl    = 1'd1;
  hold_exe_ctl    = 1'd1;
  clear_mem_ctl    = 1'd1;
end
else if(jump_en_exe) begin
  jump_if_ctl      = 1'd1;
  jump_addr_if_ctl = jump_addr_exe;
  clear_if_ctl    = 1'd1;
  clear_dec_ctl    = 1'd1;
  clear_exe_ctl    = 1'd1;
end
else if(exe_rs_mem_ld_rd_en) begin
  hold_if_ctl      = 1'd1;
  hold_dec_ctl     = 1'd1;
  clear_exe_ctl    = 1'd1;
end
else if(bus_if_en_mem_or_wb_en) begin
  hold_if_ctl      = 1'd1;
  clear_dec_ctl     = 1'd1;
end

end//always


endmodule
