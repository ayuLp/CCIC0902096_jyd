module decoder(
  //clk & rst_b
  input clk,
  input rst_b,
  //pc & instruction
  input [31:0] pc_if,
  input [31:0] inst_if,
  
  //clear
  input clear_ctl,
  
  //hold
  input hold_ctl,
  
  //decoder output
  //to execute
  output reg [31:0] pc_dec,// 传递到执行阶段的PC值
  output reg [31:0] imm_dec,// 解码后的立即数
  output reg        imm_en_dec,  // 立即数有效标志
  
    // ALU操作信号
  output reg sll_dec,  
  output reg srl_dec,  
  output reg sra_dec,  
  output reg add_dec,  
  output reg sub_dec,  
  output reg lui_dec,  // 高位立即数加载
  output reg auipc_dec,  // PC相对地址加载
  output reg xor_dec,  
  output reg and_dec,  
  output reg or_dec,  
  output reg slt_dec,  // 有符号数比较置位
  output reg sltu_dec,  // 无符号数比较置位

  // load/store操作信号
  output reg lb_dec,    
  output reg lh_dec,  
  output reg lbu_dec,  
  output reg lhu_dec,  
  output reg lw_dec,  
  output reg sb_dec,  
  output reg sh_dec,  
  output reg sw_dec,  

  //系统指令
  output reg ebreak_dec,  // 断点
  output reg ecall_dec,  // 系统调用
  output reg mret_dec,  //机器模式异常返回
  
  //跳转指令
  output reg jal_dec,  
  output reg jalr_dec,  
  output reg beq_dec,  
  output reg bne_dec,  
  output reg blt_dec,  
  output reg bge_dec,  
  output reg bltu_dec,  
  output reg bgeu_dec,  
  
  output reg fence_dec,
  output reg fence_i_dec,
  
  //csr指令
  output reg csrrw_dec,
  output reg csrrs_dec,
  output reg csrrc_dec,
  
  //寄存器文件接口
  output reg [4:0] reg_raddr1_dec,   //源寄存器1地址(rs1)
  output reg [4:0] reg_raddr2_dec,  // 源寄存器2地址(rs2)
  output reg [4:0] reg_waddr_dec,  // 目标寄存器地址(rd)

  //for exception
  output wire illegal_inst_dec,// 非法指令标志(1: 检测到非法指令)

  output reg [31:0] inst_dec,// 锁存的指令（用于异常处理）

  //io with regfile
  output reg reg_ren1_dec,  
  output reg reg_ren2_dec  
);

//define wire/reg
reg [31:0] imm_dec_pre ;
reg        imm_en_dec_pre;  

reg        sll_dec_pre;  
reg        srl_dec_pre;  
reg        sra_dec_pre;  
reg        add_dec_pre;  
reg        sub_dec_pre;  
reg        lui_dec_pre;  
reg        auipc_dec_pre;  
reg        xor_dec_pre;  
reg        and_dec_pre;  
reg        or_dec_pre;  
reg        slt_dec_pre;  
reg        sltu_dec_pre;  
reg        lb_dec_pre;  
reg        lh_dec_pre;  
reg        lbu_dec_pre;  
reg        lhu_dec_pre;  
reg        lw_dec_pre;  
reg        sb_dec_pre;  
reg        sh_dec_pre;  
reg        sw_dec_pre;  
reg        ebreak_dec_pre;  
reg        ecall_dec_pre;  
reg        mret_dec_pre;  

reg        jal_dec_pre;  
reg        jalr_dec_pre;  
reg        beq_dec_pre;  
reg        bne_dec_pre;  
reg        blt_dec_pre;  
reg        bge_dec_pre;  
reg        bltu_dec_pre;  
reg        bgeu_dec_pre;  
reg        fence_dec_pre;
reg        fence_i_dec_pre;


reg csrrw_dec_pre ;
reg csrrs_dec_pre ;
reg csrrc_dec_pre ;

reg [4:0] reg_raddr1_dec_pre;  
reg [4:0] reg_raddr2_dec_pre;  
reg [4:0] reg_waddr_dec_pre;

reg reg_ren1_dec_pre;
reg reg_ren2_dec_pre;

