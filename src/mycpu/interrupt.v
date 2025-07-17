module interrupt(
input clk,
input rst_b,

//from decoder: exception
input ecall_dec,
input ebreak_dec,
input mret_dec,
input [31:0] pc_dec,
input [31:0] inst_dec,

input illegal_inst_dec,

//from exe: exception
input load_addr_mis_exe_pre,
input store_addr_mis_exe_pre,

input [31:0] mem_addr_exe_pre,

//from out of cpu: async irq
input [7:0] ext_ini_flag_top,

//from csr regfile control
input [31:0] mstatus_csr,
input [31:0] mie_csr,
input [31:0] mtvec_csr,
input [31:0] mepc_csr,

//io with csr regfile
output reg        csr_wen_intp,
output reg [11:0] csr_waddr_intp,
output reg [31:0] csr_wdata_intp,

//to top_ctrl
output reg        ini_clear_intp,

output reg        ini_jump_intp,
output reg [31:0] ini_jump_addr_intp
);

parameter IDLE             = 3'd0;
parameter MEPC             = 3'd1;
parameter MSTATUS          = 3'd2;
parameter MCAUSE           = 3'd3;
parameter MTVAL            = 3'd4;
parameter JUMP             = 3'd5;


wire external_irq = ext_ini_flag_top[1] & mstatus_csr[3] & mie_csr[11];
wire timer_irq = ext_ini_flag_top[0] & mstatus_csr[3] & mie_csr[7];
wire illegal_inst_ecp = illegal_inst_dec;
wire inst_addr_mis_ecp = |pc_dec[1:0];
wire ecall_ecp = ecall_dec;
wire ebreak_ecp = ebreak_dec;
wire load_addr_mis_ecp = load_addr_mis_exe_pre;
wire store_addr_mis_ecp = store_addr_mis_exe_pre;

wire [7:0] irq_ecp_en = {external_irq,timer_irq,illegal_inst_ecp,inst_addr_mis_ecp,ecall_ecp,ebreak_ecp,load_addr_mis_ecp,store_addr_mis_ecp};
reg [7:0] irq_ecp_en_active;
reg mret_dec_active;

reg [2:0] intp_status;
reg [2:0] intp_status_next;

reg [31:0] inst_dec_active;
reg [31:0] pc_dec_active;
reg [31:0] mem_addr_exe_pre_active;

always @(posedge clk or negedge rst_b) begin
  if(~rst_b)
    intp_status <= IDLE;
  else
    intp_status <= intp_status_next;
end

always @(*) begin
  case(intp_status)
    IDLE:
      if(|irq_ecp_en)
        intp_status_next = MEPC;
      else if(mret_dec)
        intp_status_next = MSTATUS;
      else
        intp_status_next = intp_status;
    //ext time state machine
    MEPC:
      if(|irq_ecp_en_active)
        intp_status_next = MSTATUS;
      else
        intp_status_next = intp_status;
    MSTATUS:
      if(|irq_ecp_en_active)
        intp_status_next = MCAUSE;
      else if(mret_dec_active)
        intp_status_next = JUMP;
      else
        intp_status_next = intp_status;
    MCAUSE:
      if(|irq_ecp_en_active)
        intp_status_next = MTVAL;
      else
        intp_status_next = intp_status;
    MTVAL:
      if(|irq_ecp_en_active)
        intp_status_next = JUMP;
      else
        intp_status_next = intp_status;
    JUMP:  intp_status_next = IDLE;
    default:  intp_status_next = IDLE;         
  endcase
end//always

genvar i;
generate
  for(i=0;i<8;i=i+1) begin: gen_irq_ecp_active
    always @(posedge clk or negedge rst_b) begin
      if(~rst_b)
        irq_ecp_en_active[i]         <= 1'b0;
      else if(irq_ecp_en[i] & (intp_status_next == MEPC))
        irq_ecp_en_active[i]         <= 1'b1;
      else if(irq_ecp_en_active[i] & (intp_status_next == JUMP))
        irq_ecp_en_active[i]         <= 1'b0;
    end//always
  end//for
endgenerate

always @(posedge clk or negedge rst_b) begin
  if(~rst_b)
    mret_dec_active <= 1'b0;
  else if(mret_dec & (intp_status_next == MSTATUS))
    mret_dec_active <= 1'b1;
  else if(mret_dec_active & (intp_status_next == JUMP))
    mret_dec_active <= 1'b0;
end

always @(posedge clk or negedge rst_b) begin
  if(~rst_b)
    inst_dec_active <= 32'd0;
  else if(irq_ecp_en[5] & (intp_status_next == MEPC))
    inst_dec_active <= inst_dec;
  else if(irq_ecp_en_active[5] & (intp_status_next == JUMP))
    inst_dec_active <= 32'd0;
end

always @(posedge clk or negedge rst_b) begin
  if(~rst_b)
    pc_dec_active <= 32'd0;
  else if((irq_ecp_en[4] | irq_ecp_en[2]) & (intp_status_next == MEPC))
    pc_dec_active <= pc_dec;
  else if((irq_ecp_en_active[4] | irq_ecp_en_active[2]) & (intp_status_next == JUMP))
    pc_dec_active <= 32'd0;
end

always @(posedge clk or negedge rst_b) begin
  if(~rst_b)
    mem_addr_exe_pre_active <= 32'd0;
  else if((|irq_ecp_en[1:0]) & (intp_status_next == MEPC))
    mem_addr_exe_pre_active <= mem_addr_exe_pre;
  else if((|irq_ecp_en_active[1:0]) & (intp_status_next == JUMP))
    mem_addr_exe_pre_active <= 32'd0;
end


