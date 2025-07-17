module riscv_mem(//实现32位同步读写存储器，容量为 4KB地址空间（16KB存储，按字寻址）
input clk,
input rst_b,

input [31:0]  addr_riscv,
input [31:0]  wdata_riscv,
input         wr_en_riscv,
input         cs_en_riscv,
output reg [31:0] rdata_mem

);

reg [31:0] u0_mem[4095:0];
integer i;

always @(posedge clk or negedge rst_b) begin
  if(~rst_b)
    for(i=0;i<=12'd4095;i=i+1)
      u0_mem[i] <= 32'd0;
  else if(cs_en_riscv & wr_en_riscv)
      u0_mem[addr_riscv[27:2]] <= wdata_riscv;
end

always @(posedge clk or negedge rst_b) begin
  if(~rst_b)
    rdata_mem <= 32'd0;
  else if(cs_en_riscv & ~wr_en_riscv)
    rdata_mem <= u0_mem[addr_riscv[27:2]];
end

endmodule
