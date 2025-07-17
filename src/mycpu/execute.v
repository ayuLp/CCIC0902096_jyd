module execute(
input clk,
input rst_b,

//clear
input clear_ctl,

//hold
input hold_ctl,

//from decoder
input [31:0] pc_dec,
input [31:0] imm_dec,
input        imm_en_dec,  

// ALU操作控制信号
input sll_dec,  
input srl_dec,  
input sra_dec,  
input add_dec,  
input sub_dec,  
input lui_dec,  
input auipc_dec,  
input xor_dec,  
input and_dec,  
input or_dec,  
input slt_dec,  
input sltu_dec,  

// 访存控制信号
input lb_dec,  
input lh_dec,  
input lbu_dec,  
input lhu_dec,  
input lw_dec,  
input sb_dec,  
input sh_dec,  
input sw_dec,  
// 跳转控制信号
input jal_dec,  
input jalr_dec,  
input beq_dec,  
input bne_dec,  
input blt_dec,  
input bge_dec,  
input bltu_dec,  
input bgeu_dec,  
// 系统指令
input fence_dec,// 内存屏障
input fence_i_dec,

input csrrw_dec,// CSR操作
input csrrs_dec,
input csrrc_dec,

// 寄存器文件接口
input [4:0] reg_waddr_dec,

input [31:0] reg_rdata1_ctl,
input [31:0] reg_rdata2_ctl,

//to mem
//===== 访存阶段输出 =====//
output reg lb_exe,
output reg lh_exe,
output reg lbu_exe,
output reg lhu_exe,
output reg lw_exe,
output reg sb_exe,
output reg sh_exe,
output reg sw_exe,

//to jump ctl跳转控制输出
output reg jump_en_exe,
output reg [31:0] jump_addr_exe,

//to write mem寄存器写回接口
output reg reg_wen_exe,
output reg [4:0] reg_waddr_exe,
output reg [31:0] reg_wdata_exe,

//访存地址输出
output reg [31:0] mem_addr_exe,
//寄存器数据传递
output reg [31:0] reg_rdata2_exe,

//for exception异常检测
output reg load_addr_mis_exe_pre,
output reg store_addr_mis_exe_pre,
output reg [31:0] mem_addr_exe_pre,

//io with csr regfile
//CSR寄存器接口
output reg csr_wen_exe,// CSR写使能
output reg [11:0] csr_waddr_exe,// CSR地址
output reg [31:0] csr_wdata_exe,// CSR写数据

output reg csr_ren_exe,// CSR读使能
output reg [11:0] csr_raddr_exe,// CSR读地址
input      [31:0] csr_rdata_csr// CSR读数据

);

//预计算结果寄存器
reg jump_en_exe_pre;
reg [31:0] jump_addr_exe_pre;

reg reg_wen_exe_pre;
reg [4:0] reg_waddr_exe_pre;
reg [31:0] reg_wdata_exe_pre;

//组合逻辑
always @(*) begin
jump_en_exe_pre = 1'b0;
jump_addr_exe_pre = 32'd0;

reg_wen_exe_pre = 1'b0;
reg_waddr_exe_pre = 5'd0;
reg_wdata_exe_pre = 32'd0;

mem_addr_exe_pre = 32'd0;

csr_wen_exe = 1'b0; 
csr_waddr_exe = 12'd0;
csr_wdata_exe = 32'd0;

csr_ren_exe = 1'b0; 
csr_raddr_exe = 12'd0;