wire [6:0] opcode = inst_if[6:0]; 
wire [2:0] funct3 = inst_if[14:12]; 
wire [6:0] funct7 = inst_if[31:25]; 


always @(*) begin
//default value setting to avoid latch
imm_dec_pre = 32'd0;
imm_en_dec_pre= 32'd0;  

sll_dec_pre    = 1'b0;  
srl_dec_pre    = 1'b0;  
sra_dec_pre    = 1'b0;  
add_dec_pre    = 1'b0;  
sub_dec_pre    = 1'b0;
lui_dec_pre    = 1'b0;  
auipc_dec_pre  = 1'b0;  
xor_dec_pre    = 1'b0;  
and_dec_pre    = 1'b0;  
or_dec_pre     = 1'b0;  
slt_dec_pre    = 1'b0;  
sltu_dec_pre   = 1'b0;  
lb_dec_pre     = 1'b0;  
lh_dec_pre     = 1'b0;  
lbu_dec_pre    = 1'b0;  
lhu_dec_pre    = 1'b0;  
lw_dec_pre     = 1'b0;  
sb_dec_pre     = 1'b0;  
sh_dec_pre     = 1'b0;  
sw_dec_pre     = 1'b0;  
ebreak_dec_pre  = 1'b0;  
ecall_dec_pre  = 1'b0;  
mret_dec_pre  = 1'b0;  

jal_dec_pre    = 1'b0;  
jalr_dec_pre   = 1'b0;  
beq_dec_pre    = 1'b0;  
bne_dec_pre    = 1'b0;  
blt_dec_pre    = 1'b0;  
bge_dec_pre    = 1'b0;  
bltu_dec_pre   = 1'b0;  
bgeu_dec_pre   = 1'b0;  

fence_dec_pre    = 1'b0;
fence_i_dec_pre  = 1'b0;

csrrw_dec_pre  = 1'b0;
csrrs_dec_pre  = 1'b0;
csrrc_dec_pre  = 1'b0;

reg_raddr1_dec_pre        = inst_if[19:15];
reg_raddr2_dec_pre        = inst_if[24:20];
reg_waddr_dec_pre         = inst_if[11:7];

reg_ren1_dec_pre     = 1'b0;
reg_ren2_dec_pre     = 1'b0;

