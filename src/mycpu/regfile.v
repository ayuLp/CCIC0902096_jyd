module regfile(
input clk,
input rst_b,
input reg_ren1_dec,
input reg_ren2_dec,
input [4:0] reg_raddr1_dec,
input [4:0] reg_raddr2_dec,

input reg_wen_wb,
input [4:0] reg_waddr_wb,
input [31:0] reg_wdata_wb,

output reg [31:0] reg_rdata1_reg,
output reg [31:0] reg_rdata2_reg
);

reg [31:0] regfile[30:0];
integer i;

//write
always @(posedge clk or negedge rst_b) begin
  if(~rst_b)
    for(i=0;i<31;i=i+1)
      regfile[i] <= 32'd0;
  else if(reg_wen_wb)
    regfile[reg_waddr_wb-5'd1] <= reg_wdata_wb; 
end

//read
always @(*) begin
  if(reg_ren1_dec) begin
    if(reg_raddr1_dec == 32'd0)
      reg_rdata1_reg = 32'd0;
    else
      reg_rdata1_reg = regfile[reg_raddr1_dec-32'd1];
  end
  else
    reg_rdata1_reg = 32'd0;
end//always

always @(*) begin
  if(reg_ren2_dec) begin
    if(reg_raddr2_dec == 32'd0)
      reg_rdata2_reg = 32'd0;
    else
      reg_rdata2_reg = regfile[reg_raddr2_dec-32'd1];
  end
  else
    reg_rdata2_reg = 32'd0;
end//always

endmodule