if(lui_dec) begin
  reg_wen_exe_pre = 1'b1;
  reg_waddr_exe_pre = reg_waddr_dec;
  reg_wdata_exe_pre = {imm_dec[31:12],12'd0};
end

if(auipc_dec) begin
  reg_wen_exe_pre = 1'b1;
  reg_waddr_exe_pre = reg_waddr_dec;
  reg_wdata_exe_pre = {imm_dec[31:12],12'd0} + pc_dec;// PC + 高位立即数
end
// JAL指令处理（直接跳转）
if(jal_dec) begin
  reg_wen_exe_pre = 1'b1;
  reg_waddr_exe_pre = reg_waddr_dec;
  reg_wdata_exe_pre = pc_dec+32'd4;// 返回地址 = PC+4
  jump_en_exe_pre = 1'b1;
  // 立即数拼接：[20|10:1|11|19:12] → [31:12] + offset计算
  jump_addr_exe_pre = pc_dec + {{11{imm_dec[20]}},imm_dec[20:1],1'b0};
end
// JALR指令处理（寄存器间接跳转）
if(jalr_dec) begin
  reg_wen_exe_pre = 1'b1;
  reg_waddr_exe_pre = reg_waddr_dec;
  reg_wdata_exe_pre = pc_dec+32'd4;
  jump_en_exe_pre = 1'b1;
  // 基地址 + 符号扩展立即数（最低位置零）
  jump_addr_exe_pre = reg_rdata1_ctl + {{20{imm_dec[11]}},imm_dec[11:0]};
end
// 条件分支指令处理（统一立即数处理）
if(beq_dec) begin
  if(reg_rdata1_ctl == reg_rdata2_ctl) begin
    jump_en_exe_pre = 1'b1;
    // 立即数处理：[12|10:5|4:1|11] → 符号扩展
    jump_addr_exe_pre = pc_dec + {{19{imm_dec[12]}},imm_dec[12:1],1'b0};
  end
end

if(bne_dec) begin
  if(reg_rdata1_ctl != reg_rdata2_ctl) begin
    jump_en_exe_pre = 1'b1;
    jump_addr_exe_pre = pc_dec + {{19{imm_dec[12]}},imm_dec[12:1],1'b0};
  end
end

if(blt_dec) begin
  if($signed(reg_rdata1_ctl) < $signed(reg_rdata2_ctl)) begin
    jump_en_exe_pre = 1'b1;
    jump_addr_exe_pre = pc_dec + {{19{imm_dec[12]}},imm_dec[12:1],1'b0};
  end
end

if(bltu_dec) begin
  if(reg_rdata1_ctl < reg_rdata2_ctl) begin
    jump_en_exe_pre = 1'b1;
    jump_addr_exe_pre = pc_dec + {{19{imm_dec[12]}},imm_dec[12:1],1'b0};
  end
end

if(bge_dec) begin
  if($signed(reg_rdata1_ctl) >= $signed(reg_rdata2_ctl)) begin
    jump_en_exe_pre = 1'b1;
    jump_addr_exe_pre = pc_dec + {{19{imm_dec[12]}},imm_dec[12:1],1'b0};
  end
end

if(bgeu_dec) begin
  if(reg_rdata1_ctl >= reg_rdata2_ctl) begin
    jump_en_exe_pre = 1'b1;
    jump_addr_exe_pre = pc_dec + {{19{imm_dec[12]}},imm_dec[12:1],1'b0};
  end
end
// 加载指令处理（地址计算）
if(lb_dec|lh_dec|lw_dec|lbu_dec|lhu_dec) begin
  mem_addr_exe_pre = reg_rdata1_ctl + {{20{imm_dec[11]}},imm_dec[11:0]};// 基址+偏移
  reg_wen_exe_pre = 1'b1;// 标记需要写回寄存器
  reg_waddr_exe_pre = reg_waddr_dec;
end
 // 存储指令处理（地址计算）
if(sb_dec|sh_dec|sw_dec) begin
  mem_addr_exe_pre = reg_rdata1_ctl + {{20{imm_dec[11]}},imm_dec[11:0]};
end
// 算术逻辑单元（ALU）操作
if(add_dec) begin
  reg_wen_exe_pre = 1'b1;
  reg_waddr_exe_pre = reg_waddr_dec;
  if(imm_en_dec)
    reg_wdata_exe_pre = {{20{imm_dec[11]}},imm_dec[11:0]} + reg_rdata1_ctl;
  else
    reg_wdata_exe_pre = reg_rdata2_ctl + reg_rdata1_ctl;
end

if(sub_dec) begin
  reg_wen_exe_pre = 1'b1;
  reg_waddr_exe_pre = reg_waddr_dec;
  reg_wdata_exe_pre = reg_rdata1_ctl - reg_rdata2_ctl;
end

if(slt_dec) begin
  reg_wen_exe_pre = 1'b1;
  reg_waddr_exe_pre = reg_waddr_dec;
  if(imm_en_dec & ($signed(reg_rdata1_ctl) < $signed({{20{imm_dec[11]}},imm_dec[11:0]})))
    reg_wdata_exe_pre = 32'd1;
  else if(~imm_en_dec & ($signed(reg_rdata1_ctl) < $signed(reg_rdata2_ctl)))
    reg_wdata_exe_pre = 32'd1;
end

if(sltu_dec) begin
  reg_wen_exe_pre = 1'b1;
  reg_waddr_exe_pre = reg_waddr_dec;
  if(imm_en_dec & (reg_rdata1_ctl < {{20{imm_dec[11]}},imm_dec[11:0]}))
    reg_wdata_exe_pre = 32'd1;
  else if(~imm_en_dec & (reg_rdata1_ctl < reg_rdata2_ctl))
    reg_wdata_exe_pre = 32'd1;
end

if(xor_dec) begin
  reg_wen_exe_pre = 1'b1;
  reg_waddr_exe_pre = reg_waddr_dec;
  if(imm_en_dec)
    reg_wdata_exe_pre = {{20{imm_dec[11]}},imm_dec[11:0]} ^ reg_rdata1_ctl; 
  else
    reg_wdata_exe_pre = reg_rdata2_ctl ^ reg_rdata1_ctl;
end

if(or_dec) begin
  reg_wen_exe_pre = 1'b1;
  reg_waddr_exe_pre = reg_waddr_dec;
  if(imm_en_dec)
    reg_wdata_exe_pre = {{20{imm_dec[11]}},imm_dec[11:0]} | reg_rdata1_ctl; 
  else
    reg_wdata_exe_pre = reg_rdata2_ctl | reg_rdata1_ctl;
end

if(and_dec) begin
  reg_wen_exe_pre = 1'b1;
  reg_waddr_exe_pre = reg_waddr_dec;
  if(imm_en_dec)
    reg_wdata_exe_pre = {{20{imm_dec[11]}},imm_dec[11:0]} & reg_rdata1_ctl; 
  else
    reg_wdata_exe_pre = reg_rdata2_ctl & reg_rdata1_ctl;
end

if(sll_dec) begin
  reg_wen_exe_pre = 1'b1;
  reg_waddr_exe_pre = reg_waddr_dec;
  if(imm_en_dec)
    reg_wdata_exe_pre = reg_rdata1_ctl << imm_dec[4:0]; 
  else
    reg_wdata_exe_pre = reg_rdata1_ctl << reg_rdata2_ctl[4:0];
end

if(srl_dec) begin
  reg_wen_exe_pre = 1'b1;
  reg_waddr_exe_pre = reg_waddr_dec;
  if(imm_en_dec)
    reg_wdata_exe_pre = reg_rdata1_ctl >> imm_dec[4:0]; 
  else
    reg_wdata_exe_pre = reg_rdata1_ctl >> reg_rdata2_ctl[4:0];
end

if(sra_dec) begin
  reg_wen_exe_pre = 1'b1;
  reg_waddr_exe_pre = reg_waddr_dec;
  if(imm_en_dec)
    reg_wdata_exe_pre = $signed(reg_rdata1_ctl) >>> imm_dec[4:0]; 
  else
    reg_wdata_exe_pre = $signed(reg_rdata1_ctl) >>> reg_rdata2_ctl[4:0];
end

if(fence_dec | fence_i_dec) begin
  jump_en_exe_pre = 1'b1;
  jump_addr_exe_pre = pc_dec + 32'd4;
end
// CSR指令处理
if(csrrw_dec) begin// CSR原子写操作
  if(~imm_en_dec) begin
    csr_wen_exe = 1'b1;
    csr_waddr_exe = imm_dec[31:20];
    csr_wdata_exe = reg_rdata1_ctl;
    csr_ren_exe = 1'b1;
    csr_raddr_exe = imm_dec[31:20];
    reg_wen_exe_pre = 1'b1;
    reg_waddr_exe_pre = reg_waddr_dec;
    reg_wdata_exe_pre = csr_rdata_csr;
  end
  else begin
    csr_wen_exe = 1'b1;
    csr_waddr_exe = imm_dec[31:20];
    csr_wdata_exe = {27'd0,imm_dec[19:15]};
    csr_ren_exe = 1'b1;
    csr_raddr_exe = imm_dec[31:20];
    reg_wen_exe_pre = 1'b1;
    reg_waddr_exe_pre = reg_waddr_dec;
    reg_wdata_exe_pre = csr_rdata_csr;
  end
end

if(csrrs_dec) begin
  if(~imm_en_dec) begin
    csr_wen_exe = 1'b1;
    csr_waddr_exe = imm_dec[31:20];
    csr_wdata_exe = reg_rdata1_ctl | csr_rdata_csr;
    csr_ren_exe = 1'b1;
    csr_raddr_exe = imm_dec[31:20];
    reg_wen_exe_pre = 1'b1;
    reg_waddr_exe_pre = reg_waddr_dec;
    reg_wdata_exe_pre = csr_rdata_csr;
  end
  else begin
    csr_wen_exe = 1'b1;
    csr_waddr_exe = imm_dec[31:20];
    csr_wdata_exe = {27'd0,imm_dec[19:15]} | csr_rdata_csr;
    csr_ren_exe = 1'b1;
    csr_raddr_exe = imm_dec[31:20];
    reg_wen_exe_pre = 1'b1;
    reg_waddr_exe_pre = reg_waddr_dec;
    reg_wdata_exe_pre = csr_rdata_csr;
  end
end

if(csrrc_dec) begin
  if(~imm_en_dec) begin
    csr_wen_exe = 1'b1;
    csr_waddr_exe = imm_dec[31:20];
    csr_wdata_exe = ~reg_rdata1_ctl & csr_rdata_csr;
    csr_ren_exe = 1'b1;
    csr_raddr_exe = imm_dec[31:20];
    reg_wen_exe_pre = 1'b1;
    reg_waddr_exe_pre = reg_waddr_dec;
    reg_wdata_exe_pre = csr_rdata_csr;
  end
  else begin
    csr_wen_exe = 1'b1;
    csr_waddr_exe = imm_dec[31:20];
    csr_wdata_exe = ~{27'd0,imm_dec[19:15]} & csr_rdata_csr;
    csr_ren_exe = 1'b1;
    csr_raddr_exe = imm_dec[31:20];
    reg_wen_exe_pre = 1'b1;
    reg_waddr_exe_pre = reg_waddr_dec;
    reg_wdata_exe_pre = csr_rdata_csr;
  end
end

end//always

//时序逻辑
always @(posedge clk or negedge rst_b) begin
  if(~rst_b) begin
    jump_en_exe          <= 1'd0;
    jump_addr_exe        <= 32'd0;
    reg_wen_exe            <= 1'd0;
    reg_waddr_exe            <= 5'd0;
    reg_wdata_exe            <= 32'd0;
    mem_addr_exe        <= 32'd0;
    reg_rdata2_exe         <= 32'd0;
    lb_exe               <= 1'b0;
    lh_exe               <= 1'b0;
    lbu_exe              <= 1'b0;
    lhu_exe              <= 1'b0;
    lw_exe               <= 1'b0;
    sb_exe               <= 1'b0;
    sh_exe               <= 1'b0;
    sw_exe               <= 1'b0;
  end
  else if(hold_ctl) begin
    jump_en_exe         <= jump_en_exe  ;
    jump_addr_exe       <= jump_addr_exe;
    reg_wen_exe           <= reg_wen_exe    ;
    reg_waddr_exe           <= reg_waddr_exe    ;
    reg_wdata_exe           <= reg_wdata_exe    ;
    mem_addr_exe       <= mem_addr_exe;
    reg_rdata2_exe        <= reg_rdata2_exe ;
    lb_exe              <= lb_exe  ;
    lh_exe              <= lh_exe  ;
    lbu_exe             <= lbu_exe ;
    lhu_exe             <= lhu_exe ;
    lw_exe              <= lw_exe  ;
    sb_exe              <= sb_exe  ;
    sh_exe              <= sh_exe  ;
    sw_exe              <= sw_exe  ;
  end
  else if(clear_ctl) begin
    jump_en_exe          <= 1'd0;
    jump_addr_exe        <= 32'd0;
    reg_wen_exe            <= 1'd0;
    reg_waddr_exe            <= 5'd0;
    reg_wdata_exe            <= 32'd0;
    mem_addr_exe        <= 32'd0;
    reg_rdata2_exe         <= 32'd0;
    lb_exe               <= 1'b0;
    lh_exe               <= 1'b0;
    lbu_exe              <= 1'b0;
    lhu_exe              <= 1'b0;
    lw_exe               <= 1'b0;
    sb_exe               <= 1'b0;
    sh_exe               <= 1'b0;
    sw_exe               <= 1'b0;
  end
  else begin
    jump_en_exe         <= jump_en_exe_pre  ;
    jump_addr_exe       <= jump_addr_exe_pre;
    reg_wen_exe           <= reg_wen_exe_pre    ;
    reg_waddr_exe           <= reg_waddr_exe_pre    ;
    reg_wdata_exe           <= reg_wdata_exe_pre    ;
    mem_addr_exe       <= mem_addr_exe_pre;
    reg_rdata2_exe        <= reg_rdata2_ctl       ;
    lb_exe              <= lb_dec  ;
    lh_exe              <= lh_dec  ;
    lbu_exe             <= lbu_dec ;
    lhu_exe             <= lhu_dec ;
    lw_exe              <= lw_dec  ;
    sb_exe              <= sb_dec  ;
    sh_exe              <= sh_dec  ;
    sw_exe              <= sw_dec  ;
  end
end

//for exception
always @(*) begin
load_addr_mis_exe_pre = 1'b0;
store_addr_mis_exe_pre = 1'b0;

if((lh_dec|lhu_dec) & mem_addr_exe_pre[0]) load_addr_mis_exe_pre = 1'b1;
if(lw_dec & (|mem_addr_exe_pre[1:0])) load_addr_mis_exe_pre = 1'b1;

if(sh_dec & mem_addr_exe_pre[0]) store_addr_mis_exe_pre = 1'b1;
if(sw_dec & (|mem_addr_exe_pre[1:0])) store_addr_mis_exe_pre = 1'b1;

end

endmodule