always @(*) begin
  csr_wen_intp = 1'b0;
  csr_waddr_intp = 12'd0;
  csr_wdata_intp = 32'd0;
  ini_clear_intp = 1'b0;
  ini_jump_intp = 1'b0;
  ini_jump_addr_intp = 32'd0;
  case(intp_status_next)
    IDLE:
      begin
        csr_wen_intp = 1'b0;
        csr_waddr_intp = 12'd0;
        csr_wdata_intp = 32'd0;
        ini_clear_intp = 1'b0;
        ini_jump_intp = 1'b0;
        ini_jump_addr_intp = 32'd0;
      end
    MEPC:
      if(|irq_ecp_en) begin
        csr_wen_intp = 1'b1;
        csr_waddr_intp = 12'h341;
        csr_wdata_intp = pc_dec;
        ini_clear_intp = 1'b1;
      end
    MSTATUS:
      if(|irq_ecp_en_active) begin//irq
        csr_wen_intp = 1'b1;
        csr_waddr_intp = 12'h300;
        csr_wdata_intp = {mstatus_csr[31:4],1'b0,mstatus_csr[2:0]};
        ini_clear_intp = 1'b1;
      end
      else if(mret_dec) begin//mret
        csr_wen_intp = 1'b1;
        csr_waddr_intp = 12'h300;
        csr_wdata_intp = {mstatus_csr[31:4],mstatus_csr[7],mstatus_csr[2:0]};
        ini_clear_intp = 1'b1;
      end
    MCAUSE:
      if(irq_ecp_en_active[7]) begin
        csr_wen_intp = 1'b1;
        csr_waddr_intp = 12'h342;
        csr_wdata_intp = 32'h8000_000b;
        ini_clear_intp = 1'b1;
      end 
      else if(irq_ecp_en_active[6]) begin
        csr_wen_intp = 1'b1;
        csr_waddr_intp = 12'h342;
        csr_wdata_intp = 32'h8000_0007;
        ini_clear_intp = 1'b1;
      end 
      else if(irq_ecp_en_active[5]) begin
        csr_wen_intp = 1'b1;
        csr_waddr_intp = 12'h342;
        csr_wdata_intp = 32'h2;
        ini_clear_intp = 1'b1;
      end 
      else if(irq_ecp_en_active[4]) begin
        csr_wen_intp = 1'b1;
        csr_waddr_intp = 12'h342;
        csr_wdata_intp = 32'h0;
        ini_clear_intp = 1'b1;
      end 
      else if(irq_ecp_en_active[3]) begin
        csr_wen_intp = 1'b1;
        csr_waddr_intp = 12'h342;
        csr_wdata_intp = 32'd11;
        ini_clear_intp = 1'b1;
      end 
      else if(irq_ecp_en_active[2]) begin
        csr_wen_intp = 1'b1;
        csr_waddr_intp = 12'h342;
        csr_wdata_intp = 32'd3;
        ini_clear_intp = 1'b1;
      end 
      else if(irq_ecp_en_active[1]) begin
        csr_wen_intp = 1'b1;
        csr_waddr_intp = 12'h342;
        csr_wdata_intp = 32'd4;
        ini_clear_intp = 1'b1;
      end 
      else if(irq_ecp_en_active[0]) begin
        csr_wen_intp = 1'b1;
        csr_waddr_intp = 12'h342;
        csr_wdata_intp = 32'd6;
        ini_clear_intp = 1'b1;
      end 
    MTVAL:
      if(irq_ecp_en_active[7]) begin
        csr_wen_intp = 1'b1;
        csr_waddr_intp = 12'h343;
        csr_wdata_intp = 32'h0;
        ini_clear_intp = 1'b1;
      end 
      else if(irq_ecp_en_active[6]) begin
        csr_wen_intp = 1'b1;
        csr_waddr_intp = 12'h343;
        csr_wdata_intp = 32'h0;
        ini_clear_intp = 1'b1;
      end 
      else if(irq_ecp_en_active[5]) begin
        csr_wen_intp = 1'b1;
        csr_waddr_intp = 12'h343;
        csr_wdata_intp = inst_dec_active;
        ini_clear_intp = 1'b1;
      end 
      else if(irq_ecp_en_active[4]) begin
        csr_wen_intp = 1'b1;
        csr_waddr_intp = 12'h343;
        csr_wdata_intp = pc_dec_active;
        ini_clear_intp = 1'b1;
      end 
      else if(irq_ecp_en_active[3]) begin
        csr_wen_intp = 1'b1;
        csr_waddr_intp = 12'h343;
        csr_wdata_intp = 32'd0;
        ini_clear_intp = 1'b1;
      end 
      else if(irq_ecp_en_active[2]) begin
        csr_wen_intp = 1'b1;
        csr_waddr_intp = 12'h343;
        csr_wdata_intp = pc_dec_active;
        ini_clear_intp = 1'b1;
      end 
      else if(irq_ecp_en_active[1]) begin
        csr_wen_intp = 1'b1;
        csr_waddr_intp = 12'h343;
        csr_wdata_intp = mem_addr_exe_pre_active;
        ini_clear_intp = 1'b1;
      end 
      else if(irq_ecp_en_active[0]) begin
        csr_wen_intp = 1'b1;
        csr_waddr_intp = 12'h343;
        csr_wdata_intp = mem_addr_exe_pre_active;
        ini_clear_intp = 1'b1;
      end 
    JUMP:
      if(|irq_ecp_en_active) begin
        ini_jump_intp = 1'b1;
        ini_jump_addr_intp = mtvec_csr;
      end
      else if(mret_dec_active) begin
        ini_jump_intp = 1'b1;
        ini_jump_addr_intp = mepc_csr;
      end
  endcase
end//always

endmodule
