module csr_regfile(
input clk,
input rst_b,

//io with exe
input        csr_wen_exe,
input [11:0] csr_waddr_exe,
input [31:0] csr_wdata_exe,

input             csr_ren_exe,
input      [11:0] csr_raddr_exe,
output reg [31:0] csr_rdata_csr,

//io with irq
output reg [31:0] mstatus_csr,
output reg [31:0] mie_csr,
output reg [31:0] mtvec_csr,
output reg [31:0] mepc_csr,

input        csr_wen_intp,
input [11:0] csr_waddr_intp,
input [31:0] csr_wdata_intp

);

parameter CSR_CYCLE    = 12'hc00;
parameter CSR_CYCLEH   = 12'hc80;
parameter CSR_MTVEC    = 12'h305;
parameter CSR_MCAUSE   = 12'h342;
parameter CSR_MEPC     = 12'h341;
parameter CSR_MIE      = 12'h304;
parameter CSR_MSTATUS  = 12'h300;
parameter CSR_MSCRATCH = 12'h340;
parameter CSR_MISA     = 12'h301;
parameter CSR_MTVAL    = 12'h343;

reg [63:0] cycle_cnt;
//reg [31:0] mtvec_csr;
reg [31:0] mcause_csr;
//reg [31:0] mepc_csr;
//reg [31:0] mie_csr;
//reg [31:0] mstatus_csr;
reg [31:0] mscratch_csr;
reg [31:0] mtval_csr;

always @(posedge clk or negedge rst_b) begin
  if(~rst_b)
    cycle_cnt <= 64'd0;
  else
    cycle_cnt <= cycle_cnt + 64'd1;
end

//write: ext irq first
always @(posedge clk or negedge rst_b) begin
  if(~rst_b)
    mtvec_csr <= 32'd0;
  else if(csr_wen_intp & (csr_waddr_intp == CSR_MTVEC))
    mtvec_csr <= csr_wdata_intp;
  else if(csr_wen_exe & (csr_waddr_exe == CSR_MTVEC))
    mtvec_csr <= csr_wdata_exe;
end

always @(posedge clk or negedge rst_b) begin
  if(~rst_b)
    mcause_csr <= 32'd0;
  else if(csr_wen_intp & (csr_waddr_intp == CSR_MCAUSE))
    mcause_csr <= csr_wdata_intp;
  else if(csr_wen_exe & (csr_waddr_exe == CSR_MCAUSE))
    mcause_csr <= csr_wdata_exe;
end

always @(posedge clk or negedge rst_b) begin
  if(~rst_b)
    mepc_csr <= 32'd0;
  else if(csr_wen_intp & (csr_waddr_intp == CSR_MEPC))
    mepc_csr <= csr_wdata_intp;
  else if(csr_wen_exe & (csr_waddr_exe == CSR_MEPC))
    mepc_csr <= csr_wdata_exe;
end

always @(posedge clk or negedge rst_b) begin
  if(~rst_b)
    mie_csr <= 32'd0;
  else if(csr_wen_intp & (csr_waddr_intp == CSR_MIE))
    mie_csr <= csr_wdata_intp;
  else if(csr_wen_exe & (csr_waddr_exe == CSR_MIE))
    mie_csr <= csr_wdata_exe;
end

always @(posedge clk or negedge rst_b) begin
  if(~rst_b)
    mstatus_csr <= 32'd0;
  else if(csr_wen_intp & (csr_waddr_intp == CSR_MSTATUS))
    mstatus_csr <= csr_wdata_intp;
  else if(csr_wen_exe & (csr_waddr_exe == CSR_MSTATUS))
    mstatus_csr <= csr_wdata_exe;
end

always @(posedge clk or negedge rst_b) begin
  if(~rst_b)
    mscratch_csr <= 32'd0;
  else if(csr_wen_intp & (csr_waddr_intp == CSR_MSCRATCH))
    mscratch_csr <= csr_wdata_intp;
  else if(csr_wen_exe & (csr_waddr_exe == CSR_MSCRATCH))
    mscratch_csr <= csr_wdata_exe;
end

always @(posedge clk or negedge rst_b) begin
  if(~rst_b)
    mtval_csr <= 32'd0;
  else if(csr_wen_intp & (csr_waddr_intp == CSR_MTVAL))
    mtval_csr <= csr_wdata_intp;
  else if(csr_wen_exe & (csr_waddr_exe == CSR_MTVAL))
    mtval_csr <= csr_wdata_exe;
end

wire [31:0] misa_csr = {2'b1,4'b0,17'b0,1'b1,8'h00};

//read
always @(*) begin
  if(csr_ren_exe) begin
    case(csr_raddr_exe)
      CSR_CYCLE   : csr_rdata_csr = cycle_cnt[31:0];
      CSR_CYCLEH  : csr_rdata_csr = cycle_cnt[63:32];
      CSR_MTVEC   : csr_rdata_csr = mtvec_csr;
      CSR_MCAUSE  : csr_rdata_csr = mcause_csr;
      CSR_MEPC    : csr_rdata_csr = mepc_csr;
      CSR_MIE     : csr_rdata_csr = mie_csr;
      CSR_MSTATUS : csr_rdata_csr = mstatus_csr;
      CSR_MSCRATCH: csr_rdata_csr = mscratch_csr;
      CSR_MISA    : csr_rdata_csr = misa_csr;
      CSR_MTVAL   : csr_rdata_csr = mtval_csr;
      default     : csr_rdata_csr = 32'd0;
    endcase
  end//if
  else
    csr_rdata_csr = 32'd0;
end

endmodule