// 组合逻辑解码器
case (opcode)
  8'b0110111: 
    begin //lui
      imm_dec_pre[31:12] = inst_if[31:12];
      imm_en_dec_pre     = 1'b1;
      lui_dec_pre        = 1'b1;
    end
  8'b0010111:
    begin //auipc
      imm_dec_pre[31:12] = inst_if[31:12];
      imm_en_dec_pre     = 1'b1;
      auipc_dec_pre      = 1'b1;
    end
  8'b1101111:
    begin  //jal
      imm_dec_pre[19:12] = inst_if[19:12];
      imm_dec_pre[11]    = inst_if[20];
      imm_dec_pre[10:1]  = inst_if[30:21];
      imm_dec_pre[20]    = inst_if[31];
      imm_en_dec_pre     = 1'b1;
      jal_dec_pre        = 1'b1;
    end
  8'b1100111:
    begin //I type type0
      case(funct3)
        3'b000:
	  begin //jalr
            imm_dec_pre[11:0]  = inst_if[31:20];
            imm_en_dec_pre     = 1'b1;
            jalr_dec_pre       = 1'b1;
            reg_ren1_dec_pre     = 1'b1;
          end
      endcase
    end
  8'b1100011:
    begin //B type
      imm_dec_pre[11]    = inst_if[7];
      imm_dec_pre[4:1]   = inst_if[11:8];
      imm_dec_pre[10:5]  = inst_if[30:25];
      imm_dec_pre[12]    = inst_if[31];
      imm_en_dec_pre     = 1'b1;
      reg_ren1_dec_pre     = 1'b1;
      reg_ren2_dec_pre     = 1'b1;
      case(funct3)
        3'b000: beq_dec_pre  = 1'b1;
        3'b001: bne_dec_pre  = 1'b1;
        3'b100: blt_dec_pre  = 1'b1;
        3'b101: bge_dec_pre  = 1'b1;
        3'b110: bltu_dec_pre = 1'b1;
        3'b111: bgeu_dec_pre = 1'b1;
      endcase
    end	      
  8'b0000011:
    begin //I type1
      imm_dec_pre[11:0]  = inst_if[31:20];
      imm_en_dec_pre     = 1'b1;
      reg_ren1_dec_pre         = 1'b1;
      case (funct3)
        3'b000: lb_dec_pre     = 1'b1;//lb
        3'b001: lh_dec_pre     = 1'b1;//lh
        3'b010: lw_dec_pre     = 1'b1;//lw
        3'b100: lbu_dec_pre    = 1'b1;//lbu
        3'b101: lhu_dec_pre    = 1'b1;//lhu
      endcase
    end
  8'b0100011:
    begin
     imm_dec_pre[4:0]  = inst_if[11:7];
     imm_dec_pre[11:5] = inst_if[31:25];
     imm_en_dec_pre= 1'b1;
     reg_ren1_dec_pre    = 1'b1;
     reg_ren2_dec_pre    = 1'b1;
     case(funct3)
       3'b000: sb_dec_pre = 1'b1;
       3'b001: sh_dec_pre = 1'b1;
       3'b010: sw_dec_pre = 1'b1;
     endcase
   end	      
  8'b0010011:
    begin //I type2
      reg_ren1_dec_pre     = 1'b1;	
      imm_en_dec_pre     = 1'b1;
      case (funct3)
        3'b000:
          begin//addi
            imm_dec_pre[11:0]  = inst_if[31:20];
      	    add_dec_pre        = 1'b1;
          end
        3'b010:
          begin//slti
            imm_dec_pre[11:0]  = inst_if[31:20];
      	    slt_dec_pre        = 1'b1;
          end
        3'b011:
          begin//sltiu
            imm_dec_pre[11:0]  = inst_if[31:20];
      	    sltu_dec_pre       = 1'b1;
          end
        3'b100:
          begin//xori
            imm_dec_pre[11:0]  = inst_if[31:20];
      	    xor_dec_pre        = 1'b1;
          end
        3'b110:
          begin//ori
            imm_dec_pre[11:0]  = inst_if[31:20];
      	    or_dec_pre         = 1'b1;
          end
        3'b111:
          begin//ori
            imm_dec_pre[11:0]  = inst_if[31:20];
      	    and_dec_pre         = 1'b1;
          end
        3'b001:
          begin//slli
            if(funct7 == 7'b0000000) begin
              imm_dec_pre[4:0]  = inst_if[24:20];
              imm_en_dec_pre    = 1'b1;
      	      sll_dec_pre       = 1'b1;
      	    end
          end
        3'b101:
          begin
            if(funct7 == 7'b0000000) begin//srli
              imm_dec_pre[4:0]  = inst_if[24:20];
      	      srl_dec_pre       = 1'b1;
      	    end
      	    else if(funct7 == 7'b0100000) begin//srai
              imm_dec_pre[4:0]  = inst_if[24:20];
      	      sra_dec_pre       = 1'b1;
            end
         end
      endcase
    end
  8'b0110011:
    begin //R type
      reg_ren1_dec_pre = 1'b1; 
      reg_ren2_dec_pre = 1'b1; 
      case(funct3)
        3'b000:
          if(funct7 == 7'b0000000)
            add_dec_pre = 1'b1; 
      	  else if(funct7 == 7'b0100000)
            sub_dec_pre = 1'b1;
        3'b001: if(funct7 == 7'b0000000) sll_dec_pre  = 1'b1;
        3'b010: if(funct7 == 7'b0000000) slt_dec_pre  = 1'b1;
        3'b011: if(funct7 == 7'b0000000) sltu_dec_pre = 1'b1;
        3'b100: if(funct7 == 7'b0000000) xor_dec_pre  = 1'b1;
        3'b101:
          if(funct7 == 7'b0000000) 
            srl_dec_pre = 1'b1;
      	  else if(funct7 == 7'b0100000)
            sra_dec_pre = 1'b1;
        3'b110: if(funct7 == 7'b0000000) or_dec_pre   = 1'b1; 
        3'b111: if(funct7 == 7'b0000000) and_dec_pre  = 1'b1; 
      endcase
    end
  8'b0001111:
    begin//I type2
      case(funct3)
        3'b000:
          begin
            fence_dec_pre      = 1'b1;
      	    imm_dec_pre[27:25] = inst_if[27:25];
      	    imm_dec_pre[24:22] = inst_if[24:22];
          end
        3'b001: fence_i_dec_pre = 1'b1;
      endcase
    end	      
  8'b1110011:
    begin //I type3
      imm_dec_pre[31:20] = inst_if[31:20];
      case(funct3)
        3'b000:
          begin
            if(inst_if[31:20] == 12'b0000_0000_0000)
              ecall_dec_pre = 1'b1;
            else if(inst_if[31:20] == 12'b0000_0000_0001)
              ebreak_dec_pre = 1'b1;
            else if(inst_if[31:20] == 12'b0011_0000_0010)
              mret_dec_pre = 1'b1;
          end
        3'b001:
          begin
            reg_ren1_dec_pre    = 1'b1;
      	    csrrw_dec_pre     = 1'b1;
          end
        3'b010:
          begin
            reg_ren1_dec_pre    = 1'b1;
      	    csrrs_dec_pre     = 1'b1;
          end
        3'b011:
          begin
            reg_ren1_dec_pre    = 1'b1;
      	    csrrc_dec_pre     = 1'b1;
          end
        3'b101:
          begin
            imm_dec_pre[19:15] = inst_if[19:15];
            imm_en_dec_pre   = 1'b1;
      	    csrrw_dec_pre    = 1'b1;
          end
        3'b110:
          begin
            imm_dec_pre[19:15] = inst_if[19:15];
            imm_en_dec_pre   = 1'b1;
      	    csrrs_dec_pre    = 1'b1;
          end
        3'b111:
          begin
            imm_dec_pre[19:15] = inst_if[19:15];
            imm_en_dec_pre   = 1'b1;
      	    csrrc_dec_pre    = 1'b1;
          end
      endcase
    end
endcase//opcode
end//always

// 时序逻辑：流水线寄存器
always @(posedge clk or negedge rst_b) begin
  if(~rst_b) begin// 异步复位
    pc_dec          <= 32'd0;
    imm_dec         <= 32'd0;
    imm_en_dec      <= 32'd0;
    sll_dec         <= 1'b0;  
    srl_dec         <= 1'b0;  
    sra_dec         <= 1'b0;  
    add_dec         <= 1'b0;  
    sub_dec         <= 1'b0;  
    lui_dec         <= 1'b0;  
    auipc_dec       <= 1'b0;  
    xor_dec         <= 1'b0;  
    and_dec         <= 1'b0;  
    or_dec          <= 1'b0;  
    slt_dec         <= 1'b0;  
    sltu_dec        <= 1'b0;  
    lb_dec          <= 1'b0;  
    lh_dec          <= 1'b0;  
    lbu_dec         <= 1'b0;  
    lhu_dec         <= 1'b0;  
    lw_dec          <= 1'b0;  
    sb_dec          <= 1'b0;  
    sh_dec          <= 1'b0;  
    sw_dec          <= 1'b0;  
    ebreak_dec      <= 1'b0;  
    ecall_dec       <= 1'b0;  
    mret_dec        <= 1'b0;  
    jal_dec         <= 1'b0;  
    jalr_dec        <= 1'b0;  
    beq_dec         <= 1'b0;  
    bne_dec         <= 1'b0;  
    blt_dec         <= 1'b0;  
    bge_dec         <= 1'b0;  
    bltu_dec        <= 1'b0;  
    bgeu_dec        <= 1'b0;  
    fence_dec       <= 1'b0;
    fence_i_dec     <= 1'b0;
    csrrw_dec       <= 1'b0;
    csrrs_dec       <= 1'b0;
    csrrc_dec       <= 1'b0;
    reg_raddr1_dec         <= 5'b0;  
    reg_raddr2_dec         <= 5'b0;  
    reg_waddr_dec          <= 5'b0;  
    reg_ren1_dec      <= 1'b0;
    reg_ren2_dec      <= 1'b0;
    inst_dec          <= 32'd0;
  end
  else if(hold_ctl) begin// 流水线保持
    pc_dec          <= pc_dec       ;
    imm_dec         <= imm_dec      ;
    imm_en_dec      <= imm_en_dec   ;
    sll_dec         <= sll_dec      ;  
    srl_dec         <= srl_dec      ;  
    sra_dec         <= sra_dec      ;  
    add_dec         <= add_dec      ;  
    sub_dec         <= sub_dec      ;  
    lui_dec         <= lui_dec      ;  
    auipc_dec       <= auipc_dec    ;  
    xor_dec         <= xor_dec      ;  
    and_dec         <= and_dec      ;  
    or_dec          <= or_dec       ;  
    slt_dec         <= slt_dec      ;  
    sltu_dec        <= sltu_dec     ;  
    lb_dec          <= lb_dec       ;  
    lh_dec          <= lh_dec       ;  
    lbu_dec         <= lbu_dec      ;  
    lhu_dec         <= lhu_dec      ;  
    lw_dec          <= lw_dec       ;  
    sb_dec          <= sb_dec       ;  
    sh_dec          <= sh_dec       ;  
    sw_dec          <= sw_dec       ;  
    ebreak_dec      <= ebreak_dec   ;  
    ecall_dec       <= ecall_dec    ;  
    mret_dec        <= mret_dec     ;  
    jal_dec         <= jal_dec      ;  
    jalr_dec        <= jalr_dec     ;  
    beq_dec         <= beq_dec      ;  
    bne_dec         <= bne_dec      ;  
    blt_dec         <= blt_dec      ;  
    bge_dec         <= bge_dec      ;  
    bltu_dec        <= bltu_dec     ;  
    bgeu_dec        <= bgeu_dec     ;  
    fence_dec       <= fence_dec    ;
    fence_i_dec     <= fence_i_dec  ;
    csrrw_dec       <= csrrw_dec    ;
    csrrs_dec       <= csrrs_dec    ;
    csrrc_dec       <= csrrc_dec    ;
    reg_raddr1_dec         <= reg_raddr1_dec      ;  
    reg_raddr2_dec         <= reg_raddr2_dec      ;  
    reg_waddr_dec          <= reg_waddr_dec       ;  
    reg_ren1_dec      <= reg_ren1_dec   ;
    reg_ren2_dec      <= reg_ren2_dec   ;
    inst_dec          <= inst_dec;
  end
  else if(clear_ctl) begin// 流水线清除
    pc_dec          <= 32'd0;
    imm_dec         <= 32'd0;
    imm_en_dec      <= 32'd0;
    sll_dec         <= 1'b0;  
    srl_dec         <= 1'b0;  
    sra_dec         <= 1'b0;  
    add_dec         <= 1'b0;  
    sub_dec         <= 1'b0;  
    lui_dec         <= 1'b0;  
    auipc_dec       <= 1'b0;  
    xor_dec         <= 1'b0;  
    and_dec         <= 1'b0;  
    or_dec          <= 1'b0;  
    slt_dec         <= 1'b0;  
    sltu_dec        <= 1'b0;  
    lb_dec          <= 1'b0;  
    lh_dec          <= 1'b0;  
    lbu_dec         <= 1'b0;  
    lhu_dec         <= 1'b0;  
    lw_dec          <= 1'b0;  
    sb_dec          <= 1'b0;  
    sh_dec          <= 1'b0;  
    sw_dec          <= 1'b0;  
    ebreak_dec      <= 1'b0;  
    ecall_dec       <= 1'b0;  
    mret_dec        <= 1'b0;  
    jal_dec         <= 1'b0;  
    jalr_dec        <= 1'b0;  
    beq_dec         <= 1'b0;  
    bne_dec         <= 1'b0;  
    blt_dec         <= 1'b0;  
    bge_dec         <= 1'b0;  
    bltu_dec        <= 1'b0;  
    bgeu_dec        <= 1'b0;  
    fence_dec       <= 1'b0;
    fence_i_dec     <= 1'b0;
    csrrw_dec       <= 1'b0;
    csrrs_dec       <= 1'b0;
    csrrc_dec       <= 1'b0;
    reg_raddr1_dec         <= 5'b0;  
    reg_raddr2_dec         <= 5'b0;  
    reg_waddr_dec          <= 5'b0;  
    reg_ren1_dec      <= 1'b0;
    reg_ren2_dec      <= 1'b0;
    inst_dec          <= 32'd0;
  end
  else begin  // 正常流水线推进
    pc_dec          <= pc_if              ;
    imm_dec         <= imm_dec_pre        ;
    imm_en_dec      <= imm_en_dec_pre     ;
    sll_dec         <= sll_dec_pre        ;  
    srl_dec         <= srl_dec_pre        ;  
    sra_dec         <= sra_dec_pre        ;  
    add_dec         <= add_dec_pre        ;  
    sub_dec         <= sub_dec_pre        ;  
    lui_dec         <= lui_dec_pre        ;  
    auipc_dec       <= auipc_dec_pre      ;  
    xor_dec         <= xor_dec_pre        ;  
    and_dec         <= and_dec_pre        ;  
    or_dec          <= or_dec_pre         ;  
    slt_dec         <= slt_dec_pre        ;  
    sltu_dec        <= sltu_dec_pre       ;  
    lb_dec          <= lb_dec_pre         ;  
    lh_dec          <= lh_dec_pre         ;  
    lbu_dec         <= lbu_dec_pre        ;  
    lhu_dec         <= lhu_dec_pre        ;  
    lw_dec          <= lw_dec_pre         ;  
    sb_dec          <= sb_dec_pre         ;  
    sh_dec          <= sh_dec_pre         ;  
    sw_dec          <= sw_dec_pre         ;  
    ebreak_dec      <= ebreak_dec_pre     ;  
    ecall_dec       <= ecall_dec_pre      ;  
    mret_dec        <= mret_dec_pre      ;  
    jal_dec         <= jal_dec_pre        ;  
    jalr_dec        <= jalr_dec_pre       ;  
    beq_dec         <= beq_dec_pre        ;  
    bne_dec         <= bne_dec_pre        ;  
    blt_dec         <= blt_dec_pre        ;  
    bge_dec         <= bge_dec_pre        ;  
    bltu_dec        <= bltu_dec_pre       ;  
    bgeu_dec        <= bgeu_dec_pre       ;  
    fence_dec       <= fence_dec_pre      ;
    fence_i_dec     <= fence_i_dec_pre    ;
    csrrw_dec       <= csrrw_dec_pre      ;
    csrrs_dec       <= csrrs_dec_pre      ;
    csrrc_dec       <= csrrc_dec_pre      ;
    reg_raddr1_dec         <= reg_raddr1_dec_pre        ;  
    reg_raddr2_dec         <= reg_raddr2_dec_pre        ;  
    reg_waddr_dec          <= reg_waddr_dec_pre         ;  
    reg_ren1_dec      <= reg_ren1_dec_pre     ;
    reg_ren2_dec      <= reg_ren2_dec_pre     ;
    inst_dec          <= inst_if;
  end
end

//for exception
// 非法指令检测逻辑
  // 或所有合法操作信号
assign illegal_inst_dec = ~(
  sll_dec|  
  srl_dec|  
  sra_dec|  
  add_dec|  
  sub_dec|  
  lui_dec|  
  auipc_dec|  
  xor_dec|  
  and_dec|  
  or_dec|  
  slt_dec|  
  sltu_dec|  
  lb_dec|  
  lh_dec|  
  lbu_dec|  
  lhu_dec|  
  lw_dec|  
  sb_dec|  
  sh_dec|  
  sw_dec|  
  ebreak_dec|  
  ecall_dec|  
  mret_dec|  
  jal_dec|  
  jalr_dec|  
  beq_dec|  
  bne_dec|  
  blt_dec|  
  bge_dec|  
  bltu_dec|  
  bgeu_dec|  
  fence_dec|
  fence_i_dec|
  csrrw_dec|
  csrrs_dec|
  csrrc_dec
  ) & |inst_dec;// 当没有有效操作且指令非零时触发



endmodule
